#!/usr/bin/env node
/**
 * TZ-3: production entry points must create pools via createAppPool (DATE parser).
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SCAN_ROOTS = [
  path.join(ROOT, 'server', 'bin'),
  path.join(ROOT, 'server', 'scripts'),
  path.join(ROOT, 'server', 'db', 'seeds'),
  path.join(ROOT, 'scripts', 'care'),
];
const ALLOWED_FILE = path.join('server', 'lib', 'db', 'createPool.js');
const POOL_RE = /\bnew\s+(?:pg\.)?Pool\s*\(/;

function walk(dir, out = []) {
  if (!fs.existsSync(dir)) return out;
  for (const name of fs.readdirSync(dir)) {
    const full = path.join(dir, name);
    const stat = fs.statSync(full);
    if (stat.isDirectory()) walk(full, out);
    else if (name.endsWith('.js')) out.push(full);
  }
  return out;
}

export function findViolations(files = SCAN_ROOTS.flatMap((d) => walk(d))) {
  const violations = [];
  for (const file of files) {
    const rel = path.relative(ROOT, file);
    if (rel === ALLOWED_FILE) continue;
    const text = fs.readFileSync(file, 'utf8');
    if (!POOL_RE.test(text)) continue;
    if (text.includes('createAppPool')) continue;
    violations.push(rel);
  }
  return violations;
}

const invoked = process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (invoked) {
  const violations = findViolations();
  if (violations.length > 0) {
    console.error('check_pg_pool_bootstrap: use createAppPool from server/lib/db/createPool.js:');
    violations.forEach((v) => console.error(`  ${v}`));
    process.exit(1);
  }
  console.log('check_pg_pool_bootstrap: OK');
}
