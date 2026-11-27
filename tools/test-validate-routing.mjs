#!/usr/bin/env node
// Tests for tools/validate-routing.mjs. Run: node tools/test-validate-routing.mjs
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { validateRouting } from './validate-routing.mjs';

const kit = join(dirname(fileURLToPath(import.meta.url)), '..');
const base = () => JSON.parse(readFileSync(join(kit, 'rules', 'routing.example.json'), 'utf8'));
let fails = 0;
const expect = (name, mutate, wanted) => {
  const data = base();
  mutate(data);
  const errors = validateRouting(data);
  const ok = wanted === null ? errors.length === 0 : errors.some((e) => e.includes(wanted));
  console.log(`${ok ? 'ok  ' : 'FAIL'} ${name}${ok ? '' : `  -> ${JSON.stringify(errors)}`}`);
  if (!ok) fails++;
};

expect('example is valid', () => {}, null);
expect('verifier is optional', (d) => { delete d.roles.auditor; delete d.fallback; }, null);
expect('wrong version', (d) => { d.version = 2; }, '$.version');
expect('missing lead', (d) => { delete d.roles.lead; }, 'missing "lead"');
expect('unknown role', (d) => { d.roles.boss = d.roles.lead; }, 'unknown field "boss"');
expect('unknown role field', (d) => { d.roles.lead.token = 'x'; }, 'unknown field "token"');
expect('bad effort', (d) => { d.roles.lead.effort = 'ultra'; }, 'must be one of');
expect('bad updatedAt', (d) => { d.updatedAt = 'yesterday'; }, '$.updatedAt');
expect('duplicate exclusions', (d) => { d.excludedProviders = ['gemini', 'gemini']; }, 'must be unique');
expect('excluded provider in a role', (d) => { d.excludedProviders = ['claude']; }, 'is in excludedProviders');
expect('excluded model in a role', (d) => { d.excludedModels = ['claude-haiku-5-5']; }, 'is in excludedModels');
expect('excluded vendor model under another provider', (d) => { d.excludedProviders = ['gemini']; d.roles.bulk.model = 'gemini-3-flash'; }, 'excluded provider');
expect('excluded model in fallback override', (d) => { d.excludedModels = ['claude-opus-5-5']; delete d.roles.lead; d.roles.lead = { provider: 'claude', model: 'claude-sonnet-5-5' }; }, 'fallback.modelOverrides');

if (fails) { console.log(`test-validate-routing: ${fails} failed`); process.exit(1); }
console.log('test-validate-routing: all passed');
