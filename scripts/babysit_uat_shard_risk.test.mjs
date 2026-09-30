#!/usr/bin/env node
/**
 * Tests for babysit_uat_shard_risk.mjs
 */
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { SHARDS } from '../e2e/scripts/shard-files.mjs';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const script = path.join(repoRoot, 'scripts/babysit_uat_shard_risk.mjs');

function run(paths) {
  const result = spawnSync('node', [script], {
    cwd: repoRoot,
    input: paths.join('\n'),
    encoding: 'utf8',
  });
  assert.equal(result.status, 0, result.stderr || result.stdout);
  return JSON.parse(result.stdout);
}

{
  const out = run(['docs/readme.md']);
  assert.equal(out.shards.length, 0);
  assert.equal(out.merge_action, 'wait');
}

{
  const out = run(['flutter_app/lib/features/organization/presentation/screens/foo.dart']);
  assert.equal(out.shards.length, 0);
  assert.equal(out.merge_action, 'wait');
}

{
  const out = run(['e2e/playwright/tests/organisation.edit.spec.ts']);
  assert.equal(out.shards.length, 0);
  assert.equal(out.merge_action, 'wait');
}

{
  const out = run(['flutter_app/lib/features/experience/presentation/screens/foo.dart']);
  assert.ok(out.shards.length >= 1);
  const navShard = SHARDS.findIndex((shard) => shard.includes('playwright/tests/guardian.navigation.spec.ts')) + 1;
  const hit = out.shards.find((s) => s.index === navShard);
  assert.ok(hit, `experience change should flag the shard holding guardian.navigation (${navShard})`);
  assert.equal(hit.risk, 'high');
}

{
  const result = spawnSync('node', [script, '--pr'], {
    cwd: repoRoot,
    encoding: 'utf8',
  });
  assert.equal(result.status, 2);
  assert.match(result.stderr, /--pr requires/);
}

console.log('babysit_uat_shard_risk tests passed');
