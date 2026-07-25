'use strict';

const {
  COORDINATION_ISSUE_NUMBER,
} = require('./uat_queue_constants');
const {
  applyDeployResult,
  enqueueEntry,
  findActiveEntryByPr,
  parseUatTag,
} = require('./uat_queue_lib');
const {
  loadStateFromIssue,
  resolveCoordinationIssue,
  saveStateToIssue,
} = require('./uat_queue_sync');

/**
 * Ensure a ledger entry exists for a UAT tag / PR before deploy sync.
 * Used when merge-handler skipped enqueue (no linked issue) or ledger drifted.
 */
async function ensureQueueEntryForDeployRef({
  deployRef,
  mergeSha,
  owner,
  repo,
  issueNumber = COORDINATION_ISSUE_NUMBER,
  token,
  enqueuedBy,
  write = true,
}) {
  const parsed = parseUatTag(deployRef);
  if (!parsed) {
    return { skipped: true, reason: 'invalid_deploy_ref' };
  }

  const coordIssue = resolveCoordinationIssue(issueNumber);
  if (!coordIssue) {
    return { skipped: true, reason: 'coordination_issue_not_configured' };
  }

  const { state } = await loadStateFromIssue(coordIssue, token);
  const existing = findActiveEntryByPr(state, parsed.prNumber);
  if (existing) {
    return {
      skipped: false,
      entry: existing,
      created: false,
      issueNumber: coordIssue,
      state,
    };
  }

  let sha = mergeSha || null;
  if (!sha && owner && repo && token) {
    try {
      const { tagCommitSha } = require('./uat_deploy_run_resolve');
      sha = await tagCommitSha(owner, repo, deployRef, token);
    } catch {
      sha = null;
    }
  }
  if (!sha) {
    return { skipped: true, reason: 'merge_sha_unavailable', issueNumber: coordIssue };
  }

  const result = enqueueEntry(state, {
    mergeSha: sha,
    prNumber: parsed.prNumber,
    enqueuedBy: enqueuedBy || `pr-${parsed.prNumber}`,
    uatTag: deployRef,
  });

  if (write) {
    await saveStateToIssue(coordIssue, result.state, token);
  }

  return {
    skipped: false,
    entry: result.entry,
    created: result.created,
    issueNumber: coordIssue,
    state: result.state,
  };
}

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
  gateFailureClass,
  issueNumber = COORDINATION_ISSUE_NUMBER,
  token,
  write = true,
  owner = null,
  repo = null,
  mergeSha = null,
}) {
  const coordIssue = resolveCoordinationIssue(issueNumber);
  if (!coordIssue) {
    return { skipped: true, reason: 'coordination_issue_not_configured' };
  }

  let state = (await loadStateFromIssue(coordIssue, token)).state;
  const parsed = parseUatTag(deployRef);
  if (parsed && !findActiveEntryByPr(state, parsed.prNumber)) {
    const ensured = await ensureQueueEntryForDeployRef({
      deployRef,
      mergeSha,
      owner,
      repo,
      issueNumber: coordIssue,
      token,
      enqueuedBy: `pr-${parsed.prNumber}`,
      write: false,
    });
    if (!ensured.skipped && ensured.state) {
      state = ensured.state;
    }
  }

  const result = applyDeployResult(state, {
    deployRef,
    conclusion,
    deployRunId,
    gateSummaryRef,
    gateFailureClass,
  });
  if (result.skipped) {
    return { skipped: true, reason: result.reason, issueNumber: coordIssue };
  }
  if (write) {
    await saveStateToIssue(coordIssue, result.state, token);
  }
  return {
    skipped: false,
    entry: result.entry,
    issueNumber: coordIssue,
    conclusion,
    state: result.state,
    backfilled: Boolean(parsed && mergeSha),
  };
}

module.exports = {
  ensureQueueEntryForDeployRef,
  syncDeployResult,
  syncEnqueueAfterMerge,
};
