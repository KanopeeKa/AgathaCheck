#!/usr/bin/env node
'use strict';

const { execFileSync } = require('child_process');
const path = require('path');
const { rest, parseRepo } = require('./github-project-lib');
const {
  buildUatCoordinatorPayload,
  classifyFailedJobs,
} = require('../../scripts/lib/uat_coordinator_payload');
const {
  acquireWatcher,
  findEntryByMergeSha,
  headEntryNeedingAttention,
  isWatcherLeaseActive,
  markEntryRemedial,
  parseUatTag,
  releaseWatcher,
  setPromoteHold,
} = require('../../scripts/lib/uat_queue_lib');
const { reconcileFailedDeployLedger } = require('../../scripts/lib/uat_deploy_run_resolve');
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
  write = true,
  force = false,
  mergeSha = null,
  failedEntry = null,
}) {
  const { state, issueNumber } = await loadStateFromIssue(coordinationIssue, token);
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
  setPromoteHold(nextState, {
    reason: `deploy-uat failure run ${workflowRunId}`,
  });

  if (write) {
    await saveStateToIssue(issueNumber, nextState, token);
  }

  const jobs = await fetchWorkflowJobs(owner, repo, workflowRunId, token);
  const failedGates = classifyFailedJobs(jobs);
  const payload = buildUatCoordinatorPayload({
    coordinationIssueNumber: issueNumber,
    coordinationIssueUrl: `https://github.com/${owner}/${repo}/issues/${issueNumber}`,
    entry,
    failedGates,
    workflowRunId,
    workflowUrl,
    repository: `https://github.com/${owner}/${repo}`,
  });

  return {
    skipped: false,
    issueNumber,
    entry,
    payload,
    failed_gates: failedGates,
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

  const ledgerSync = await reconcileFailedDeployLedger({
    owner,
    repo,
    workflowRunId,
    workflowUrl: resolvedUrl,
    coordinationIssue,
    token,
    write: writeLedger,
  });

  let failedEntry = null;
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

  const prepared = await prepareDispatch({
    coordinationIssue,
    workflowRunId,
    workflowUrl: resolvedUrl,
    holder: `gha-${workflowRunId}`,
    token,
    owner,
    repo,
    write: writeLedger,
    force: forceDispatch,
    mergeSha: run.head_sha || null,
    failedEntry,
  });

  if (prepared.skipped) {
    printJson({ ...prepared, ledger_sync: ledgerSync });
    return;
  }

  if (dryRun) {
    printJson({ dry_run: true, ...prepared });
    return;
  }

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
