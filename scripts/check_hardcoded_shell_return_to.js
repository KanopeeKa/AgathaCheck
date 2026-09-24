#!/usr/bin/env node
/**
 * Ratchet: disallow new hardcoded shell returnTo paths in Flutter lib.
 *
 * Use currentShellLocation / openPetDetail / openVetDetail / openAwayPlanDetail
 * instead of encodeShellReturnTo('/fixed/path').
 */
'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const LIB = path.join(ROOT, 'flutter_app/lib');

/** Relative paths allowed to embed a fixed return target (keep empty when possible). */
const ALLOWLIST = new Set([]);

const PATTERN = /encodeShellReturnTo\s*\(\s*['"]\/[^'"]+['"]\s*\)/g;

function walk(dir, out = []) {
  for (const name of fs.readdirSync(dir)) {
    const full = path.join(dir, name);
    const st = fs.statSync(full);
    if (st.isDirectory()) walk(full, out);
    else if (name.endsWith('.dart')) out.push(full);
  }
  return out;
}

function rel(p) {
  return path.relative(ROOT, p).replace(/\\/g, '/');
}

let failed = false;
for (const file of walk(LIB)) {
  const r = rel(file);
  if (r.endsWith('shell_return_navigation.dart')) continue;
  const text = fs.readFileSync(file, 'utf8');
  const matches = text.match(PATTERN);
  if (!matches) continue;
  if (ALLOWLIST.has(r)) continue;
  failed = true;
  console.error(`check_hardcoded_shell_return_to: ${r}`);
  for (const m of matches) {
    console.error(`  ${m}`);
  }
}

if (failed) {
  console.error(
    'check_hardcoded_shell_return_to: use currentShellLocation or open*Detail helpers instead.',
  );
  process.exit(1);
}

console.log('check_hardcoded_shell_return_to: OK');
