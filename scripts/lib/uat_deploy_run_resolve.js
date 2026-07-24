'use strict';

const { rest } = require('../../.github/scripts/github-project-lib');
const { syncDeployResult } = require('./uat_queue_apply');
const { resolveCoordinationIssue } = require('./uat_queue_sync');

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

  const result = await syncDeployResult({
    deployRef,
    conclusion: 'failure',
    deployRunId: String(workflowRunId),
    gateSummaryRef: workflowUrl,
    gateFailureClass,
    issueNumber: coordIssue,
    token,
    write,
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
  resolveUatTagForCommit,
  extractDeployRefFromWorkflowRun,
  reconcileFailedDeployLedger,
};
