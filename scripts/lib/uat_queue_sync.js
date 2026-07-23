'use strict';

const {
  fetchIssue,
  rest,
  upsertMarkerComment,
} = require('../../.github/scripts/github-project-lib');
const { resolveRepository } = require('./execute_plan_project');
const {
  COORDINATION_ISSUE_NUMBER,
  STATE_MARKER,
} = require('./uat_queue_constants');
const {
  createEmptyState,
  parseStateFromCommentBody,
  renderStateCommentBody,
} = require('./uat_queue_lib');

function resolveCoordinationIssue(issueOverride) {
  const issueNumber = Number(issueOverride || COORDINATION_ISSUE_NUMBER);
  if (!Number.isInteger(issueNumber) || issueNumber < 1) {
    return null;
  }
  return issueNumber;
}

function getGithubToken() {
  return process.env.GITHUB_TOKEN || process.env.GH_TOKEN || null;
}

async function loadStateFromIssue(issueNumber, token) {
  const { owner, repo } = resolveRepository();
  const authToken = token || getGithubToken();
  if (!authToken) {
    throw new Error('GITHUB_TOKEN or gh auth required to load uat queue state');
  }

  const comments = await rest(
    'GET',
    `/repos/${owner}/${repo}/issues/${issueNumber}/comments?per_page=100`,
    authToken
  );

  const markerComment = [...comments]
    .reverse()
    .find((comment) => comment.body?.includes(STATE_MARKER));

  if (!markerComment) {
    return { state: createEmptyState(), issueNumber, commentId: null };
  }

  return {
    state: parseStateFromCommentBody(markerComment.body),
    issueNumber,
    commentId: markerComment.id,
  };
}

async function saveStateToIssue(issueNumber, state, token) {
  const { owner, repo } = resolveRepository();
  const authToken = token || getGithubToken();
  if (!authToken) {
    throw new Error('GITHUB_TOKEN or gh auth required to save uat queue state');
  }

  const body = renderStateCommentBody(state);
  const commentId = await upsertMarkerComment({
    owner,
    repo,
    issueNumber,
    marker: STATE_MARKER,
    body,
    token: authToken,
  });

  return { issueNumber, commentId, updated_at: state.updated_at };
}

async function ensureCoordinationIssueExists(issueNumber, token) {
  const { owner, repo } = resolveRepository();
  const authToken = token || getGithubToken();
  await fetchIssue(owner, repo, issueNumber, authToken);
}

module.exports = {
  ensureCoordinationIssueExists,
  loadStateFromIssue,
  resolveCoordinationIssue,
  saveStateToIssue,
};
