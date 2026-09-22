#!/usr/bin/env node
/**
 * Merge coordination preflight for /babysit-plus — mutex + FIFO yield before merge.
 *
 * Usage:
 *   node scripts/babysit_merge_preflight.mjs --pr <url|num> [--json]
 *   node scripts/babysit_merge_preflight.mjs --pr <url|num> --claim [--force] [--json]
 *   node scripts/babysit_merge_preflight.mjs --pr <url|num> --release [--json]
 *
 * Exit codes:
 *   0 — clear to merge (or claim/release succeeded)
 *   1 — branch behind base; rebase once then re-run
 *   2 — wait (another PR holds merge-lease or FIFO yield)
 *   3 — error / do-not-merge
 */
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  DEFAULT_BASE_HOT_MINUTES,
  DEFAULT_LEASE_STALE_MINUTES,
  MERGE_LEASE_LABEL,
  evaluateMergePreflight,
  findCompetingGreenPrs,
  findLeaseHolder,
  isBaseHot,
  isLeaseStale,
} from './lib/babysit_merge_preflight_lib.js';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

function printUsage() {
  console.log(`Usage: ./scripts/babysit_merge_preflight.sh --pr <url|num> [options]

Options:
  --claim           Add merge-lease label when preflight is clear
  --release         Remove merge-lease label after merge
  --force           Override FIFO yield or stale lease on --claim
  --json            Emit machine-readable JSON
  -h, --help        Show this help

Exit codes: 0 clear, 1 rebase, 2 wait, 3 error`);
}

function usageError(msg) {
  console.error(`babysit_merge_preflight: ${msg}`);
  console.error(
    'usage: ./scripts/babysit_merge_preflight.sh --pr <url|num> [--claim|--release] [--force] [--json]',
  );
  process.exit(3);
}

function ghJson(args) {
  const result = spawnSync('gh', args, { cwd: repoRoot, encoding: 'utf8' });
  if (result.status !== 0) {
    console.error(result.stderr || result.stdout);
    process.exit(3);
  }
  const text = (result.stdout || '').trim();
  return text ? JSON.parse(text) : null;
}

function ghRun(args) {
  const result = spawnSync('gh', args, { cwd: repoRoot, encoding: 'utf8' });
  if (result.status !== 0) {
    console.error(result.stderr || result.stdout);
    process.exit(3);
  }
}

function syncBaseCheck(pr) {
  const script = path.join(repoRoot, 'scripts', 'babysit_sync_base.sh');
  const result = spawnSync(script, ['--pr', String(pr), '--check'], {
    cwd: repoRoot,
    encoding: 'utf8',
  });
  if (result.status === 0) {
    return false;
  }
  if (result.status === 1) {
    return true;
  }
  console.error(result.stderr || result.stdout);
  process.exit(3);
}

function parseArgs() {
  const opts = {
    pr: null,
    json: false,
    claim: false,
    release: false,
    force: false,
  };
  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    switch (arg) {
      case '--pr':
        opts.pr = argv[++i];
        if (!opts.pr) usageError('--pr requires a value');
        break;
      case '--json':
        opts.json = true;
        break;
      case '--claim':
        opts.claim = true;
        break;
      case '--release':
        opts.release = true;
        break;
      case '--force':
        opts.force = true;
        break;
      case '-h':
      case '--help':
        printUsage();
        process.exit(0);
      default:
        usageError(`unknown argument: ${arg}`);
    }
  }
  if (!opts.pr) {
    usageError('--pr is required');
  }
  if (opts.claim && opts.release) {
    usageError('--claim and --release are mutually exclusive');
  }
  return opts;
}

function listOpenPrsOnBase(baseBranch) {
  const prs = ghJson([
    'pr',
    'list',
    '--state',
    'open',
    '--base',
    baseBranch,
    '--limit',
    '50',
    '--json',
    'number,url,headRefName,updatedAt,title,mergeable,labels,statusCheckRollup',
  ]);
  return Array.isArray(prs) ? prs : [];
}

function baseTipPushedAt(baseBranch) {
  const data = ghJson([
    'api',
    `repos/{owner}/{repo}/commits/${baseBranch}`,
    '--jq',
    '.commit.committer.date',
  ]);
  return typeof data === 'string' ? data : null;
}

function loadContext(prRef) {
  const pr = ghJson([
    'pr',
    'view',
    String(prRef),
    '--json',
    'number,url,baseRefName,headRefName,labels,updatedAt,mergeable,statusCheckRollup',
  ]);
  const baseBranch = pr.baseRefName;
  const openPrs = listOpenPrsOnBase(baseBranch);
  const leaseHolder = findLeaseHolder(openPrs);
  const competingGreenPrs = findCompetingGreenPrs(openPrs, {
    prNumber: pr.number,
  });
  const hotMinutes = Number(
    process.env.MERGE_PREFLIGHT_BASE_HOT_MINUTES || DEFAULT_BASE_HOT_MINUTES,
  );
  const staleMinutes = Number(
    process.env.MERGE_PREFLIGHT_LEASE_STALE_MINUTES || DEFAULT_LEASE_STALE_MINUTES,
  );
  const nowMs = Date.now();
  const baseHot = isBaseHot(baseTipPushedAt(baseBranch), nowMs, hotMinutes);
  const behindBase = syncBaseCheck(prRef);
  const hasDoNotMerge = (pr.labels || []).some(
    (label) => label.name === 'do-not-merge',
  );
  const leaseStale =
    leaseHolder &&
    leaseHolder.number !== pr.number &&
    isLeaseStale(leaseHolder.updatedAt, nowMs, staleMinutes);

  const evaluation = evaluateMergePreflight({
    prNumber: pr.number,
    behindBase,
    leaseHolder,
    competingGreenPrs,
    baseHot,
    hasDoNotMerge,
    force: false,
    leaseStale,
  });

  return {
    pr,
    baseBranch,
    openPrs,
    leaseHolder,
    competingGreenPrs,
    baseHot,
    behindBase,
    evaluation,
    hotMinutes,
    staleMinutes,
    leaseStale,
  };
}

function printResult(payload, opts) {
  if (opts.json) {
    console.log(JSON.stringify(payload, null, 2));
    return;
  }
  const { evaluation } = payload;
  if (evaluation.allowed) {
    console.log(`babysit_merge_preflight: clear (PR #${payload.pr.number})`);
    return;
  }
  console.log(
    `babysit_merge_preflight: ${evaluation.reason} — ${evaluation.action}`,
  );
  if (evaluation.lease_holder) {
    console.log(
      `  lease holder: PR #${evaluation.lease_holder.number} ${evaluation.lease_holder.url || ''}`,
    );
  }
  if (evaluation.yield_to) {
    console.log(
      `  yield to: PR #${evaluation.yield_to.number} ${evaluation.yield_to.url || ''}`,
    );
  }
}

function main() {
  const opts = parseArgs();

  if (opts.release) {
    ghRun([
      'pr',
      'edit',
      String(opts.pr),
      '--remove-label',
      MERGE_LEASE_LABEL,
    ]);
    const payload = {
      command: 'release',
      pr: opts.pr,
      released: true,
      label: MERGE_LEASE_LABEL,
    };
    if (opts.json) {
      console.log(JSON.stringify(payload, null, 2));
    } else {
      console.log(`babysit_merge_preflight: released merge-lease on PR ${opts.pr}`);
    }
    process.exit(0);
  }

  const ctx = loadContext(opts.pr);
  let evaluation = ctx.evaluation;

  if (opts.claim) {
    if (!evaluation.allowed) {
      if (opts.force) {
        evaluation = evaluateMergePreflight({
          prNumber: ctx.pr.number,
          behindBase: ctx.behindBase,
          leaseHolder: ctx.leaseHolder,
          competingGreenPrs: ctx.competingGreenPrs,
          baseHot: ctx.baseHot,
          hasDoNotMerge: (ctx.pr.labels || []).some(
            (label) => label.name === 'do-not-merge',
          ),
          force: true,
          leaseStale: ctx.leaseStale,
        });
      }
      if (!evaluation.allowed) {
        const payload = {
          command: 'claim',
          pr: ctx.pr.number,
          base: ctx.baseBranch,
          ...evaluation,
        };
        printResult({ ...ctx, evaluation }, opts);
        if (opts.json) {
          console.log(JSON.stringify(payload, null, 2));
        }
        process.exit(evaluation.exitCode);
      }
    }

    ghRun(['pr', 'edit', String(opts.pr), '--add-label', MERGE_LEASE_LABEL]);
    const payload = {
      command: 'claim',
      pr: ctx.pr.number,
      base: ctx.baseBranch,
      claimed: true,
      label: MERGE_LEASE_LABEL,
      evaluation,
    };
    if (opts.json) {
      console.log(JSON.stringify(payload, null, 2));
    } else {
      console.log(`babysit_merge_preflight: claimed merge-lease on PR #${ctx.pr.number}`);
    }
    process.exit(0);
  }

  const payload = {
    command: 'check',
    pr: ctx.pr.number,
    base: ctx.baseBranch,
    base_hot: ctx.baseHot,
    behind_base: ctx.behindBase,
    competing_green_count: ctx.competingGreenPrs.length,
    lease_holder: ctx.leaseHolder
      ? { number: ctx.leaseHolder.number, url: ctx.leaseHolder.url }
      : null,
    ...evaluation,
  };

  printResult(ctx, opts);
  if (opts.json) {
    console.log(JSON.stringify(payload, null, 2));
  }
  process.exit(evaluation.exitCode);
}

main();
