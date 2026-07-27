#!/usr/bin/env node
'use strict';

const { execFileSync } = require('child_process');
const path = require('path');
const { rest, parseRepo } = require('./github-project-lib');
const {
  buildUatCoordinatorPayload,
  classifyFailedJobs,
  isInfraOnlyFailure,
} = require('../../scripts/lib/uat_coordinator_payload');
const {
  acquireWatcher,
  findEntryByMergeSha,
  headEntryNeedingAttention,
  isWatcherLeaseActive,
  markEntryRemedial,
  parseUatTag,
  pruneExpiredWatcher,
  releaseWatcher,
  setPromoteHold,
} = require('../../scripts/lib/uat_queue_lib');
const { reconcileFailedDeployLedger, reconcileFailedPreUatLedger } = require('../../scripts/lib/uat_deploy_run_resolve');
const {
  loadStateFromIssue,
  resolveCoordinationIssue,
  saveStateToIssue,
} = require('../../scripts/lib/uat_queue_sync');

const REPO_ROOT = path.resolve(__dirname, '../..');

async function fetchWorkflowJobs(owner, repo, runId, token) {
  const data = await rest(
    'GET',
    `/repos/${owner}/${repo}/actions/runs/${runId}/jobs?per_page=100`,
    token,
  );
  return data.jobs || [];
}

async function fetchWorkflowRun(owner, repo, runId, token) {
  return rest('GET', `/repos/${owner}/${repo}/actions/runs/${runId}`, token);
}

/**
 * A watcher lease is tied to the failed deploy run id (`gha-<runId>`). If that
 * run has already finished but launch-uat-coordinator failed after the lease was
 * acquired, the lease blocks every later dispatch until expiry (90 min).
 */
async function releaseWatcherIfHolderRunFinished(state, owner, repo, token) {
  pruneExpiredWatcher(state);
  const holder = state.active_watcher?.holder;
  if (!holder || !isWatcherLeaseActive(state)) {
    return state;
  }
  const match = holder.match(/^gha-(\d+)$/);
  if (!match) {
    return state;
  }
  try {
    const run = await rest('GET', `/repos/${owner}/${repo}/actions/runs/${match[1]}`, token);
    if (run.status === 'completed') {
      releaseWatcher(state);
    }
  } catch {
    // Keep the lease when the holder run cannot be verified.
  }
  return state;
}

function printJson(obj) {
  console.log(JSON.stringify(obj, null, 2));
}

async function prepareDispatch({
  coordinationIssue,
  workflowRunId,
  workflowUrl,
  holder,
  token,
  owner,
  repo,
  force = false,
  mergeSha = null,
  failedEntry = null,
  failedGates = null,
  skipPromoteHold = false,
}) {
  const { state, issueNumber } = await loadStateFromIssue(coordinationIssue, token);
  await releaseWatcherIfHolderRunFinished(state, owner, repo, token);
  let head = failedEntry || headEntryNeedingAttention(state);

  if (!head || !['failed', 'remedial'].includes(head.state)) {
    if (force && mergeSha) {
      const bySha = findEntryByMergeSha(state, mergeSha);
      if (bySha && ['failed', 'remedial'].includes(bySha.state)) {
        head = bySha;
      }
    }
    if (!head || !['failed', 'remedial'].includes(head.state)) {
      return {
        skipped: true,
        reason: 'no_failed_head_entry',
        head: head || null,
      };
    }
  }

  if (!force && head.state === 'remedial' && isWatcherLeaseActive(state)) {
    return {
      skipped: true,
      reason: 'remedial_in_progress',
      holder: state.active_watcher?.holder || null,
    };
  }

  if (force && isWatcherLeaseActive(state)) {
    releaseWatcher(state);
  }

  let watcherResult = acquireWatcher(state, {
    holder,
    leaseMinutes: 90,
    watchingSeq: head.seq,
  });
  if (!watcherResult.acquired) {
    if (!force) {
      return {
        skipped: true,
        reason: 'watcher_lease_held',
        holder: watcherResult.holder,
      };
    }
    releaseWatcher(state);
    watcherResult = acquireWatcher(state, {
      holder,
      leaseMinutes: 90,
      watchingSeq: head.seq,
    });
    if (!watcherResult.acquired) {
      return {
        skipped: true,
        reason: 'watcher_lease_held',
        holder: watcherResult.holder,
      };
    }
  }

  let nextState = watcherResult.state;
  if (head.state === 'failed') {
    const remedial = markEntryRemedial(nextState, { mergeSha: head.merge_sha });
    nextState = remedial.state;
  }
  const entry = findEntryByMergeSha(nextState, head.merge_sha) || head;
  if (!skipPromoteHold) {
    setPromoteHold(nextState, {
      reason: `deploy-uat failure run ${workflowRunId}`,
    });
  }

  const resolvedFailedGates =
    failedGates || classifyFailedJobs(await fetchWorkflowJobs(owner, repo, workflowRunId, token));
  const payload = buildUatCoordinatorPayload({
    coordinationIssueNumber: issueNumber,
    coordinationIssueUrl: `https://github.com/${owner}/${repo}/issues/${issueNumber}`,
    entry,
    failedGates: resolvedFailedGates,
    workflowRunId,
    workflowUrl,
    repository: `https://github.com/${owner}/${repo}`,
  });

  return {
    skipped: false,
    issueNumber,
    entry,
    payload,
    failed_gates: resolvedFailedGates,
    nextState,
  };
}

async function main() {
  const repository = process.env.GITHUB_REPOSITORY;
  const token = process.env.GITHUB_TOKEN;
  const workflowRunId = process.env.WORKFLOW_RUN_ID;
  const workflowUrl = process.env.WORKFLOW_URL;
  const dryRun = process.env.DRY_RUN === 'true';
  const writeLedger = process.env.WRITE_LEDGER !== 'false' && !dryRun;
  const forceDispatch = process.env.FORCE_DISPATCH === 'true';

  if (!repository || !token || !workflowRunId) {
    throw new Error('GITHUB_REPOSITORY, GITHUB_TOKEN, and WORKFLOW_RUN_ID are required');
  }

  const coordinationIssue = resolveCoordinationIssue(process.env.UAT_COORDINATION_ISSUE);
  if (!coordinationIssue) {
    printJson({
      skipped: true,
      reason: 'coordination_issue_not_configured',
    });
    return;
  }

  const apiKey = process.env.cursor_api_key || process.env.CURSOR_API_KEY;
  if (!dryRun && !apiKey) {
    printJson({
      skipped: true,
      reason: 'cursor_api_key_not_configured',
    });
    return;
  }

  const { owner, repo } = parseRepo(repository);
  const run = await fetchWorkflowRun(owner, repo, workflowRunId, token);
  if (run.conclusion !== 'failure' && process.env.FORCE_DISPATCH !== 'true') {
    printJson({
      skipped: true,
      reason: 'workflow_not_failed',
      conclusion: run.conclusion,
    });
    return;
  }

  const resolvedUrl =
    workflowUrl
    || run.html_url
    || `https://github.com/${owner}/${repo}/actions/runs/${workflowRunId}`;

  // Classify once up front so an infra-only failure (WAF/deploy transport, no
  // evidence of a code regression) is recorded as `infra_failed` rather than
  // `failed` — this keeps queueHeadHold from freezing promotion for unrelated
  // merges. See scripts/lib/uat_coordinator_payload.js isInfraOnlyFailure.
  // This branch only runs for a `conclusion === 'failure'` run (checked
  // above), so there is no legitimate 'none' case here — zero non-aggregate
  // failed jobs (e.g. a ghost/cancelled run) is unclassifiable, not evidence
  // of "no failure", and must default to the conservative 'code' (blocking).
  const jobs = await fetchWorkflowJobs(owner, repo, workflowRunId, token);
  const failedGates = classifyFailedJobs(jobs);
  const gateFailureClass = isInfraOnlyFailure(failedGates) ? 'infra_only' : 'code';

  const isPreUatRun = /^pre-uat e2e$/i.test(String(run.name || '').trim());

  const ledgerSync = isPreUatRun
    ? await reconcileFailedPreUatLedger({
        owner,
        repo,
        workflowRunId,
        workflowUrl: resolvedUrl,
        coordinationIssue,
        token,
        write: writeLedger,
        failedGates,
      })
    : await reconcileFailedDeployLedger({
        owner,
        repo,
        workflowRunId,
        workflowUrl: resolvedUrl,
        coordinationIssue,
        token,
        write: writeLedger,
        gateFailureClass,
      });

  let failedEntry = null;
  if (writeLedger) {
    if (!ledgerSync.skipped && ledgerSync.entry?.state === 'failed') {
      failedEntry = ledgerSync.entry;
    } else if (ledgerSync.deployRef) {
      const parsed = parseUatTag(ledgerSync.deployRef);
      if (parsed) {
        const { state } = await loadStateFromIssue(coordinationIssue, token);
        failedEntry =
          state.entries.find(
            (entry) => entry.pr_number === parsed.prNumber && entry.state === 'failed',
          ) || null;
      }
    }
  }

  if (!failedEntry && ledgerSync.entry?.state === 'infra_failed') {
    printJson({
      skipped: true,
      reason: 'infra_only_failure_no_hold',
      gate_failure_class: gateFailureClass,
      failed_gates: failedGates,
      ledger_sync: ledgerSync,
    });
    return;
  }

  const prepared = await prepareDispatch({
    coordinationIssue,
    workflowRunId,
    workflowUrl: resolvedUrl,
    holder: `gha-${workflowRunId}`,
    token,
    owner,
    repo,
    force: forceDispatch,
    mergeSha: run.head_sha || null,
    failedEntry,
    failedGates,
    skipPromoteHold: isPreUatRun,
  });

  if (prepared.skipped) {
    printJson({ ...prepared, ledger_sync: ledgerSync });
    return;
  }

  if (dryRun) {
    printJson({ dry_run: true, ...prepared });
    return;
  }

  try {
    execFileSync(
      'node',
      ['.github/scripts/launch-uat-coordinator.js'],
      {
        cwd: REPO_ROOT,
        stdio: 'inherit',
        env: {
          ...process.env,
          UAT_COORDINATION_ISSUE: String(prepared.issueNumber),
          UAT_COORDINATOR_PAYLOAD: JSON.stringify(prepared.payload),
        },
      },
    );
  } catch (error) {
    printJson({
      dispatched: false,
      launch_error: error.message,
      ledger_sync: ledgerSync,
    });
    throw error;
  }

  if (writeLedger && prepared.nextState) {
    await saveStateToIssue(prepared.issueNumber, prepared.nextState, token);
  }

  printJson({
    dispatched: true,
    issue_number: prepared.issueNumber,
    pr_number: prepared.entry.pr_number,
    workflow_run_id: workflowRunId,
  });
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}

module.exports = {
  prepareDispatch,
  fetchWorkflowJobs,
};
