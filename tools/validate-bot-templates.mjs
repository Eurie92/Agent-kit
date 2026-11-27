#!/usr/bin/env node
// Validates starter bot template.json files. No dependencies (Node 18+).
//   node tools/validate-bot-templates.mjs          checks templates/bots/starters/*/template.json
//   node tools/validate-bot-templates.mjs <dir>    checks <dir>/*/template.json
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const KIT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const DEFAULT_DIR = join(KIT, 'templates', 'bots', 'starters');

const OPTIONAL_KEYS = ['allProjects', 'docsOnly'];
const REQUIRED_KEYS = [
  'id', 'name', 'category', 'description', 'firstChat',
  'watches', 'does', 'reports', 'needs', 'schedules',
  'level', 'skills', 'picture', 'soul', 'agents',
];
const ALLOWED_KEYS = new Set([...REQUIRED_KEYS, ...OPTIONAL_KEYS]);
const NEEDS_VALUES = ['nothing', 'GitHub via gh'];
const LEVEL_VALUES = ['watch', 'report', 'work', 'ship'];
const PICTURE_KINDS = ['mascot', 'emoji', 'initial'];
const ID_RE = /^kit-[a-z0-9-]+$/;

const isPlainObject = (v) => v !== null && typeof v === 'object' && !Array.isArray(v);
const isNonEmptyString = (v) => typeof v === 'string' && v.trim().length > 0;

/** Validate one parsed template.json value against a starter folder name. */
export function validateBotTemplate(data, folderName) {
  const errors = [];
  if (!isPlainObject(data)) {
    errors.push('template must be a JSON object');
    return errors;
  }

  for (const key of Object.keys(data)) {
    if (!ALLOWED_KEYS.has(key)) errors.push(`unknown field "${key}"`);
  }
  for (const key of REQUIRED_KEYS) {
    if (!Object.hasOwn(data, key)) errors.push(`missing required field "${key}"`);
  }

  if (Object.hasOwn(data, 'id')) {
    if (typeof data.id !== 'string' || !ID_RE.test(data.id)) {
      errors.push(`id must match ${ID_RE} (got ${JSON.stringify(data.id)})`);
    } else if (folderName && data.id !== `kit-${folderName}`) {
      errors.push(`id must equal "kit-${folderName}" (got ${JSON.stringify(data.id)})`);
    }
  }

  if (Object.hasOwn(data, 'category') && data.category !== 'Agent-kit') {
    errors.push(`category must be "Agent-kit" (got ${JSON.stringify(data.category)})`);
  }

  for (const key of ['name', 'description', 'firstChat', 'watches', 'does', 'reports', 'agents']) {
    if (Object.hasOwn(data, key) && !isNonEmptyString(data[key])) {
      errors.push(`${key} must be a non-empty string`);
    }
  }

  if (Object.hasOwn(data, 'needs') && !NEEDS_VALUES.includes(data.needs)) {
    errors.push(`needs must be one of ${NEEDS_VALUES.join(', ')} (got ${JSON.stringify(data.needs)})`);
  }

  if (Object.hasOwn(data, 'level') && !LEVEL_VALUES.includes(data.level)) {
    errors.push(`level must be one of ${LEVEL_VALUES.join(', ')} (got ${JSON.stringify(data.level)})`);
  }

  for (const key of OPTIONAL_KEYS) {
    if (Object.hasOwn(data, key) && typeof data[key] !== 'boolean') {
      errors.push(`${key} must be a boolean`);
    }
  }

  if (Object.hasOwn(data, 'schedules')) {
    if (!Array.isArray(data.schedules)) {
      errors.push('schedules must be an array');
    } else {
      data.schedules.forEach((entry, i) => {
        if (!isPlainObject(entry)) {
          errors.push(`schedules[${i}] must be an object`);
          return;
        }
        if (!isNonEmptyString(entry.title)) errors.push(`schedules[${i}].title must be a non-empty string`);
        if (!isNonEmptyString(entry.prompt)) errors.push(`schedules[${i}].prompt must be a non-empty string`);
        if (!isPlainObject(entry.schedule)) {
          errors.push(`schedules[${i}].schedule must be an object`);
        } else if (entry.schedule.type === 'webhook') {
          errors.push(`schedules[${i}].schedule.type cannot be "webhook"`);
        }
      });
    }
  }

  if (Object.hasOwn(data, 'skills')) {
    if (!Array.isArray(data.skills) || !data.skills.every((s) => typeof s === 'string')) {
      errors.push('skills must be an array of strings');
    }
  }

  if (Object.hasOwn(data, 'picture')) {
    if (!isPlainObject(data.picture)) {
      errors.push('picture must be an object');
    } else if (!PICTURE_KINDS.includes(data.picture.kind)) {
      errors.push(`picture.kind must be one of ${PICTURE_KINDS.join(', ')} (got ${JSON.stringify(data.picture.kind)})`);
    }
  }

  if (Object.hasOwn(data, 'soul')) {
    if (!isNonEmptyString(data.soul)) {
      errors.push('soul must be a non-empty string');
    } else if (/[<>]/.test(data.soul)) {
      errors.push('soul must not contain "<" or ">" characters');
    }
  }

  return errors;
}

// Validate every `<dir>/<starter>/template.json` file. Returns `{ files, failures }`.
export function validateBotTemplatesDir(dir = DEFAULT_DIR) {
  if (!existsSync(dir)) {
    return { files: 0, failures: [{ file: dir, errors: ['templates directory not found'] }] };
  }
  const entries = readdirSync(dir, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .sort((a, b) => a.name.localeCompare(b.name));
  const failures = [];
  let files = 0;

  for (const entry of entries) {
    const file = join(dir, entry.name, 'template.json');
    if (!existsSync(file)) continue;
    files++;
    let errors;
    try {
      errors = validateBotTemplate(JSON.parse(readFileSync(file, 'utf8')), entry.name);
    } catch (e) {
      errors = [`invalid JSON: ${e.message}`];
    }
    if (errors.length) failures.push({ file, errors });
  }

  if (files === 0) {
    failures.push({ file: dir, errors: ['no starter template.json files found'] });
  }
  return { files, failures };
}

function main(argv) {
  if (argv.length > 1) {
    console.error('Usage: node tools/validate-bot-templates.mjs [dir]');
    return 1;
  }
  const dir = argv[0] ? resolve(argv[0]) : DEFAULT_DIR;
  const { files, failures } = validateBotTemplatesDir(dir);
  if (failures.length) {
    for (const f of failures) {
      console.log(`FAIL ${f.file}`);
      for (const e of f.errors) console.log(`  ${e}`);
    }
    return 1;
  }
  console.log(`ok   ${dir} (${files} bot template(s))`);
  return 0;
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  process.exitCode = main(process.argv.slice(2));
}
