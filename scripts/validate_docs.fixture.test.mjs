import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..');

function copyCheckDocPlacement(root) {
  const scriptsDir = path.join(root, 'scripts');
  fs.mkdirSync(scriptsDir, { recursive: true });
  fs.copyFileSync(
    path.join(REPO_ROOT, 'scripts/check_doc_placement.js'),
    path.join(scriptsDir, 'check_doc_placement.js'),
  );
  fs.mkdirSync(path.join(root, 'server/node_modules'), { recursive: true });
  fs.cpSync(
    path.join(REPO_ROOT, 'server/node_modules/js-yaml'),
    path.join(root, 'server/node_modules/js-yaml'),
    { recursive: true },
  );
}

test('check_doc_placement fails on deliberate misplaced root doc (docs validation gate)', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'docs-fixture-'));
  copyCheckDocPlacement(root);
  fs.mkdirSync(path.join(root, 'docs'), { recursive: true });
  fs.writeFileSync(path.join(root, 'docs', 'stray.md'), '# stray\n');

  const res = spawnSync(process.execPath, [path.join(root, 'scripts/check_doc_placement.js')], {
    encoding: 'utf8',
  });
  assert.equal(res.status, 1);
  assert.match(res.stderr + res.stdout, /Misplaced root doc/);
});

test('check_doc_placement passes on allowed root docs layout', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'docs-fixture-'));
  copyCheckDocPlacement(root);
  fs.mkdirSync(path.join(root, 'docs'), { recursive: true });
  fs.writeFileSync(path.join(root, 'docs', 'README.md'), '# ok\n');

  const res = spawnSync(process.execPath, [path.join(root, 'scripts/check_doc_placement.js')], {
    encoding: 'utf8',
  });
  assert.equal(res.status, 0);
});
