'use strict';

/**
 * Execute-plan v2 authorization acknowledgements (WP12).
 * Spec: docs/agent-efficiency/plans/execute-plan-v2/work-packages-hardening.md §WP12.
 */

const ACK_RE = /^execute-plan: authorization accepted — comment (\d+) — run (\d+)$/;

const formatAck = (commentId, runId) => `execute-plan: authorization accepted — comment ${commentId} — run ${runId}`;

const formatIgnoredNote = (verb, commentId, agentId, now) =>
  `execute-plan: ${verb}-autonomous comment ${commentId} not accepted — worker ${agentId} was still running at ${now}. Post it again once the worker has finished.`;

const formatStoppedNote = (verb, commentId, agentId) =>
  `execute-plan: ${verb}-autonomous comment ${commentId} not accepted — posted while worker ${agentId} was running; plan stopped (needs-owner).`;

const formatKeyUnavailableNote = (verb, commentId) =>
  `execute-plan: ${verb}-autonomous comment ${commentId} not accepted — CURSOR_API_KEY unavailable; authorization not accepted.`;

const NOT_ACCEPTED_RE = /execute-plan: (\w+)-autonomous comment (\d+) not accepted —/;

function commentHasRejectionNote(comments, commentId, { botLogin = 'github-actions[bot]' } = {}) {
  for (const c of comments || []) {
    if (!c.user || c.user.login !== botLogin) continue;
    const m = NOT_ACCEPTED_RE.exec(String(c.body || '').trim());
    if (m && Number(m[2]) === commentId) return true;
  }
  return false;
}

function parseAckBody(body) {
  const m = ACK_RE.exec(String(body || '').trim());
  return m ? { commentId: Number(m[1]), runId: Number(m[2]) } : null;
}

/**
 * @returns {Promise<Set<number>>} comment ids with a valid acknowledgement on the control issue
 */
async function acceptedAuthorizationIds(client, comments, { botLogin = 'github-actions[bot]' } = {}) {
  const accepted = new Set();
  const runCache = new Map();
  for (const comment of comments || []) {
    if (!comment.user || comment.user.login !== botLogin) continue;
    const parsed = parseAckBody(comment.body);
    if (!parsed) continue;
    let run = runCache.get(parsed.runId);
    if (run === undefined) {
      try {
        run = await client.getWorkflowRun(parsed.runId);
      } catch {
        run = null;
      }
      runCache.set(parsed.runId, run);
    }
    if (!run || run.path !== '.github/workflows/execute-plan-approve.yml' || run.head_branch !== 'main' || run.event !== 'issue_comment') {
      continue;
    }
    if (commentHasRejectionNote(comments, parsed.commentId)) continue;
    accepted.add(parsed.commentId);
  }
  return accepted;
}

module.exports = {
  ACK_RE,
  formatAck,
  formatIgnoredNote,
  formatStoppedNote,
  formatKeyUnavailableNote,
  parseAckBody,
  commentHasRejectionNote,
  acceptedAuthorizationIds,
};
