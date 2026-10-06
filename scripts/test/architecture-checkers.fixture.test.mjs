import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..', '..');
const SERVER_DIR = path.join(REPO_ROOT, 'server');

function runArchitectureJest(fixtureServerRoot, testFile, testNamePattern) {
  return spawnSync(
    'npx',
    [
      'jest',
      testFile,
      '--runInBand',
      '--forceExit',
      '--testNamePattern',
      testNamePattern,
    ],
    {
      cwd: SERVER_DIR,
      encoding: 'utf8',
      env: {
        ...process.env,
        GOVERNANCE_FIXTURE_SERVER_ROOT: fixtureServerRoot,
      },
    },
  );
}

test('transaction ownership architecture test fails on hand-written BEGIN in fixture tree', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'tx-fixture-'));
  const libDir = path.join(root, 'lib');
  fs.mkdirSync(libDir, { recursive: true });
  fs.writeFileSync(
    path.join(libDir, 'evil.js'),
    "export async function bad(pool) { await pool.query('BEGIN'); }\n",
  );

  const res = runArchitectureJest(
    root,
    'test/architecture/transactionOwnership.test.js',
    'active server code uses withTransaction',
  );
  assert.notEqual(res.status, 0);
  assert.match(res.stdout + res.stderr, /hand-written BEGIN|withOptionalTransaction/);
});

test('server direction architecture test fails when lib imports routes in fixture tree', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'dir-fixture-'));
  fs.mkdirSync(path.join(root, 'lib'), { recursive: true });
  fs.mkdirSync(path.join(root, 'routes'), { recursive: true });
  fs.writeFileSync(path.join(root, 'routes', 'target.js'), 'export const x = 1;\n');
  fs.writeFileSync(
    path.join(root, 'lib', 'evil.js'),
    "import x from '../routes/target.js';\nexport { x };\n",
  );

  const res = runArchitectureJest(
    root,
    'test/architecture/serverDirection.test.js',
    'has no server/lib or server/services imports from server/routes',
  );
  assert.notEqual(res.status, 0);
  assert.match(res.stdout + res.stderr, /lib\/evil\.js|routes/);
});
