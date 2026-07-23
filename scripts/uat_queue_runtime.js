#!/usr/bin/env node
/**
 * Cross-agent UAT deploy queue runtime.
 *
 *   node scripts/uat_queue_runtime.js enqueue --merge <sha> --pr <n> [--ref context] [--issue N] [--write]
 *   node scripts/uat_queue_runtime.js status [--merge <sha> | --seq <n>]
 *   node scripts/uat_queue_runtime.js barrier-check [--branch <name>]
 *   node scripts/uat_queue_runtime.js acquire-watcher --holder <id> [--lease-minutes 90] [--issue N] [--write]
 *   node scripts/uat_queue_runtime.js release-watcher [--issue N] [--write]
 *   node scripts/uat_queue_runtime.js set-barrier --sha <sha> [--reason text] [--issue N] [--write]
 *   node scripts/uat_queue_runtime.js reconcile [--issue N] [--write]
 *   node scripts/uat_queue_runtime.js render-state [--issue N]
 *
 * Exit codes: 0 ok; 2 expected wait (watcher held); 1 error.
 */

'use strict';

const { execFileSync } = require('child_process');
const path = require('path');
const {
  COORDINATION_ISSUE_NUMBER,
  DEFAULT_WATCHER_LEASE_MINUTES,
} = require('./lib/uat_queue_constants');
const {
  UatQueueError,
  acquireWatcher,
  barrierCheck,
  enqueueEntry,
  findEntryByMergeSha,
  headEntryNeedingAttention,
  isWatcherLeaseActive,
  releaseWatcher,
  setBarrier,
} = require('./lib/uat_queue_lib');
const {
  loadStateFromIssue,
  resolveCoordinationIssue,
  saveStateToIssue,
} = require('./lib/uat_queue_sync');

const REPO_ROOT = path.resolve(__dirname, '..');

function usage() {
  console.error(`Usage: node scripts/uat_queue_runtime.js <command> [options]

Commands:
  enqueue --merge <sha> --pr <n> [--ref context] [--issue N] [--write]
  status [--merge <sha> | --seq <n>] [--issue N]
  barrier-check [--branch <name>] [--issue N]
  acquire-watcher --holder <id> [--lease-minutes N] [--issue N] [--write]
  release-watcher [--issue N] [--write]
  set-barrier --sha <sha> [--reason text] [--issue N] [--write]
  reconcile [--issue N] [--write]
  render-state [--issue N]

Default coordination issue: UAT_COORDINATION_ISSUE env or ${COORDINATION_ISSUE_NUMBER} (0 = unset; pass --issue).
`);
  process.exit(1);
}

function fail(msg, code = 1) {
  console.error(`uat_queue_runtime: ${msg}`);
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

function requireStringFlag(flags, name) {
  const value = flags[name];
  if (typeof value !== 'string' || !value.trim()) {
    throw new UatQueueError(`--${name} requires a value`);
  }
  return value.trim();
}

function requirePositiveIntFlag(flags, name) {
  const raw = requireStringFlag(flags, name);
  const value = Number(raw);
  if (!Number.isInteger(value) || value < 1) {
    throw new UatQueueError(`--${name} must be a positive integer`);
  }
  return value;
}

function optionalStringFlag(flags, name) {
  if (flags[name] === undefined) {
    return null;
  }
  return requireStringFlag(flags, name);
}

function optionalPositiveIntFlag(flags, name, defaultValue) {
  if (flags[name] === undefined) {
    return defaultValue;
  }
  if (flags[name] === true) {
    throw new UatQueueError(`--${name} requires a value`);
  }
  const value = Number(flags[name]);
  if (!Number.isInteger(value) || value < 1) {
    throw new UatQueueError(`--${name} must be a positive integer`);
  }
  return value;
}

function printJson(obj) {
  console.log(JSON.stringify(obj, null, 2));
}

function gitRevParse(ref) {
  return execFileSync('git', ['rev-parse', ref], { cwd: REPO_ROOT, encoding: 'utf8' }).trim();
}

function gitIsAncestor(ancestor, descendant) {
  try {
    execFileSync('git', ['merge-base', '--is-ancestor', ancestor, descendant], {
      cwd: REPO_ROOT,
      stdio: 'ignore',
    });
    return true;
  } catch {
    return false;
  }
}

function resolveBranchTip(branchName) {
  const branch = branchName || gitRevParse('--abbrev-ref HEAD');
  if (branch === 'HEAD') {
    return gitRevParse('HEAD');
  }
  try {
    execFileSync('git', ['fetch', 'origin', 'main', '--quiet'], {
      cwd: REPO_ROOT,
      stdio: 'ignore',
    });
  } catch {
    // offline / no remote
  }
  return gitRevParse(branch);
}

async function loadIssueState(flags) {
  const issueNumber = resolveCoordinationIssue(flags.issue);
  if (!issueNumber) {
    throw new UatQueueError(
      'coordination issue not configured — set UAT_COORDINATION_ISSUE or pass --issue'
    );
  }
  return loadStateFromIssue(issueNumber);
}

async function maybeSave(flags, issueNumber, state) {
  if (!flags.write) {
    return { saved: false };
  }
  const result = await saveStateToIssue(issueNumber, state);
  return { saved: true, ...result };
}

async function runCommand(cmd, flags) {
  switch (cmd) {
    case 'enqueue': {
      const { state, issueNumber } = await loadIssueState(flags);
      const result = enqueueEntry(state, {
        mergeSha: requireStringFlag(flags, 'merge'),
        prNumber: requirePositiveIntFlag(flags, 'pr'),
        enqueuedBy: optionalStringFlag(flags, 'ref'),
        uatTag: optionalStringFlag(flags, 'tag'),
      });
      const saveMeta = await maybeSave(flags, issueNumber, result.state);
      printJson({ command: 'enqueue', entry: result.entry, created: result.created, ...saveMeta });
      return;
    }

    case 'status': {
      const { state } = await loadIssueState(flags);
      let entry = null;
      if (flags.merge) {
        entry = findEntryByMergeSha(state, flags.merge);
      } else if (flags.seq) {
        entry = state.entries.find((e) => e.seq === Number(flags.seq)) || null;
      } else {
        entry = headEntryNeedingAttention(state);
      }
      printJson({
        command: 'status',
        main_barrier_sha: state.main_barrier_sha,
        active_watcher: state.active_watcher,
        watcher_lease_active: isWatcherLeaseActive(state),
        entry,
        entries: state.entries,
      });
      return;
    }

    case 'barrier-check': {
      const issueNumber = resolveCoordinationIssue(flags.issue);
      let barrierSha = flags.barrier || null;
      if (!barrierSha && issueNumber) {
        const loaded = await loadStateFromIssue(issueNumber);
        barrierSha = loaded.state.main_barrier_sha;
      }
      const branchTipSha = resolveBranchTip(flags.branch);
      const result = barrierCheck({
        barrierSha,
        branchTipSha,
        isAncestor: gitIsAncestor,
      });
      printJson({ command: 'barrier-check', ...result });
      if (result.needs_rebase) {
        process.exit(2);
      }
      return;
    }

    case 'acquire-watcher': {
      const { state, issueNumber } = await loadIssueState(flags);
      const head = headEntryNeedingAttention(state);
      const result = acquireWatcher(state, {
        holder: requireStringFlag(flags, 'holder'),
        leaseMinutes: optionalPositiveIntFlag(
          flags,
          'lease-minutes',
          DEFAULT_WATCHER_LEASE_MINUTES
        ),
        watchingSeq: head?.seq,
      });
      if (!result.acquired) {
        printJson({ command: 'acquire-watcher', acquired: false, ...result });
        process.exit(2);
      }
      const saveMeta = await maybeSave(flags, issueNumber, result.state);
      printJson({ command: 'acquire-watcher', acquired: true, watcher: result.watcher, ...saveMeta });
      return;
    }

    case 'release-watcher': {
      const { state, issueNumber } = await loadIssueState(flags);
      releaseWatcher(state);
      const saveMeta = await maybeSave(flags, issueNumber, state);
      printJson({ command: 'release-watcher', ...saveMeta });
      return;
    }

    case 'set-barrier': {
      const { state, issueNumber } = await loadIssueState(flags);
      setBarrier(state, {
        sha: requireStringFlag(flags, 'sha'),
        reason: optionalStringFlag(flags, 'reason'),
      });
      const saveMeta = await maybeSave(flags, issueNumber, state);
      printJson({
        command: 'set-barrier',
        main_barrier_sha: state.main_barrier_sha,
        ...saveMeta,
      });
      return;
    }

    case 'reconcile': {
      const { state, issueNumber } = await loadIssueState(flags);
      // Phase 1: load + normalize only; Actions notify updates deploy results.
      const saveMeta = await maybeSave(flags, issueNumber, state);
      printJson({
        command: 'reconcile',
        entries: state.entries.length,
        head: headEntryNeedingAttention(state),
        watcher_lease_active: isWatcherLeaseActive(state),
        ...saveMeta,
      });
      return;
    }

    case 'render-state': {
      const { state } = await loadIssueState(flags);
      printJson(state);
      return;
    }

    default:
      usage();
  }
}

async function main() {
  const { positional, flags } = parseArgs(process.argv.slice(2));
  const cmd = positional[0];
  if (!cmd) usage();

  try {
    await runCommand(cmd, flags);
  } catch (e) {
    if (e instanceof UatQueueError) {
      fail(e.message);
    }
    fail(e.message);
  }
}

main();
