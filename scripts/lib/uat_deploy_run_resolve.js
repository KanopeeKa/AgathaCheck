'use strict';

const { rest } = require('../../.github/scripts/github-project-lib');
const {
  enqueueEntry,
  findActiveEntryByPr,
  findEntryByMergeSha,
} = require('./uat_queue_lib');
const { loadStateFromIssue, resolveCoordinationIssue, saveStateToIssue } =
  require('./uat_queue_sync');

function yymmddFromIso(iso) {
  if (!iso || iso.length < 10) {
    return null;
  }
  return iso.slice(2, 4) + iso.slice(5, 7) + iso.slice(8, 10);
}

async function tagCommitSha(owner, repo, tagName, token) {
  const ref = await rest('GET', `/repos/${owner}/${repo}/git/ref/tags/${tagName}`, token);
  let obj = ref.object;
  if (obj.type === 'tag') {
    const tagObj = await rest('GET', `/repos/${owner}/${repo}/git/tags/${obj.sha}`, token);
    obj = tagObj.object;
  }
  return obj.sha;
}

async function resolvePrForCommit(owner, repo, commitSha, token) {
  const pulls = await rest('GET', `/repos/${owner}/${repo}/commits/${commitSha}/pulls`, token);
  if (!Array.isArray(pulls) || pulls.length !== 1) {
    return null;
  }
  return pulls[0].number;
}

/**
 * Derive uat-* tag for a promoted commit (same fast path as resolve-uat-deploy-trigger.sh).
 */
async function resolveUatTagForCommit(owner, repo, commitSha, yymmdd, token) {
  const prNumber = await resolvePrForCommit(owner, repo, commitSha, token);
  if (!prNumber || !yymmdd) {
    return null;
  }
  const tag = `uat-${yymmdd}-${prNumber}`;
  try {
    const tagSha = await tagCommitSha(owner, repo, tag, token);
    if (tagSha === commitSha) {
      return tag;
    }
  } catch {
    return null;
  }
  return null;
}

/**
 * Resolve deploy_ref for a deploy-uat workflow run.
 */
async function extractDeployRefFromWorkflowRun(owner, repo, runId, token) {
  const run = await rest('GET', `/repos/${owner}/${repo}/actions/runs/${runId}`, token);
  const commitSha = run.head_sha;
  if (!commitSha) {
    return null;
  }

  if (run.head_branch && /^uat-\d{6}-\d+$/.test(run.head_branch)) {
    return run.head_branch;
  }

  const yymmdd = yymmddFromIso(run.created_at || run.run_started_at);
  const fastTag = await resolveUatTagForCommit(owner, repo, commitSha, yymmdd, token);
  if (fastTag) {
    return fastTag;
  }

  return null;
}

/**
 * True when Pre-UAT failed only because main advanced during the run (queue
 * bundling). Do not dispatch a remedial agent — the next queued run covers HEAD.
 */
function isPreUatBundlingOnlyFailure(failedGates) {
  if (!failedGates || failedGates.length === 0) {
    return true;
  }
  const hasCodeFailure = failedGates.some((row) =>
    ['localhost_e2e', 'flutter_build', 'migrations', 'unknown'].includes(row.gate),
  );
  if (hasCodeFailure) {
    return false;
  }
  return failedGates.every((row) => row.gate === 'pre_uat_e2e');
}

/**
 * Mark the merge commit's queue entry failed after a Pre-UAT E2E code failure.
 * Pre-UAT runs before any uat-* tag exists, so deploy_ref reconciliation cannot apply.
 */
async function reconcileFailedPreUatLedger({
  owner,
  repo,
  workflowRunId,
  workflowUrl,
  coordinationIssue,
  token,
  write = true,
  failedGates = null,
}) {
  if (isPreUatBundlingOnlyFailure(failedGates)) {
    return { skipped: true, reason: 'pre_uat_bundling_only' };
  }

  const coordIssue = resolveCoordinationIssue(coordinationIssue);
  if (!coordIssue) {
    return { skipped: true, reason: 'coordination_issue_not_configured' };
  }

  const run = await rest('GET', `/repos/${owner}/${repo}/actions/runs/${workflowRunId}`, token);
  const mergeSha = run.head_sha || null;
  if (!mergeSha) {
    return { skipped: true, reason: 'merge_sha_unavailable' };
  }

  const prNumber = await resolvePrForCommit(owner, repo, mergeSha, token);
  if (!prNumber) {
    return { skipped: true, reason: 'pr_unresolved', mergeSha };
  }

  let { state: workingState } = await loadStateFromIssue(coordIssue, token);
  let entry =
    findEntryByMergeSha(workingState, mergeSha) || findActiveEntryByPr(workingState, prNumber);

  if (!entry) {
    const enqueued = enqueueEntry(workingState, {
      mergeSha,
      prNumber,
      enqueuedBy: `pre-uat-run-${workflowRunId}`,
    });
    workingState = enqueued.state;
    entry = enqueued.entry;
  } else if (['complete', 'superseded'].includes(entry.state)) {
    return {
      skipped: true,
      reason: 'entry_already_terminal',
      entry,
      mergeSha,
      prNumber,
    };
  }

  entry.state = 'failed';
  entry.result = 'failure';
  entry.gate_summary_ref = workflowUrl;
  entry.deploy_run_id = String(workflowRunId);
  entry.completed_at = new Date().toISOString();

  if (write) {
    await saveStateToIssue(coordIssue, workingState, token);
  }

  return {
    skipped: false,
    entry,
    mergeSha,
    prNumber,
    issueNumber: coordIssue,
    dryRun: !write,
  };
}

/**
 * Apply a failed deploy result to the queue ledger when notify/sync was skipped.
 */
async function reconcileFailedDeployLedger({
  owner,
  repo,
  workflowRunId,
  workflowUrl,
  coordinationIssue,
  token,
  write = true,
  gateFailureClass = null,
}) {
  const coordIssue = resolveCoordinationIssue(coordinationIssue);
  if (!coordIssue) {
    return { skipped: true, reason: 'coordination_issue_not_configured' };
  }

  const deployRef = await extractDeployRefFromWorkflowRun(owner, repo, workflowRunId, token);
  if (!deployRef) {
    return { skipped: true, reason: 'deploy_ref_unavailable' };
  }

  const run = await rest('GET', `/repos/${owner}/${repo}/actions/runs/${workflowRunId}`, token);

  const { syncDeployResult } = require('./uat_queue_apply');
  const result = await syncDeployResult({
    deployRef,
    conclusion: 'failure',
    deployRunId: String(workflowRunId),
    gateSummaryRef: workflowUrl,
    gateFailureClass,
    issueNumber: coordIssue,
    token,
    write,
    owner,
    repo,
    mergeSha: run.head_sha || null,
  });

  if (result.skipped) {
    return { skipped: true, reason: result.reason, deployRef };
  }

  if (!write) {
    return { skipped: false, deployRef, entry: result.entry, dryRun: true };
  }

  return { skipped: false, deployRef, entry: result.entry, issueNumber: coordIssue };
}

module.exports = {
  yymmddFromIso,
  tagCommitSha,
  resolveUatTagForCommit,
  extractDeployRefFromWorkflowRun,
  isPreUatBundlingOnlyFailure,
  reconcileFailedPreUatLedger,
  reconcileFailedDeployLedger,
};
