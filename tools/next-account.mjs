#!/usr/bin/env node
// Picks the account and model a worker role runs on, walking the chain in local/routing.json:
// the role's pool accounts in order, then the pool's whenEmpty account, then the top-level
// fallback. Accounts that hit their usage limit are remembered in local/account-state.json
// until they reset, so every thread skips them. No dependencies (Node 18+).
//
//   node tools/next-account.mjs <role> [--available <driverKind>:<id>,...]
//       Prints one JSON line: where to run the role and with which model and options.
//   node tools/next-account.mjs --spent <id> [--until <ISO time>] [--reason <text>] [<role>]
//       Marks an account as at its limit (until --until, or for the pool's cooldownHours).
//       With a role, also prints the next pick for it.
//   node tools/next-account.mjs --clear [<id>]     Forgets one spent account, or all.
//   node tools/next-account.mjs --status           Lists pools, accounts and their state.
//
// --available: the host's accounts that can run a child now, as driverKind:id pairs (T3 Code:
// orchestrator_capabilities, providers with canRunChildTask). Listed pool accounts missing from
// it are skipped; with the pool's addNew, unlisted accounts on the pool's driver are added.
// For tests and other homes: --routing <file>, --state <file>, --now <ISO time>.
import { readFileSync, writeFileSync, renameSync, existsSync, mkdirSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { validateRouting, fallbackModel } from './validate-routing.mjs';

const KIT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const DEFAULT_COOLDOWN_HOURS = 5;
const byName = (a, b) => a.localeCompare(b, 'en', { numeric: true });

// Host options for an effort level, by driverKind or provider. Antigravity (Gemini models) calls
// it thought_level and stops at xhigh.
export function optionsFor(kind, effort) {
  if (!effort) return {};
  if (kind === 'antigravity' || kind === 'gemini') return { thought_level: effort === 'max' ? 'xhigh' : effort };
  return { effort };
}

export function isSpent(state, id, now) {
  const e = state?.spent?.[id];
  return Boolean(e && Date.parse(e.until) > now.getTime());
}

export function poolOf(routing, id) {
  return Object.entries(routing.pools ?? {}).find(([, p]) => p.accounts?.includes(id));
}

function parseAvailable(list) {
  if (list === undefined) return undefined;
  return list.split(',').map((s) => s.trim()).filter(Boolean).map((pair) => {
    const i = pair.indexOf(':');
    if (i < 1 || i === pair.length - 1) throw new Error(`--available entries must be driverKind:id (got "${pair}")`);
    return { kind: pair.slice(0, i), id: pair.slice(i + 1) };
  });
}

// Pool accounts in the order to try them, given what the host can run now.
export function poolAccounts(pool, available) {
  if (!available) return [...pool.accounts];
  const onDriver = available.filter((a) => a.kind === pool.driverKind).map((a) => a.id);
  const listed = pool.accounts.filter((id) => onDriver.includes(id));
  const extra = pool.addNew ? onDriver.filter((id) => !pool.accounts.includes(id)).sort(byName) : [];
  return [...listed, ...extra];
}

// The pick for one role. Returns { role, target, providerInstanceId?, model, options, step, skipped }.
// target: "delegate_task" (child on an account), "native" (native subagent on the main account) or
// "none" (everything is at its limit).
export function pick(routing, state, role, { available, now = new Date() } = {}) {
  const r = routing.roles?.[role];
  if (!r) throw new Error(`no role "${role}" in routing (roles: ${Object.keys(routing.roles ?? {}).join(', ')})`);
  if (role === 'lead') throw new Error('the lead runs in your own thread; pick a worker role');
  const skipped = [];
  const isAvailable = (id) => !available || available.some((a) => a.id === id);
  const free = (id) => {
    if (!isAvailable(id)) { skipped.push({ id, why: 'not available' }); return false; }
    if (isSpent(state, id, now)) { skipped.push({ id, why: 'at limit', until: state.spent[id].until }); return false; }
    return true;
  };
  const result = (rest) => ({ role, ...rest, skipped });

  if (r.pool) {
    const pool = routing.pools[r.pool];
    const accounts = poolAccounts(pool, available);
    for (const id of pool.accounts) if (!accounts.includes(id)) skipped.push({ id, why: 'not available' });
    for (const [i, id] of accounts.entries()) {
      if (free(id)) {
        return result({ target: 'delegate_task', providerInstanceId: id, model: r.model, options: optionsFor(pool.driverKind, r.effort), step: `pool ${r.pool}, account ${i + 1} of ${accounts.length}` });
      }
    }
    const we = pool.whenEmpty;
    if (we && (!we.providerInstanceId || free(we.providerInstanceId))) {
      const base = { model: we.models[role], options: optionsFor(we.provider, r.effort), step: `pool ${r.pool} is at its limit; using its whenEmpty account` };
      return result(we.providerInstanceId ? { target: 'delegate_task', providerInstanceId: we.providerInstanceId, ...base } : { target: 'native', ...base });
    }
  } else if (r.providerInstanceId) {
    if (free(r.providerInstanceId)) {
      return result({ target: 'delegate_task', providerInstanceId: r.providerInstanceId, model: r.model, options: optionsFor(r.provider, r.effort), step: 'role account' });
    }
  } else {
    return result({ target: 'native', model: r.model, options: optionsFor(r.provider, r.effort), step: 'role runs as a native subagent' });
  }

  const fb = routing.fallback;
  if (fb && (!fb.providerInstanceId || free(fb.providerInstanceId))) {
    const base = { model: fallbackModel(routing, role), options: optionsFor(fb.provider, r.effort), step: `fallback: ${fb.runsOn ?? fb.provider}` };
    return result(fb.providerInstanceId ? { target: 'delegate_task', providerInstanceId: fb.providerInstanceId, ...base } : { target: 'native', ...base });
  }
  return result({ target: 'none', step: 'every account for this role is at its limit; wait for a reset or run the work in your own thread' });
}

// Marks an account as at its limit. Returns the new state (expired entries dropped).
export function markSpent(routing, state, id, { until, reason, now = new Date() } = {}) {
  const hours = poolOf(routing, id)?.[1]?.cooldownHours ?? DEFAULT_COOLDOWN_HOURS;
  const end = until ? new Date(until) : new Date(now.getTime() + hours * 3600e3);
  if (Number.isNaN(end.getTime())) throw new Error(`--until is not a time: "${until}"`);
  const spent = Object.fromEntries(Object.entries(state?.spent ?? {}).filter(([k]) => isSpent(state, k, now)));
  spent[id] = { since: now.toISOString(), until: end.toISOString(), ...(reason ? { reason: reason.slice(0, 200) } : {}) };
  return { version: 1, spent };
}

function readJson(file, fallback) {
  if (!existsSync(file)) return fallback;
  return JSON.parse(readFileSync(file, 'utf8'));
}

function writeState(file, state) {
  mkdirSync(dirname(file), { recursive: true });
  const tmp = `${file}.tmp`;
  writeFileSync(tmp, `${JSON.stringify(state, null, 2)}\n`);
  renameSync(tmp, file);
}

function parseArgs(argv) {
  const opts = { _: [] };
  const valued = new Set(['--available', '--spent', '--until', '--reason', '--routing', '--state', '--now']);
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (valued.has(a)) {
      if (i + 1 >= argv.length) throw new Error(`${a} needs a value`);
      opts[a.slice(2)] = argv[++i];
    } else if (a === '--clear' || a === '--status') opts[a.slice(2)] = true;
    else if (a.startsWith('--')) throw new Error(`unknown option ${a}`);
    else opts._.push(a);
  }
  return opts;
}

function status(routing, state, now) {
  const lines = [];
  const mark = (id) => (isSpent(state, id, now) ? `at limit until ${state.spent[id].until}` : 'free');
  for (const [name, p] of Object.entries(routing.pools ?? {})) {
    const users = Object.entries(routing.roles).filter(([, r]) => r.pool === name).map(([k]) => k);
    lines.push(`pool ${name} (${p.driverKind}; roles: ${users.join(', ') || 'none'}; addNew ${p.addNew ? 'on' : 'off'}; cooldown ${p.cooldownHours ?? DEFAULT_COOLDOWN_HOURS} h)`);
    p.accounts.forEach((id, i) => lines.push(`  ${i + 1}. ${id}: ${mark(id)}`));
    if (p.whenEmpty) lines.push(`  then ${p.whenEmpty.providerInstanceId ?? 'native'} (${p.whenEmpty.provider})${p.whenEmpty.providerInstanceId ? `: ${mark(p.whenEmpty.providerInstanceId)}` : ''}`);
  }
  for (const [role, r] of Object.entries(routing.roles)) {
    if (!r.pool && r.providerInstanceId) lines.push(`role ${role}: ${r.providerInstanceId} (${r.model}): ${mark(r.providerInstanceId)}`);
  }
  if (routing.fallback) lines.push(`fallback: ${routing.fallback.providerInstanceId ?? 'native subagent'} (${routing.fallback.provider})`);
  return lines.join('\n');
}

function main(argv) {
  const o = parseArgs(argv);
  const routingFile = o.routing ? resolve(o.routing) : join(KIT, 'local', 'routing.json');
  const stateFile = o.state ? resolve(o.state) : join(KIT, 'local', 'account-state.json');
  const now = o.now ? new Date(o.now) : new Date();
  if (Number.isNaN(now.getTime())) throw new Error(`--now is not a time: "${o.now}"`);
  if (!existsSync(routingFile)) throw new Error(`${routingFile} not found (run the setup skill to write it)`);
  const routing = JSON.parse(readFileSync(routingFile, 'utf8'));
  const errors = validateRouting(routing);
  if (errors.length) throw new Error(`${routingFile} is not valid (run node tools/validate-routing.mjs):\n  ${errors.join('\n  ')}`);
  let state = readJson(stateFile, { version: 1, spent: {} });

  if (o.status) { console.log(status(routing, state, now)); return 0; }
  if (o.clear) {
    const id = o._[0];
    state = { version: 1, spent: id ? Object.fromEntries(Object.entries(state.spent ?? {}).filter(([k]) => k !== id)) : {} };
    writeState(stateFile, state);
    console.log(id ? `cleared ${id}` : 'cleared all accounts');
    return 0;
  }
  if (o.spent) {
    state = markSpent(routing, state, o.spent, { until: o.until, reason: o.reason, now });
    writeState(stateFile, state);
    console.log(`marked ${o.spent} at limit until ${state.spent[o.spent].until}`);
    if (!o._.length) return 0;
  }
  const role = o._[0];
  if (!role) throw new Error('usage: node tools/next-account.mjs <role> [--available driverKind:id,...] | --spent <id> [<role>] | --clear [<id>] | --status');
  const choice = pick(routing, state, role, { available: parseAvailable(o.available), now });
  console.log(JSON.stringify(choice));
  return choice.target === 'none' ? 2 : 0;
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try {
    process.exitCode = main(process.argv.slice(2));
  } catch (e) {
    console.error(`next-account: ${e.message}`);
    process.exitCode = 1;
  }
}
