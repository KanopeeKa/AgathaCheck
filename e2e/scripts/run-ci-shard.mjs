#!/usr/bin/env node
/**
 * Run one CI file-balanced shard (see shard-files.mjs).
 * Usage: npm run test:ci-shard -- 3
 */
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { SHARD_TOTAL } from './shard-files.mjs';

const e2eRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

const shardIndex = Number(process.argv[2]);
if (!Number.isInteger(shardIndex) || shardIndex < 1 || shardIndex > SHARD_TOTAL) {
  console.error(`usage: run-ci-shard.mjs <1-${SHARD_TOTAL}>`);
  process.exit(1);
}

const list = spawnSync('node', ['scripts/shard-files.mjs', String(shardIndex)], {
  cwd: e2eRoot,
  encoding: 'utf8',
});
if (list.status !== 0) {
  process.stderr.write(list.stderr);
  process.exit(list.status ?? 1);
}

const files = list.stdout.trim().split(/\s+/).filter(Boolean);
if (files.length === 0) {
  console.error(`Shard ${shardIndex} has no spec files`);
  process.exit(1);
}

const playwrightBin = path.join(e2eRoot, 'node_modules', '.bin', 'playwright');
const result = spawnSync(
  playwrightBin,
  ['test', '--project=full', '--max-failures=1', ...files],
  {
    cwd: e2eRoot,
    stdio: 'inherit',
  },
);
process.exit(result.status ?? 1);
