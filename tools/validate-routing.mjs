#!/usr/bin/env node
// Validates routing files against schemas/routing.schema.json. No dependencies (Node 18+).
//   node tools/validate-routing.mjs              rules/routing.example.json, plus local/routing.json when present
//   node tools/validate-routing.mjs <file>...    only those files
// Besides the schema, it checks that no role uses an excluded provider or model, that pools
// are wired up (roles name a real pool, the pool's fallback has a model per role), and that the
// top-level fallback has a model it can run for every worker role.
import { readFileSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const KIT = resolve(dirname(fileURLToPath(import.meta.url)), '..');

const typeOf = (v) => (v === null ? 'null' : Array.isArray(v) ? 'array' : Number.isInteger(v) ? 'integer' : typeof v);
const sameType = (v, t) => typeOf(v) === t || (t === 'number' && typeOf(v) === 'integer');

// Small JSON Schema subset: $ref (local), type, const, enum, pattern, minLength, maxLength,
// minimum, maximum, required, properties, additionalProperties (false or a schema),
// propertyNames, items, minItems, uniqueItems.
function check(schema, value, path, root, errors) {
  if (schema.$ref) {
    const target = schema.$ref.replace(/^#\//, '').split('/').reduce((o, k) => o?.[k], root);
    if (!target) { errors.push(`${path}: unresolved ${schema.$ref}`); return; }
    return check(target, value, path, root, errors);
  }
  if ('const' in schema && value !== schema.const) errors.push(`${path}: must be ${JSON.stringify(schema.const)}`);
  if (schema.enum && !schema.enum.includes(value)) errors.push(`${path}: must be one of ${schema.enum.join(', ')} (got ${JSON.stringify(value)})`);
  if (schema.type && !sameType(value, schema.type)) { errors.push(`${path}: must be ${schema.type} (got ${typeOf(value)})`); return; }
  if (typeof value === 'string') {
    if (schema.minLength !== undefined && value.length < schema.minLength) errors.push(`${path}: shorter than ${schema.minLength}`);
    if (schema.maxLength !== undefined && value.length > schema.maxLength) errors.push(`${path}: longer than ${schema.maxLength}`);
    if (schema.pattern && !new RegExp(schema.pattern).test(value)) errors.push(`${path}: ${JSON.stringify(value)} does not match ${schema.pattern}`);
  }
  if (typeof value === 'number') {
    if (schema.minimum !== undefined && value < schema.minimum) errors.push(`${path}: less than ${schema.minimum}`);
    if (schema.maximum !== undefined && value > schema.maximum) errors.push(`${path}: more than ${schema.maximum}`);
  }
  if (Array.isArray(value)) {
    if (schema.minItems !== undefined && value.length < schema.minItems) errors.push(`${path}: needs at least ${schema.minItems} item(s)`);
    if (schema.uniqueItems && new Set(value.map((v) => JSON.stringify(v))).size !== value.length) errors.push(`${path}: items must be unique`);
    if (schema.items) value.forEach((v, i) => check(schema.items, v, `${path}[${i}]`, root, errors));
  }
  if (typeOf(value) === 'object') {
    for (const k of schema.required ?? []) if (!(k in value)) errors.push(`${path}: missing "${k}"`);
    const props = schema.properties ?? {};
    for (const [k, v] of Object.entries(value)) {
      if (schema.propertyNames) check(schema.propertyNames, k, `${path} key "${k}"`, root, errors);
      if (Object.hasOwn(props, k)) check(props[k], v, `${path}.${k}`, root, errors);
      else if (schema.additionalProperties === false) errors.push(`${path}: unknown field "${k}"`);
      else if (typeOf(schema.additionalProperties) === 'object') check(schema.additionalProperties, v, `${path}.${k}`, root, errors);
    }
  }
}

// Rules the schema cannot express: nothing on an excluded provider or model.
function checkExclusions(data, errors) {
  const lc = (list) => (Array.isArray(list) ? list.map((s) => String(s).toLowerCase()) : []);
  const badProviders = lc(data.excludedProviders);
  const badModels = lc(data.excludedModels);
  const test = (where, provider, model) => {
    const p = provider?.toLowerCase();
    const m = model?.toLowerCase();
    if (p && badProviders.includes(p)) errors.push(`${where}: provider "${provider}" is in excludedProviders`);
    if (m && badModels.includes(m)) errors.push(`${where}: model "${model}" is in excludedModels`);
    if (m && badProviders.some((x) => m.startsWith(x))) errors.push(`${where}: model "${model}" belongs to an excluded provider`);
  };
  for (const [role, r] of Object.entries(data.roles ?? {})) test(`roles.${role}`, r?.provider, r?.model);
  const fb = data.fallback;
  if (fb) {
    test('fallback', fb.provider, undefined);
    for (const [role, model] of Object.entries(fb.modelOverrides ?? {})) test(`fallback.modelOverrides.${role}`, fb.provider, model);
  }
  for (const [name, pool] of Object.entries(data.pools ?? {})) {
    const we = pool?.whenEmpty;
    if (!we) continue;
    test(`pools.${name}.whenEmpty`, we.provider, undefined);
    for (const [role, model] of Object.entries(we.models ?? {})) test(`pools.${name}.whenEmpty.models.${role}`, we.provider, model);
  }
}

// The model the top-level fallback would run for a role, or undefined when it has none.
// Shared with tools/next-account.mjs so the check and the picker agree.
export function fallbackModel(data, role) {
  const fb = data.fallback;
  const r = data.roles?.[role];
  if (!fb || !r) return undefined;
  if (fb.modelOverrides?.[role]) return fb.modelOverrides[role];
  const we = r.pool ? data.pools?.[r.pool]?.whenEmpty : undefined;
  if (we?.models?.[role] && we.provider === fb.provider) return we.models[role];
  return r.provider === fb.provider ? r.model : undefined;
}

// Pools: every role names a pool that exists, its providerInstanceId is in that pool, the pool's
// whenEmpty has a model for it, and the top-level fallback can run every worker role.
function checkPools(data, errors) {
  const pools = typeOf(data.pools) === 'object' ? data.pools : {};
  for (const [role, r] of Object.entries(data.roles ?? {})) {
    if (typeOf(r) !== 'object') continue;
    if (r.pool !== undefined) {
      const pool = pools[r.pool];
      if (role === 'lead') errors.push('roles.lead: the lead runs in your own thread and cannot use a pool');
      else if (typeOf(pool) !== 'object') errors.push(`roles.${role}.pool: no pool named "${r.pool}" in pools`);
      else {
        if (r.providerInstanceId && Array.isArray(pool.accounts) && !pool.accounts.includes(r.providerInstanceId)) {
          errors.push(`roles.${role}.providerInstanceId: "${r.providerInstanceId}" is not in pools.${r.pool}.accounts`);
        }
        if (pool.whenEmpty && !pool.whenEmpty.models?.[role]) {
          errors.push(`pools.${r.pool}.whenEmpty.models: missing a model for role "${role}"`);
        }
      }
    }
    if (role !== 'lead' && data.fallback && fallbackModel(data, role) === undefined) {
      errors.push(`fallback: no ${data.fallback.provider} model for role "${role}"; add fallback.modelOverrides.${role}`);
    }
  }
}

export function validateRouting(data, schema = JSON.parse(readFileSync(join(KIT, 'schemas', 'routing.schema.json'), 'utf8'))) {
  const errors = [];
  check(schema, data, '$', schema, errors);
  if (typeOf(data) === 'object') { checkExclusions(data, errors); checkPools(data, errors); }
  return errors;
}

function main(argv) {
  const files = argv.length ? argv : [join(KIT, 'rules', 'routing.example.json'), join(KIT, 'local', 'routing.json')].filter((f, i) => i === 0 || existsSync(f));
  let bad = 0;
  for (const f of files) {
    let errors;
    try {
      errors = validateRouting(JSON.parse(readFileSync(f, 'utf8')));
    } catch (e) {
      errors = [`cannot read or parse: ${e.message}`];
    }
    if (errors.length) { bad++; console.log(`FAIL ${f}`); for (const e of errors) console.log(`  ${e}`); }
    else console.log(`ok   ${f}`);
  }
  if (!argv.length && !existsSync(join(KIT, 'local', 'routing.json'))) console.log('note local/routing.json not found (run the setup skill to write it)');
  return bad ? 1 : 0;
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) process.exitCode = main(process.argv.slice(2));
