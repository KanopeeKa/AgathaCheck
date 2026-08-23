#!/usr/bin/env node
/**
 * Resolve pre-UAT E2E remedial scope: diff since last green run + failed shards union.
 *
 * Usage:
 *   node scripts/e2e_debug_resolve.mjs --json
 *   node scripts/e2e_debug_resolve.mjs --merge-sha <sha> --json
 *   node scripts/e2e_debug_resolve.mjs --run-id <id> --json
 *   node scripts/e2e_debug_resolve.mjs --proactive --json
 *   node scripts/e2e_debug_resolve.mjs --baseline-sha <sha> --json   # skip gh lookup
 */
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

const RISK_ORDER = { none: 0, low: 1, medium: 2, high: 3 };

function usageError(msg) {
  console.error(`e2e_debug_resolve: ${msg}`);
  console.error(
    'usage: node scripts/e2e_debug_resolve.mjs [--merge-sha <sha>|--run-id <id>] [--proactive] [--baseline-sha <sha>] [--json]',
  );
  process.exit(2);
}

function ghJson(args) {
  const result = spawnSync('gh', args, { cwd: repoRoot, encoding: 'utf8' });
  if (result.status !== 0) {
    console.error(result.stderr || result.stdout);
    process.exit(1);
  }
  return JSON.parse(result.stdout || 'null');
}

function gitRevParse(ref) {
  const result = spawnSync('git', ['rev-parse', ref], { cwd: repoRoot, encoding: 'utf8' });
  if (result.status !== 0) {
    console.error(result.stderr || result.stdout);
    process.exit(1);
  }
  return result.stdout.trim();
}

function fetchMain() {
  spawnSync('git', ['fetch', 'origin', 'main', '--quiet'], { cwd: repoRoot });
}

/**
 * @param {number[]} failedShards
 * @param {{ index: number, risk: string }[]} riskShards
 * @param {string[]} changedPaths
 */
export function computeTargetShards(failedShards, riskShards, changedPaths) {
  const atRisk = [];
  const supportChanged = changedPaths.some((p) => p.startsWith('e2e/playwright/support/'));

  for (const shard of riskShards) {
    const order = RISK_ORDER[shard.risk] ?? 0;
    if (order >= RISK_ORDER.medium) {
      atRisk.push(shard.index);
    } else if (order >= RISK_ORDER.low && supportChanged) {
      atRisk.push(shard.index);
    }
  }

  const failed = failedShards.filter((n) => Number.isInteger(n) && n > 0);
  const union = [...new Set([...failed, ...atRisk])];
  return union.sort((a, b) => a - b);
}

function findLastGreenPreUatRun() {
  const runs = ghJson([
    'run',
    'list',
    '--workflow=pre-uat-e2e.yml',
    '--branch=main',
    '--limit=80',
    '--json',
    'databaseId,headSha,status,conclusion,url,createdAt',
  ]);
  if (!Array.isArray(runs)) {
    return null;
  }
  return runs.find((r) => r.conclusion === 'success');
}

function findRunForMergeSha(mergeSha) {
  const target = mergeSha.toLowerCase().trim();
  const runs = ghJson([
    'run',
    'list',
    '--workflow=pre-uat-e2e.yml',
    '--branch=main',
    '--limit=100',
    '--json',
    'databaseId,headSha,status,conclusion,url,createdAt',
  ]);
  const exact = runs.filter((r) => (r.headSha || '').toLowerCase() === target);
  if (exact.length) {
    return exact[0];
  }
  const prefix = target.slice(0, Math.min(target.length, 12));
  const matches = runs.filter((r) => (r.headSha || '').toLowerCase().startsWith(prefix));
  if (matches.length === 1) {
    return matches[0];
  }
  if (matches.length > 1 && target.length >= 12) {
    const narrow = matches.filter((r) => (r.headSha || '').toLowerCase().startsWith(target.slice(0, 12)));
    if (narrow.length === 1) {
      return narrow[0];
    }
  }
  return null;
}

function failedShardsFromRun(runId) {
  const data = ghJson(['run', 'view', String(runId), '--json', 'jobs']);
  const failed = [];
  for (const job of data.jobs || []) {
    if (job.conclusion !== 'failure') {
      continue;
    }
    const name = job.name || '';
    const m = name.match(/shard[\s/_-]*(\d+)/i);
    if (m) {
      failed.push(Number(m[1]));
    } else if (/Full localhost E2E/i.test(name) || /e2e-full/i.test(name)) {
      failed.push(-1);
    }
  }
  return [...new Set(failed)].sort((a, b) => a - b);
}

function runShardRisk(sinceSha, toSha) {
  const args = ['scripts/babysit_uat_shard_risk.mjs', '--since-sha', sinceSha];
  if (toSha) {
    args.push('--to-sha', toSha);
  }
  const result = spawnSync('node', args, { cwd: repoRoot, encoding: 'utf8' });
  if (result.status !== 0) {
    console.error(result.stderr || result.stdout);
    process.exit(1);
  }
  return JSON.parse(result.stdout);
}

function parseArgs() {
  const opts = {
    json: false,
    proactive: false,
    mergeSha: null,
    runId: null,
    baselineSha: null,
  };
  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    switch (arg) {
      case '--json':
        opts.json = true;
        break;
      case '--proactive':
        opts.proactive = true;
        break;
      case '--merge-sha':
        opts.mergeSha = argv[++i];
        if (!opts.mergeSha) usageError('--merge-sha requires a value');
        break;
      case '--run-id':
        opts.runId = argv[++i];
        if (!opts.runId) usageError('--run-id requires a value');
        break;
      case '--baseline-sha':
        opts.baselineSha = argv[++i];
        if (!opts.baselineSha) usageError('--baseline-sha requires a value');
        break;
      default:
        usageError(`unknown argument: ${arg}`);
    }
  }
  return opts;
}

function main() {
  const opts = parseArgs();
  fetchMain();
  const headSha = gitRevParse('origin/main');

  let baselineSha = opts.baselineSha;
  let baselineRun = null;
  let baselineWarning = null;

  if (!baselineSha) {
    baselineRun = findLastGreenPreUatRun();
    if (baselineRun?.headSha) {
      baselineSha = baselineRun.headSha;
    } else {
      baselineSha = gitRevParse('origin/main~20');
      baselineWarning = 'no_green_pre_uat_run_found; using origin/main~20 as baseline';
    }
  }

  let failingRun = null;
  let failedShards = [];

  if (opts.runId) {
    failingRun = { databaseId: Number(opts.runId), headSha: opts.mergeSha || headSha };
    failedShards = failedShardsFromRun(opts.runId);
  } else if (opts.mergeSha) {
    failingRun = findRunForMergeSha(opts.mergeSha);
    if (failingRun) {
      failedShards = failedShardsFromRun(failingRun.databaseId);
    } else if (!opts.proactive) {
      baselineWarning = (baselineWarning ? `${baselineWarning}; ` : '') + 'no_run_for_merge_sha';
    }
  }

  const risk = runShardRisk(baselineSha, headSha);

  const diffResult = spawnSync('git', ['diff', '--name-only', baselineSha, headSha], {
    cwd: repoRoot,
    encoding: 'utf8',
  });
  const changedPaths =
    diffResult.status === 0
      ? diffResult.stdout.split('\n').map((p) => p.trim()).filter(Boolean)
      : [];

  const targetShards = computeTargetShards(failedShards, risk.shards, changedPaths);

  const remedialBranch = `cursor/preuat-fix-${headSha.slice(0, 8)}-6bba`;

  const result = {
    mode: opts.proactive ? 'proactive' : failedShards.length ? 'reactive' : 'scope_only',
    head_sha: headSha,
    baseline_sha: baselineSha,
    baseline_run_id: baselineRun?.databaseId ?? null,
    baseline_run_url: baselineRun?.url ?? null,
    failing_run_id: failingRun?.databaseId ?? null,
    failing_run_url: failingRun?.url ?? null,
    failed_shards: failedShards,
    changed_files: changedPaths.length,
    changed_paths_sample: changedPaths.slice(0, 20),
    merge_action: risk.merge_action,
    at_risk_shards: risk.at_risk_shards,
    risk_shards: risk.shards,
    target_shards: targetShards,
    remedial_branch: remedialBranch,
    parallel_workers: targetShards.length > 1,
    warning: baselineWarning,
  };

  if (opts.json) {
    console.log(JSON.stringify(result, null, 2));
  } else {
    console.log(`baseline: ${baselineSha.slice(0, 7)} → head: ${headSha.slice(0, 7)}`);
    console.log(`target_shards: ${targetShards.join(',')}`);
    console.log(`remedial_branch: ${remedialBranch}`);
    if (baselineWarning) {
      console.log(`warning: ${baselineWarning}`);
    }
  }
}

const invokedAsMain =
  process.argv[1] && fileURLToPath(import.meta.url) === fileURLToPath(`file://${process.argv[1]}`);
if (invokedAsMain) {
  main();
}
