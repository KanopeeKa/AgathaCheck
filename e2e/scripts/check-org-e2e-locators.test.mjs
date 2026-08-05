#!/usr/bin/env node
/**
 * Unit tests for check-org-e2e-locators.mjs (spawn with fixture paths).
 */
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const script = path.join(repoRoot, 'e2e/scripts/check-org-e2e-locators.mjs');

function runWithPaths(paths) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'org-locator-'));
  const pathsFile = path.join(tmp, 'paths.txt');
  fs.writeFileSync(pathsFile, paths.join('\n'));
  const result = spawnSync('node', [script, '--paths-file', pathsFile], {
    cwd: repoRoot,
    encoding: 'utf8',
  });
  fs.rmSync(tmp, { recursive: true, force: true });
  return result;
}

// Unrelated diff — skip
{
  const result = runWithPaths(['server/routes/pets/index.js']);
  assert.equal(result.status, 0, result.stderr || result.stdout);
  assert.match(result.stdout, /skip/);
}

// Org Flutter without E2E touch — current tree should be clean
{
  const result = runWithPaths([
    'flutter_app/lib/features/organization/presentation/widgets/foo.dart',
  ]);
  assert.equal(result.status, 0, result.stderr || result.stdout);
  assert.match(result.stdout, /no known stale patterns/);
}

// Org Flutter + E2E touch — skip scan
{
  const result = runWithPaths([
    'flutter_app/lib/features/organization/presentation/widgets/foo.dart',
    'e2e/playwright/pages/organization-detail.page.ts',
  ]);
  assert.equal(result.status, 0, result.stderr || result.stdout);
  assert.match(result.stdout, /org E2E files updated/);
}

console.log('check-org-e2e-locators tests passed');
