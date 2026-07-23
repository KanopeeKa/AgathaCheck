'use strict';

const {
  COORDINATION_ISSUE_NUMBER,
} = require('./uat_queue_constants');
const {
  applyDeployResult,
  enqueueEntry,
} = require('./uat_queue_lib');
const {
  loadStateFromIssue,
  resolveCoordinationIssue,
  saveStateToIssue,
} = require('./uat_queue_sync');

async function syncEnqueueAfterMerge({
  mergeSha,
  prNumber,
  enqueuedBy,
  issueNumber = COORDINATION_ISSUE_NUMBER,
  token,
}) {
  const coordIssue = resolveCoordinationIssue(issueNumber);
  if (!coordIssue) {
    return { skipped: true, reason: 'coordination_issue_not_configured' };
  }

  const { state } = await loadStateFromIssue(coordIssue, token);
  const result = enqueueEntry(state, {
    mergeSha,
    prNumber,
    enqueuedBy: enqueuedBy || `pr-${prNumber}`,
  });
  await saveStateToIssue(coordIssue, result.state, token);
  return { skipped: false, entry: result.entry, created: result.created, issueNumber: coordIssue };
}

async function syncDeployResult({
  deployRef,
  conclusion,
  deployRunId,
  gateSummaryRef,
  issueNumber = COORDINATION_ISSUE_NUMBER,
  token,
}) {
  const coordIssue = resolveCoordinationIssue(issueNumber);
  if (!coordIssue) {
    return { skipped: true, reason: 'coordination_issue_not_configured' };
  }

  const { state } = await loadStateFromIssue(coordIssue, token);
  const result = applyDeployResult(state, {
    deployRef,
    conclusion,
    deployRunId,
    gateSummaryRef,
  });
  if (result.skipped) {
    return { skipped: true, reason: result.reason, issueNumber: coordIssue };
  }
  await saveStateToIssue(coordIssue, result.state, token);
  return {
    skipped: false,
    entry: result.entry,
    issueNumber: coordIssue,
    conclusion,
  };
}

module.exports = {
  syncDeployResult,
  syncEnqueueAfterMerge,
};
