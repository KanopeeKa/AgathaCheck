'use strict';

const { rest } = require('../../.github/scripts/github-project-lib');
const { syncDeployResult } = require('./uat_queue_apply');
const { resolveCoordinationIssue } = require('./uat_queue_sync');

/**
 * Read deploy_ref from a deploy-uat workflow run's resolve-trigger job outputs.
 */
async function extractDeployRefFromWorkflowRun(owner, repo, runId, token) {
  const data = await rest(
    'GET',
    `/repos/${owner}/${repo}/actions/runs/${runId}/jobs?per_page=100`,
    token,
  );
  const jobs = data.jobs || [];
  const resolveJob = jobs.find((job) => job.name === 'Resolve deploy trigger');
  const deployRef = resolveJob?.outputs?.deploy_ref;
  if (deployRef && deployRef !== 'n/a') {
    return deployRef;
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
  extractDeployRefFromWorkflowRun,
  reconcileFailedDeployLedger,
};
