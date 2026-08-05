#!/usr/bin/env node
/**
 * Tests for babysit_uat_shard_risk.mjs
 */
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
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
  assert.ok(out.shards.length >= 1);
  assert.ok(out.shards.some((s) => s.index === 12));
  assert.equal(out.merge_action, 'act_now');
}

{
  const out = run(['e2e/playwright/tests/organisation.edit.spec.ts']);
  const shard = out.shards.find((s) => s.index === 12);
  assert.ok(shard);
  assert.equal(shard.risk, 'high');
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
