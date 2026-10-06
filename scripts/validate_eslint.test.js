import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { createRequire } from 'node:module';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

import { collectViolations, runEslint } from './validate_eslint.js';

const require = createRequire(import.meta.url);
const { listActiveServerFiles } = require('./lib/active-server-universe.js');

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..');

test('validate_eslint.js exits 0 on active server universe with baseline', () => {
  const out = execFileSync('node', ['scripts/validate_eslint.js'], {
    cwd: REPO_ROOT,
    encoding: 'utf8',
  });
  assert.match(out, /validate_eslint: OK/);
});

test('new eslint violation fails against empty baseline in fixture repo', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'eslint-fixture-'));
  const relFile = 'server/lib/bad.js';
  fs.mkdirSync(path.join(root, 'server/lib'), { recursive: true });
  fs.mkdirSync(path.join(root, 'docs/engineering/frozen-domains'), { recursive: true });
  fs.writeFileSync(
    path.join(root, 'docs/engineering/frozen-domains/manifest.json'),
    JSON.stringify({ serverRoots: [] }),
  );
  fs.writeFileSync(
    path.join(root, 'server/eslint-baseline.json'),
    JSON.stringify({ violations: [] }, null, 2),
  );
  fs.writeFileSync(
    path.join(root, 'server/eslint.config.js'),
    fs.readFileSync(path.join(REPO_ROOT, 'server/eslint.config.js')),
  );
  fs.writeFileSync(path.join(root, relFile), 'const unused = 1;\nexport default 1;\n');

  const results = runEslint(root, [relFile]);
  assert.ok(collectViolations(root, results).size >= 1);

  let failed = false;
  try {
    execFileSync('node', ['scripts/validate_eslint.js', '--root', root], {
      cwd: REPO_ROOT,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
    });
  } catch (err) {
    failed = true;
    assert.match(String(err.stderr || err.stdout), /new violation\(s\)/i);
  }
  assert.equal(failed, true);
});

test('listActiveServerFiles excludes manifest frozen route roots', () => {
  const files = listActiveServerFiles(REPO_ROOT);
  assert.ok(files.some((f) => f.startsWith('server/lib/')));
  assert.ok(!files.some((f) => f.startsWith('server/routes/organizations/')));
});
