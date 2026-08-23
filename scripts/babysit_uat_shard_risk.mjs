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

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

/** Shards with historical flake / org IA sensitivity — boost to high when overlapped. */
const HIGH_BOOST_SHARDS = new Set([3, 10, 12, 13]);

const RISK_ORDER = { none: 0, low: 1, medium: 2, high: 3 };

/** Repo-relative path patterns → shard indices (1-based). */
const PATH_TO_SHARDS = [
  {
    re: /^flutter_app\/lib\/features\/organization\//,
    shards: [3, 10, 12, 13],
    reason: 'org Flutter',
  },
  {
    re: /^flutter_app\/test\/features\/organization\//,
    shards: [3, 10, 12, 13],
    reason: 'org Flutter tests',
  },
  {
    re: /^flutter_app\/lib\/core\/router\/organization/,
    shards: [3, 10, 12, 13],
    reason: 'org routes',
  },
  {
    re: /^server\/routes\/organizations\//,
    shards: [3, 10, 12, 13],
    reason: 'org API',
  },
  {
    re: /^e2e\/playwright\/pages\/organization/,
    shards: [3, 12, 13],
    reason: 'org Playwright pages',
  },
  {
    re: /^e2e\/playwright\/pages\/manage-fosters/,
    shards: [13],
    reason: 'foster Playwright page',
  },
  {
    re: /^flutter_app\/lib\/features\/health_tracking\//,
    shards: [2],
    reason: 'health Flutter',
  },
  {
    re: /^flutter_app\/lib\/features\/pet_profile\//,
    shards: [4, 5, 6, 7, 8],
    reason: 'pet Flutter',
  },
  {
    re: /^flutter_app\/lib\/features\/auth\//,
    shards: [3, 9, 11],
    reason: 'auth Flutter',
  },
  {
    re: /^flutter_app\/lib\/features\/experience\//,
    shards: [11, 13],
    reason: 'experience Flutter',
  },
  {
    re: /^flutter_app\/lib\/l10n\//,
    shards: [3, 10, 12, 13],
    reason: 'l10n (org-heavy)',
    risk: 'low',
  },
  {
    re: /^flutter_app\/lib\/core\//,
    shards: [3, 9, 10, 11, 12, 13],
    reason: 'shared core',
    risk: 'low',
  },
  {
    re: /^e2e\/playwright\/support\//,
    shards: Array.from({ length: SHARD_TOTAL }, (_, i) => i + 1),
    reason: 'shared E2E support',
    risk: 'medium',
  },
];

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

  for (const rule of PATH_TO_SHARDS) {
    if (!rule.re.test(changedPath)) continue;
    const baseRisk = rule.risk ?? 'medium';
    for (const shard of rule.shards) {
      let risk = baseRisk;
      if (baseRisk !== 'low' && HIGH_BOOST_SHARDS.has(shard)) {
        risk = 'high';
      }
      hits.push({ shard, risk, reason: `${rule.reason}: ${changedPath}` });
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
