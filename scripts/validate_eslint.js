#!/usr/bin/env node
/**
 * Run ESLint ratchet on Pet Care policy modules (F-20).
 * Usage: node scripts/validate_eslint.js
 */
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..');
const ESLINT_BIN = path.join(REPO_ROOT, 'server/node_modules/eslint/bin/eslint.js');

const LINT_PATHS = [
  'server/routes/weightEntries.js',
  'server/lib/petAccess.js',
  'server/lib/petCapabilityPolicy.js',
  'server/lib/openapi',
];

function fail(msg) {
  console.error(`validate_eslint: ${msg}`);
  process.exit(1);
}

function main() {
  if (!fs.existsSync(ESLINT_BIN)) {
    fail('eslint not installed — run npm ci in server/');
  }
  execFileSync(
    process.execPath,
    [ESLINT_BIN, ...LINT_PATHS, '--config', 'eslint.config.js'],
    { cwd: REPO_ROOT, stdio: 'inherit' },
  );
  console.log('validate_eslint: OK');
}

main();
