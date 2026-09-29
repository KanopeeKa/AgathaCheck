#!/usr/bin/env node
/**
 * Write-path guard (D-CSM-033): only `server/lib/care/occurrence/**` may
 * INSERT, UPDATE or DELETE `health_occurrences`. Migrations (SQL and their JS
 * hooks under `server/scripts/migrations/`) are excluded; seeds must call the
 * care commands. Tests are excluded (fixtures may build rows directly).
 *
 * Usage: node scripts/check_occurrence_writes.js
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SERVER = path.join(ROOT, 'server');
const ALLOWED = [
  path.join('server', 'lib', 'care', 'occurrence') + path.sep,
  path.join('server', 'scripts', 'migrations') + path.sep,
];
const SKIP_DIRS = new Set(['node_modules', 'test', 'coverage', 'uploads']);
const WRITE = /\b(INSERT\s+INTO|UPDATE|DELETE\s+FROM)\s+health_occurrences\b/i;

function walk(dir, out = []) {
  for (const name of fs.readdirSync(dir)) {
    if (SKIP_DIRS.has(name)) continue;
    const full = path.join(dir, name);
    const stat = fs.statSync(full);
    if (stat.isDirectory()) walk(full, out);
    else if (name.endsWith('.js') || name.endsWith('.mjs')) out.push(full);
  }
  return out;
}

export function findViolations(files = walk(SERVER)) {
  const violations = [];
  for (const file of files) {
    const rel = path.relative(ROOT, file);
    if (ALLOWED.some((prefix) => rel.startsWith(prefix))) continue;
    const lines = fs.readFileSync(file, 'utf8').split('\n');
    lines.forEach((line, i) => {
      if (WRITE.test(line)) violations.push(`${rel}:${i + 1}: ${line.trim()}`);
    });
  }
  return violations;
}

const invokedDirectly = process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (invokedDirectly) {
  const violations = findViolations();
  if (violations.length > 0) {
    console.error('check_occurrence_writes: health_occurrences is written outside server/lib/care/occurrence/:');
    for (const v of violations) console.error(`  ${v}`);
    console.error('Route the change through a care command (D-CSM-033).');
    process.exit(1);
  }
  console.log('check_occurrence_writes: OK');
}
