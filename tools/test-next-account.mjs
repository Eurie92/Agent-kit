#!/usr/bin/env node
// Tests for tools/next-account.mjs. Run: node tools/test-next-account.mjs
import { mkdtempSync, writeFileSync, readFileSync, readdirSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import { pick, markSpent } from './next-account.mjs';
import { validateRouting } from './validate-routing.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const NOW = new Date('2026-11-27T08:00:00Z');
const later = (h) => new Date(NOW.getTime() + h * 3600e3);
const routing = () => ({
  version: 1,
  updatedAt: '2026-11-27T08:00:00Z',
  roles: {
    advisor: { provider: 'claude', model: 'claude-fable-5-2', effort: 'medium', providerInstanceId: 'team2' },
    lead: { provider: 'claude', model: 'claude-opus-5-5' },
    implementation: { provider: 'gemini', model: 'gemini-4-hydrogen', effort: 'high', providerInstanceId: 'ag1', pool: 'ag' },
    bulk: { provider: 'gemini', model: 'gemini-4-hydrogen', effort: 'max', pool: 'ag' },
    researcher: { provider: 'gemini', model: 'gemini-4-hydrogen', pool: 'ag' },
  },
  excludedModels: [],
  excludedProviders: [],
  fallback: { provider: 'claude', runsOn: 'Main account, native subagent', modelOverrides: { advisor: 'claude-opus-5-5' } },
  pools: {
    ag: {
      driverKind: 'antigravity',
      accounts: ['ag1', 'ag2', 'ag3'],
      addNew: true,
      cooldownHours: 5,
      whenEmpty: { provider: 'claude', providerInstanceId: 'team2', models: { implementation: 'claude-sonnet-5-5', bulk: 'claude-haiku-5-5', researcher: 'claude-sonnet-5-5' } },
    },
  },
});
const empty = { version: 1, spent: {} };
const spend = (ids, r = routing()) => ids.reduce((st, id) => markSpent(r, st, id, { now: NOW }), empty);

let fails = 0;
const expect = (name, fn) => {
  let err;
  try { const msg = fn(); if (msg) err = msg; } catch (e) { err = e.message; }
  console.log(`${err ? 'FAIL' : 'ok  '} ${name}${err ? `  -> ${err}` : ''}`);
  if (err) fails++;
};
const eq = (got, want) => (JSON.stringify(got) === JSON.stringify(want) ? '' : `got ${JSON.stringify(got)}, want ${JSON.stringify(want)}`);

expect('test routing is valid', () => eq(validateRouting(routing()), []));
expect('fresh: first pool account, thought_level', () => {
  const p = pick(routing(), empty, 'implementation', { now: NOW });
  return eq([p.target, p.providerInstanceId, p.model, p.options], ['delegate_task', 'ag1', 'gemini-4-hydrogen', { thought_level: 'high' }]);
});
expect('max effort becomes xhigh on antigravity', () => eq(pick(routing(), empty, 'bulk', { now: NOW }).options, { thought_level: 'xhigh' }));
expect('no effort gives no options', () => eq(pick(routing(), empty, 'researcher', { now: NOW }).options, {}));
expect('spent account is skipped', () => eq(pick(routing(), spend(['ag1']), 'implementation', { now: NOW }).providerInstanceId, 'ag2'));
expect('whole pool spent: whenEmpty account and model', () => {
  const p = pick(routing(), spend(['ag1', 'ag2', 'ag3']), 'bulk', { now: NOW });
  return eq([p.target, p.providerInstanceId, p.model, p.options], ['delegate_task', 'team2', 'claude-haiku-5-5', { effort: 'max' }]);
});
expect('whenEmpty spent too: native fallback', () => {
  const p = pick(routing(), spend(['ag1', 'ag2', 'ag3', 'team2']), 'implementation', { now: NOW });
  return eq([p.target, p.model], ['native', 'claude-sonnet-5-5']);
});
expect('no fallback: target none', () => {
  const r = routing(); delete r.fallback;
  return eq(pick(r, spend(['ag1', 'ag2', 'ag3', 'team2'], r), 'implementation', { now: NOW }).target, 'none');
});
expect('cooldown ends: account is free again', () => eq(pick(routing(), spend(['ag1']), 'implementation', { now: later(5.1) }).providerInstanceId, 'ag1'));
expect('--until from the error wins over cooldown', () => {
  const st = markSpent(routing(), empty, 'ag1', { now: NOW, until: later(1).toISOString() });
  return eq([pick(routing(), st, 'implementation', { now: later(0.5) }).providerInstanceId, pick(routing(), st, 'implementation', { now: later(1.5) }).providerInstanceId], ['ag2', 'ag1']);
});
expect('markSpent drops expired entries', () => {
  const st = markSpent(routing(), spend(['ag1']), 'ag2', { now: later(6) });
  return eq(Object.keys(st.spent), ['ag2']);
});
expect('available: missing pool account skipped, new ones added in name order', () => {
  const available = ['antigravity:ag2', 'antigravity:ag_10', 'antigravity:ag_9', 'claudeAgent:team2'].map((s) => ({ kind: s.split(':')[0], id: s.split(':')[1] }));
  const st = spend(['ag2', 'ag3']);
  const p = pick(routing(), st, 'implementation', { now: NOW, available });
  return eq([p.providerInstanceId, p.skipped.map((s) => s.id)], ['ag_9', ['ag1', 'ag3', 'ag2']]);
});
expect('addNew off: new accounts ignored', () => {
  const r = routing(); r.pools.ag.addNew = false;
  const available = [{ kind: 'antigravity', id: 'ag9' }, { kind: 'claudeAgent', id: 'team2' }];
  const p = pick(r, empty, 'implementation', { now: NOW, available });
  return eq([p.providerInstanceId, p.model], ['team2', 'claude-sonnet-5-5']);
});
expect('role without pool: own account, then fallback override', () => {
  const a = pick(routing(), empty, 'advisor', { now: NOW });
  const b = pick(routing(), spend(['team2']), 'advisor', { now: NOW });
  return eq([a.providerInstanceId, a.options, b.target, b.model], ['team2', { effort: 'medium' }, 'native', 'claude-opus-5-5']);
});
expect('lead is refused', () => { try { pick(routing(), empty, 'lead', { now: NOW }); return 'no error'; } catch { return ''; } });
expect('validator: role names a missing pool', () => {
  const r = routing(); r.roles.bulk.pool = 'nope';
  return validateRouting(r).some((e) => e.includes('no pool named "nope"')) ? '' : JSON.stringify(validateRouting(r));
});
expect('validator: whenEmpty needs a model per pooled role', () => {
  const r = routing(); delete r.pools.ag.whenEmpty.models.bulk;
  return validateRouting(r).some((e) => e.includes('missing a model for role "bulk"')) ? '' : JSON.stringify(validateRouting(r));
});
expect('validator: providerInstanceId must be in the pool', () => {
  const r = routing(); r.roles.implementation.providerInstanceId = 'team2';
  return validateRouting(r).some((e) => e.includes('is not in pools.ag.accounts')) ? '' : JSON.stringify(validateRouting(r));
});
expect('validator: fallback needs a model it can run', () => {
  const r = routing(); delete r.pools.ag.whenEmpty;
  return validateRouting(r).some((e) => e.includes('no claude model for role "implementation"')) ? '' : JSON.stringify(validateRouting(r));
});
expect('validator: excluded provider in whenEmpty', () => {
  const r = routing(); r.excludedProviders = ['claude']; r.roles = { ...r.roles, lead: { provider: 'gemini', model: 'gemini-4-neon' }, advisor: { provider: 'gemini', model: 'gemini-4-neon' } }; delete r.fallback;
  return validateRouting(r).some((e) => e.includes('pools.ag.whenEmpty')) ? '' : JSON.stringify(validateRouting(r));
});
expect('validator: empty accounts, bad cooldown, bad pool name', () => {
  const r = routing(); r.pools.ag.accounts = []; r.pools.ag.cooldownHours = 0; r.pools['bad name'] = { driverKind: 'x', accounts: ['a'] };
  const errs = validateRouting(r).join('\n');
  return ['at least 1', 'less than 0.1', 'key "bad name"'].every((w) => errs.includes(w)) ? '' : errs;
});

expect('validator: fallback needs a provider', () => {
  const r = routing(); delete r.fallback.provider;
  return validateRouting(r).some((e) => e.includes('$.fallback: missing "provider"')) ? '' : JSON.stringify(validateRouting(r));
});
expect('validator: prototype keys are unknown fields', () => {
  const r = routing(); r.roles.lead = JSON.parse('{"provider":"claude","model":"claude-opus-5-5","constructor":"x"}');
  return validateRouting(r).some((e) => e.includes('unknown field "constructor"')) ? '' : JSON.stringify(validateRouting(r));
});
expect('pick: prototype role name is refused', () => { try { pick(routing(), empty, 'constructor', { now: NOW }); return 'no error'; } catch { return ''; } });

// CLI: --spent writes state, the next pick skips it, --clear forgets it.
expect('CLI round trip', () => {
  const dir = mkdtempSync(join(tmpdir(), 'next-account-'));
  try {
    const rf = join(dir, 'routing.json');
    const sf = join(dir, 'state.json');
    writeFileSync(rf, JSON.stringify(routing()));
    const run = (...args) => execFileSync(process.execPath, [join(here, 'next-account.mjs'), '--routing', rf, '--state', sf, '--now', NOW.toISOString(), ...args], { encoding: 'utf8' });
    const first = JSON.parse(run('implementation'));
    const out = run('--spent', 'ag1', '--reason', 'quota', 'implementation').trim().split('\n');
    const second = JSON.parse(out[1]);
    const saved = JSON.parse(readFileSync(sf, 'utf8'));
    run('--clear', 'ag1');
    const third = JSON.parse(run('implementation'));
    const status = run('--status');
    const refused = (...args) => { try { execFileSync(process.execPath, [join(here, 'next-account.mjs'), '--routing', rf, '--state', sf, ...args], { stdio: 'pipe' }); return false; } catch { return true; } };
    if (!refused('--spent', '--status')) return 'flag taken as a value: --spent --status';
    if (!refused('--spent', 'ag1', '--status')) return 'two modes accepted: --spent ag1 --status';
    writeFileSync(sf, 'null');
    run('--clear', 'ag1');
    const nullState = readFileSync(sf, 'utf8').replace(/\s/g, '');
    if (nullState !== '{"version":1,"spent":{}}') return `null state not repaired: ${nullState}`;
    const leftovers = readdirSync(dir).filter((f) => f.endsWith('.tmp'));
    if (leftovers.length) return `temp files left: ${leftovers}`;
    return eq([first.providerInstanceId, out[0].startsWith('marked ag1'), second.providerInstanceId, saved.spent.ag1.reason, third.providerInstanceId, status.includes('1. ag1: free')], ['ag1', true, 'ag2', 'quota', 'ag1', true]);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

if (fails) { console.log(`test-next-account: ${fails} failed`); process.exit(1); }
console.log('test-next-account: all passed');
