#!/usr/bin/env node
/**
 * Map a PR diff to pre-UAT E2E shard risk (Option A: path overlap + flaky shard boost).
 *
 * Usage:
 *   node scripts/babysit_uat_shard_risk.mjs --paths-file changed.txt
 *   node scripts/babysit_uat_shard_risk.mjs --pr 612
 *   node scripts/babysit_uat_shard_risk.mjs --since-sha <sha>
 *   git diff --name-only origin/main...HEAD | node scripts/babysit_uat_shard_risk.mjs
 *
 * JSON stdout: { shards: [{ index, risk, specs, reasons }], merge_action: "wait"|"act_now" }
 */
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { SHARDS, SHARD_TOTAL } from '../e2e/scripts/shard-files.mjs';
import { AREAS, areasForPath, isBroadPath } from '../e2e/scripts/spec-domains.mjs';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

/**
 * Specs with historical flake sensitivity — boost their shards to high when overlapped.
 * (Spec-based, not shard-index-based: shard membership is duration-balanced and moves.)
 */
const HIGH_BOOST_SPECS = new Set([
  'guardian.dashboard.spec.ts',
  'guardian.navigation.spec.ts',
  'away.planning.spec.ts',
  'away.plan.detail.v2.spec.ts',
  'away.care.planning.spec.ts',
  'people-hub.spec.ts',
  'experience.navigation.spec.ts',
  'notifications.spec.ts',
]);

const RISK_ORDER = { none: 0, low: 1, medium: 2, high: 3 };
const ALL_SHARDS = Array.from({ length: SHARD_TOTAL }, (_, i) => i + 1);

const specToShard = new Map();
for (let i = 0; i < SHARDS.length; i++) {
  for (const spec of SHARDS[i]) {
    specToShard.set(spec, i + 1);
    specToShard.set(`e2e/${spec}`, i + 1);
  }
}

function usageError(msg) {
  console.error(`babysit_uat_shard_risk: ${msg}`);
  console.error('usage: node scripts/babysit_uat_shard_risk.mjs [--paths-file <file> | --pr <n> | --since-sha <sha> [--to-sha <sha>]]');
  process.exit(2);
}

function readChangedPaths() {
  const sinceIdx = process.argv.indexOf('--since-sha');
  if (sinceIdx !== -1) {
    const baseSha = process.argv[sinceIdx + 1];
    if (!baseSha || baseSha.startsWith('-')) {
      usageError('--since-sha requires a commit SHA');
    }
    const toIdx = process.argv.indexOf('--to-sha');
    const toSha =
      toIdx !== -1 && process.argv[toIdx + 1] && !process.argv[toIdx + 1].startsWith('-')
        ? process.argv[toIdx + 1]
        : 'origin/main';
    spawnSync('git', ['fetch', 'origin', 'main', '--depth=1', '--quiet'], { cwd: repoRoot });
    const diff = spawnSync('git', ['diff', '--name-only', baseSha, toSha], {
      cwd: repoRoot,
      encoding: 'utf8',
    });
    if (diff.status !== 0) {
      console.error(diff.stderr || diff.stdout);
      process.exit(1);
    }
    return diff.stdout.split('\n').map((p) => p.trim()).filter(Boolean);
  }

  const pathsFileIdx = process.argv.indexOf('--paths-file');
  if (pathsFileIdx !== -1) {
    const file = process.argv[pathsFileIdx + 1];
    if (!file || file.startsWith('-')) {
      usageError('--paths-file requires a file path');
    }
    const abs = path.isAbsolute(file) ? file : path.join(repoRoot, file);
    return fs
      .readFileSync(abs, 'utf8')
      .split('\n')
      .map((line) => line.trim())
      .filter(Boolean);
  }

  const prIdx = process.argv.indexOf('--pr');
  if (prIdx !== -1) {
    const pr = process.argv[prIdx + 1];
    if (!pr || pr.startsWith('-')) {
      usageError('--pr requires a PR number or URL');
    }
    const files = spawnSync(
      'gh',
      ['pr', 'view', pr, '--json', 'files', '-q', '.files[].path'],
      { cwd: repoRoot, encoding: 'utf8' },
    );
    if (files.status !== 0) {
      console.error(files.stderr);
      process.exit(1);
    }
    return files.stdout.split('\n').map((p) => p.trim()).filter(Boolean);
  }

  const chunks = [];
  if (!process.stdin.isTTY) {
    chunks.push(fs.readFileSync(0, 'utf8'));
  }
  if (chunks.length) {
    return chunks
      .join('\n')
      .split('\n')
      .map((p) => p.trim())
      .filter(Boolean);
  }

  spawnSync('git', ['fetch', 'origin', 'main', '--depth=1', '--quiet'], { cwd: repoRoot });
  const base = spawnSync('git', ['merge-base', 'HEAD', 'origin/main'], {
    cwd: repoRoot,
    encoding: 'utf8',
  });
  const diff = spawnSync('git', ['diff', '--name-only', base.stdout.trim() || 'HEAD', 'HEAD'], {
    cwd: repoRoot,
    encoding: 'utf8',
  });
  return diff.stdout.split('\n').map((p) => p.trim()).filter(Boolean);
}

function classifyPath(changedPath) {
  const hits = [];

  const directSpec = specToShard.get(changedPath);
  if (directSpec) {
    hits.push({ shard: directSpec, risk: 'high', reason: `direct spec change: ${changedPath}` });
  }

  const specMatch = changedPath.match(/^e2e\/playwright\/tests\/(.+\.spec\.ts)$/);
  if (specMatch) {
    const rel = `playwright/tests/${specMatch[1]}`;
    const shard = specToShard.get(rel);
    if (shard) {
      hits.push({ shard, risk: 'high', reason: `direct spec change: ${rel}` });
    }
  }

  if (changedPath.startsWith('e2e/playwright/support/') || changedPath.startsWith('e2e/playwright/fixtures/')) {
    for (const shard of ALL_SHARDS) hits.push({ shard, risk: 'medium', reason: `shared E2E support: ${changedPath}` });
  } else if (isBroadPath(changedPath)) {
    for (const shard of ALL_SHARDS) hits.push({ shard, risk: 'low', reason: `shared core: ${changedPath}` });
  }

  for (const area of areasForPath(changedPath)) {
    for (const spec of AREAS[area].specs) {
      const shard = specToShard.get(`playwright/tests/${spec}`);
      if (!shard) continue;
      const risk = HIGH_BOOST_SPECS.has(spec) ? 'high' : 'medium';
      hits.push({ shard, risk, reason: `${area} (${spec}): ${changedPath}` });
    }
  }

  return hits;
}

const changed = readChangedPaths();
/** @type {Map<number, { risk: string, reasons: Set<string>, specs: string[] }>} */
const shardMap = new Map();

for (let i = 1; i <= SHARD_TOTAL; i++) {
  shardMap.set(i, { risk: 'none', reasons: new Set(), specs: [...SHARDS[i - 1]] });
}

for (const filePath of changed) {
  for (const hit of classifyPath(filePath)) {
    const entry = shardMap.get(hit.shard);
    if (!entry) continue;
    entry.reasons.add(hit.reason);
    if (RISK_ORDER[hit.risk] > RISK_ORDER[entry.risk]) {
      entry.risk = hit.risk;
    }
  }
}

const shards = [...shardMap.entries()]
  .map(([index, { risk, reasons, specs }]) => ({
    index,
    risk,
    specs,
    reasons: [...reasons],
  }))
  .filter((s) => s.risk !== 'none')
  .sort((a, b) => RISK_ORDER[b.risk] - RISK_ORDER[a.risk] || a.index - b.index);

const mergeAction = shards.some((s) => s.risk === 'high') ? 'act_now' : 'wait';

const result = {
  changed_files: changed.length,
  shard_total: SHARD_TOTAL,
  merge_action: mergeAction,
  shards,
  at_risk_shards: shards.map((s) => s.index),
};

console.log(JSON.stringify(result, null, 2));
