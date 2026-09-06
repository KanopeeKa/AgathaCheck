import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..');

test('validate_eslint.js exits 0 on ratchet paths', () => {
  const out = execFileSync('node', ['scripts/validate_eslint.js'], {
    cwd: REPO_ROOT,
    encoding: 'utf8',
  });
  assert.match(out, /validate_eslint: OK/);
});
