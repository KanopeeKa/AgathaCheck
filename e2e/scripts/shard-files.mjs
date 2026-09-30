#!/usr/bin/env node
/**
 * Duration-balanced Playwright shards for Pre-UAT E2E (active Pet Care specs only).
 *
 * Every active spec in playwright/tests (frozen Shelter/Fostering specs from
 * frozen-e2e-specs.mjs and the live-UAT warmup excluded) is assigned by LPT
 * (longest processing time first → least-loaded shard) using the measured
 * per-spec times in spec-durations.json. New specs are picked up automatically
 * with the default estimate, so the manifest cannot drift from the tests folder.
 * Output is deterministic (ties broken by name, then lowest shard index).
 *
 * Usage:
 *   node e2e/scripts/shard-files.mjs           # print manifest summary with estimated load
 *   node e2e/scripts/shard-files.mjs 3         # print space-separated paths for shard 3
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { FROZEN_E2E_SPECS } from './frozen-e2e-specs.mjs';

export const SHARD_TOTAL = 9;

const here = path.dirname(fileURLToPath(import.meta.url));
const TESTS_DIR = path.join(here, '..', 'playwright', 'tests');
const DURATIONS = JSON.parse(fs.readFileSync(path.join(here, 'spec-durations.json'), 'utf8'));

/** Specs never run by Pre-UAT localhost shards. */
export const NON_SHARD_SPECS = new Set(['uat-auth-warmup.spec.ts', ...FROZEN_E2E_SPECS]);

export function activeSpecs(testsDir = TESTS_DIR) {
  return fs
    .readdirSync(testsDir)
    .filter((f) => f.endsWith('.spec.ts') && !NON_SHARD_SPECS.has(f))
    .sort();
}

export function specSeconds(spec, durations = DURATIONS) {
  return durations.specs?.[spec] ?? durations.defaultSec ?? 90;
}

/**
 * LPT assignment of specs into `total` shards.
 * @returns {{ shards: string[][], loads: number[] }} shard entries are spec basenames
 */
export function balanceSpecs(specs, total, secondsOf) {
  const order = [...specs].sort((a, b) => secondsOf(b) - secondsOf(a) || a.localeCompare(b));
  const shards = Array.from({ length: total }, () => []);
  const loads = Array.from({ length: total }, () => 0);
  for (const spec of order) {
    let target = 0;
    for (let i = 1; i < total; i++) if (loads[i] < loads[target]) target = i;
    shards[target].push(spec);
    loads[target] += secondsOf(spec);
  }
  for (const shard of shards) shard.sort();
  return { shards, loads };
}

const balanced = balanceSpecs(activeSpecs(), SHARD_TOTAL, (spec) => specSeconds(spec));

/** @type {string[][]} e2e-relative paths per shard (index 0 = shard 1). */
export const SHARDS = balanced.shards.map((shard) => shard.map((spec) => `playwright/tests/${spec}`));
export const SHARD_LOADS = balanced.loads;

if (SHARDS.length !== SHARD_TOTAL) {
  throw new Error(`shard-files.mjs: expected ${SHARD_TOTAL} shards, got ${SHARDS.length}`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1])) {
  const shardArg = process.argv[2];
  if (shardArg === undefined || shardArg === '--summary') {
    for (let i = 0; i < SHARDS.length; i++) {
      console.log(`Shard ${i + 1}/${SHARD_TOTAL} (~${SHARD_LOADS[i]}s): ${SHARDS[i].join(', ')}`);
    }
  } else {
    const index = Number(shardArg);
    if (!Number.isInteger(index) || index < 1 || index > SHARD_TOTAL) {
      console.error(`usage: shard-files.mjs <1-${SHARD_TOTAL}>`);
      process.exit(1);
    }
    console.log(SHARDS[index - 1].join(' '));
  }
}
