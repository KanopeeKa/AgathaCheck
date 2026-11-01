#!/usr/bin/env node
/**
 * Execute-plan control issue + plan artifact runtime (v2).
 *
 * Usage:
 *   node scripts/execute_plan_runtime.js gate <plan_id> [--json] [--actor agent|driver] [--dry-run]
 *   node scripts/execute_plan_runtime.js tick <plan_id> [--issue N] [--json] [--actor agent|driver] [--dry-run]
 *   node scripts/execute_plan_runtime.js init <plan_id> [--window-days N] [--dry-run]
 *   node scripts/execute_plan_runtime.js complete-plan <plan_id> [--write] [--dry-run]
 *   node scripts/execute_plan_runtime.js check-diff --pr <n> [--repo owner/name] [--publish]
 *   node scripts/execute_plan_runtime.js watch-ci <plan_id> --pr <n> [--timeout-min 25]
 *   node scripts/execute_plan_runtime.js watch-preuat <plan_id> [--issue N] [--timeout-min 90]
 *   node scripts/execute_plan_runtime.js watch-preuat-sha <merge_sha> [--json] [--timeout-min 90]
 *   node scripts/execute_plan_runtime.js watch-deploy <plan_id> [--issue N] [--timeout-min 45]
 *   node scripts/execute_plan_runtime.js roadmap-status <roadmap_id>
 *   node scripts/execute_plan_runtime.js roadmap-next-child <roadmap_id>
 *   node scripts/execute_plan_runtime.js roadmap-set-child <roadmap_id> --child <plan_id> --status <status> [--pr-url u] [--merge-commit sha] [--write]
 */

'use strict';

const {
  computeHash,
  loadSnapshot,
  ExecutePlanError,
} = require('./lib/execute_plan_lib');
const {
  findNextPendingChild,
  roadmapStatus,
  setRoadmapChildStatus,
  validateRoadmap,
} = require('./lib/execute_plan_roadmap');
const { atomicWriteFile, planPaths } = require('./lib/execute_plan_schema');

function usage() {
  console.error(`Usage: node scripts/execute_plan_runtime.js <command> [options]

Commands:
  gate <plan_id> [--json] [--actor agent|driver] [--dry-run]   (alias of tick)
  tick <plan_id> [--issue N] [--json] [--actor agent|driver] [--dry-run]
  init <plan_id> [--window-days N] [--dry-run]
  complete-plan <plan_id> [--write] [--dry-run]
  check-diff --pr <n> [--repo owner/name] [--publish]
  watch-ci <plan_id> --pr <n> [--timeout-min 25]
  watch-preuat <plan_id> [--issue N] [--timeout-min 90]
  watch-preuat-sha <merge_sha> [--json] [--timeout-min 90]
  watch-deploy <plan_id> [--issue N] [--timeout-min 45]
  roadmap-status <roadmap_id>
  roadmap-next-child <roadmap_id>
  roadmap-set-child <roadmap_id> --child <plan_id> --status <status> [--pr-url u] [--merge-commit sha] [--write]
`);
  process.exit(1);
}

function fail(msg, code = 1) {
  console.error(`execute_plan_runtime: ${msg}`);
  process.exit(code);
}

function parseArgs(argv) {
  const positional = [];
  const flags = {};
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg.startsWith('--')) {
      const key = arg.slice(2);
      const next = argv[i + 1];
      if (!next || next.startsWith('--')) {
        flags[key] = true;
      } else {
        flags[key] = next;
        i += 1;
      }
    } else {
      positional.push(arg);
    }
  }
  return { positional, flags };
}

function printJson(obj) {
  console.log(JSON.stringify(obj, null, 2));
}

function assertLegacyRoadmap(snapshot) {
  if (snapshot.schema_version !== 1 || snapshot.plan_kind !== 'roadmap') {
    throw new ExecutePlanError(
      'roadmap CLI requires a legacy schema-1 roadmap snapshot on disk; v2 plans use tick only'
    );
  }
  validateRoadmap(snapshot);
}

function saveLegacyRoadmapSnapshot(planId, snapshot) {
  assertLegacyRoadmap(snapshot);
  const { snapshotJson } = planPaths(planId);
  snapshot.content_hash = computeHash(snapshot);
  atomicWriteFile(snapshotJson, `${JSON.stringify(snapshot, null, 2)}\n`);
}

function main() {
  const { positional, flags } = parseArgs(process.argv.slice(2));
  const cmd = positional[0];
  const arg1 = positional[1];
  if (!cmd) usage();

  if (flags.labels) {
    fail('--labels is removed; use tick (gate is an alias of tick)');
  }

  const asyncCmds = new Set([
    'gate',
    'tick',
    'init',
    'check-diff',
    'complete-plan',
    'watch-ci',
    'watch-preuat',
    'watch-preuat-sha',
    'watch-deploy',
  ]);
  if (asyncCmds.has(cmd)) {
    runAsync(cmd, arg1, flags, positional).catch((e) => {
      fail(e.message, e.exitCode || 1);
    });
    return;
  }

  try {
    runSync(cmd, arg1, flags);
  } catch (e) {
    fail(e instanceof ExecutePlanError ? e.message : e.message);
  }
}

function runSync(cmd, planId, flags) {
  switch (cmd) {
    case 'roadmap-status': {
      if (!planId) usage();
      const snapshot = loadSnapshot(planId);
      assertLegacyRoadmap(snapshot);
      printJson(roadmapStatus(snapshot));
      break;
    }

    case 'roadmap-next-child': {
      if (!planId) usage();
      const snapshot = loadSnapshot(planId);
      assertLegacyRoadmap(snapshot);
      const next = findNextPendingChild(snapshot);
      printJson({
        roadmap_id: planId,
        next_child_plan_id: next?.plan_id ?? null,
        child: next,
      });
      break;
    }

    case 'roadmap-set-child': {
      if (!planId || !flags.child || !flags.status) usage();
      const snapshot = loadSnapshot(planId);
      assertLegacyRoadmap(snapshot);
      setRoadmapChildStatus(snapshot, flags.child, flags.status, {
        pr_url: flags['pr-url'],
        merge_commit: flags['merge-commit'],
      });
      if (flags.write) {
        saveLegacyRoadmapSnapshot(planId, snapshot);
        printJson({
          ok: true,
          ...roadmapStatus(snapshot),
        });
      } else {
        printJson({
          ok: true,
          dry_run: true,
          ...roadmapStatus(snapshot),
        });
        console.error('execute_plan_runtime: dry-run (pass --write to persist)');
      }
      break;
    }

    default:
      usage();
  }
}

async function runAsync(cmd, arg1, flags, positional) {
  switch (cmd) {
    case 'gate':
    case 'tick': {
      if (!arg1) usage();
      await require('./lib/execute_plan_tick').cliTick(arg1, flags);
      break;
    }

    case 'init': {
      if (!arg1) usage();
      await require('./lib/execute_plan_init').cliInit(arg1, flags);
      break;
    }

    case 'check-diff':
      await require('./lib/execute_plan_scope_run').cliCheckDiff(flags);
      break;

    case 'watch-ci': {
      if (!arg1) usage();
      await require('./lib/execute_plan_tick').cliWatchCi(arg1, flags);
      break;
    }

    case 'watch-preuat': {
      if (!arg1) usage();
      await require('./lib/execute_plan_tick').cliWatchPreUat(arg1, flags);
      break;
    }

    case 'watch-preuat-sha': {
      if (!arg1) usage();
      await require('./lib/execute_plan_tick').cliWatchPreUatSha(arg1, flags);
      break;
    }

    case 'watch-deploy': {
      if (!arg1) usage();
      await require('./lib/execute_plan_tick').cliWatchDeploy(arg1, flags);
      break;
    }

    case 'complete-plan': {
      if (!arg1) usage();
      if (!isV2Plan(arg1)) {
        throw new ExecutePlanError(
          'complete-plan requires a v2 snapshot (schema_version 2); v1 plans are retired'
        );
      }
      await require('./lib/execute_plan_tick').cliCompletePlan(arg1, flags);
      break;
    }

    default:
      usage();
  }
}

function isV2Plan(planId) {
  try {
    return loadSnapshot(planId).schema_version === 2;
  } catch {
    return false;
  }
}

main();
