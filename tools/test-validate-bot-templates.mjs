#!/usr/bin/env node
// Tests for tools/validate-bot-templates.mjs. Run: node tools/test-validate-bot-templates.mjs
import { execFileSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const kit = join(here, '..');
const validator = join(here, 'validate-bot-templates.mjs');
const sample = JSON.parse(readFileSync(join(kit, 'templates', 'bots', 'starters', 'saver', 'template.json'), 'utf8'));

let fails = 0;

function runDir(mutator, folder = 'saver') {
  const root = mkdtempSync(join(tmpdir(), 'bot-templates-'));
  try {
    const sub = join(root, folder);
    mkdirSync(sub, { recursive: true });
    const content = mutator(structuredClone(sample));
    writeFileSync(join(sub, 'template.json'), typeof content === 'string' ? content : JSON.stringify(content, null, 2));
    try {
      const out = execFileSync(process.execPath, [validator, root], { encoding: 'utf8' });
      return { code: 0, out };
    } catch (e) {
      return { code: e.status ?? 1, out: `${e.stdout ?? ''}${e.stderr ?? ''}` };
    }
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

function expect(name, fn) {
  const err = fn();
  console.log(`${err ? 'FAIL' : 'ok  '} ${name}${err ? `  -> ${err}` : ''}`);
  if (err) fails++;
}

expect('valid starter passes with one-line OK', () => {
  const r = runDir((d) => d);
  if (r.code !== 0) return `expected exit 0, got ${r.code}: ${r.out}`;
  if (r.out.trim().split(/\r?\n/).length !== 1 || !r.out.startsWith('ok')) return `expected one-line OK, got ${JSON.stringify(r.out)}`;
  return '';
});

expect('rejects invalid JSON', () => {
  const r = runDir(() => '{not json');
  return r.code === 1 && r.out.includes('invalid JSON') ? '' : JSON.stringify(r);
});

expect('rejects unknown top-level key', () => {
  const r = runDir((d) => { d.extra = 1; return d; });
  return r.code === 1 && r.out.includes('unknown field "extra"') ? '' : JSON.stringify(r);
});

expect('rejects missing required key', () => {
  const r = runDir((d) => { delete d.agents; return d; });
  return r.code === 1 && r.out.includes('missing required field "agents"') ? '' : JSON.stringify(r);
});

expect('rejects mismatched folder id', () => {
  const r = runDir((d) => { d.id = 'kit-other'; return d; }, 'saver');
  return r.code === 1 && r.out.includes('kit-saver') ? '' : JSON.stringify(r);
});

expect('rejects wrong category', () => {
  const r = runDir((d) => { d.category = 'Built-in'; return d; });
  return r.code === 1 && r.out.includes('category must be "Agent-kit"') ? '' : JSON.stringify(r);
});

expect('rejects webhook schedule', () => {
  const r = runDir((d) => {
    d.schedules = [{ title: 'Hook', prompt: 'Do work', schedule: { type: 'webhook' } }];
    return d;
  });
  return r.code === 1 && r.out.includes('webhook') ? '' : JSON.stringify(r);
});

expect('rejects angle brackets in soul', () => {
  const r = runDir((d) => { d.soul = '# Saver\n\n<owner>\n'; return d; });
  return r.code === 1 && r.out.includes('"<" or ">"') ? '' : JSON.stringify(r);
});

expect('rejects bad needs, level, skills, picture.kind', () => {
  const r = runDir((d) => {
    d.needs = 'slack';
    d.level = 'admin';
    d.skills = [123];
    d.picture = { kind: 'photo', tile: 'meadow' };
    return d;
  });
  const ok = r.code === 1
    && r.out.includes('needs must be one of')
    && r.out.includes('level must be one of')
    && r.out.includes('skills must be an array of strings')
    && r.out.includes('picture.kind must be one of');
  return ok ? '' : JSON.stringify(r);
});

if (fails) {
  console.log(`test-validate-bot-templates: ${fails} failed`);
  process.exit(1);
}
console.log('test-validate-bot-templates: all passed');
