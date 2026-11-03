'use strict';

const { formatAck } = require('../../lib/execute_plan_ack');

const VALID_ACK_RUN = Object.freeze({
  path: '.github/workflows/execute-plan-approve.yml',
  head_branch: 'main',
  event: 'issue_comment',
});

const DEFAULT_ACK_RUN_ID = 88888;

function ackComment(commentId, runId = DEFAULT_ACK_RUN_ID) {
  return {
    id: 50_000 + commentId,
    user: { login: 'github-actions[bot]' },
    created_at: '2026-10-16T09:06:00Z',
    updated_at: '2026-10-16T09:06:00Z',
    body: formatAck(commentId, runId),
  };
}

/** Fake-fetch route for `getWorkflowRun` used by acknowledgement verification. */
function workflowRunRoute(repo, runId = DEFAULT_ACK_RUN_ID, run = VALID_ACK_RUN) {
  const prefix = repo.includes('/') ? `/repos/${repo}` : repo;
  return { [`GET ${prefix}/actions/runs/${runId}`]: { body: run } };
}

function acceptedIds(...ids) {
  return new Set(ids);
}

function acceptedForComments(comments) {
  return new Set((comments || []).map((c) => c.id));
}

module.exports = {
  VALID_ACK_RUN,
  DEFAULT_ACK_RUN_ID,
  ackComment,
  workflowRunRoute,
  acceptedIds,
  acceptedForComments,
};
