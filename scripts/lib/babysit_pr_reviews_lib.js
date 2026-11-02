'use strict';

// Review author is `copilot-pull-request-reviewer[bot]`; a pending request lists the reviewer as `Copilot`.
const COPILOT_LOGIN_RE = /^copilot/i;

function isCopilotLogin(login) {
  return COPILOT_LOGIN_RE.test(String(login || ''));
}

function classifyReviewer(login) {
  return isCopilotLogin(login) ? 'copilot' : 'human';
}

function loginOf(entry) {
  return entry?.user?.login || entry?.author?.login || entry?.login || '';
}

/**
 * A pending request wins over an earlier review: GitHub keeps Copilot in `requested_reviewers`
 * until the (re-)review is submitted, so threads from that review are not in yet.
 */
function assessCopilotStatus({ reviews, reviewComments, requestedReviewers }) {
  const copilotComments = (reviewComments || []).filter((c) => isCopilotLogin(loginOf(c)));
  if ((requestedReviewers || []).some((r) => isCopilotLogin(loginOf(r)))) {
    return { state: 'pending', reason: 'review_requested', inlineCommentCount: copilotComments.length };
  }
  if ((reviews || []).some((r) => isCopilotLogin(loginOf(r)))) {
    return { state: 'complete', reason: 'review_submitted', inlineCommentCount: copilotComments.length };
  }
  if (copilotComments.length > 0) {
    return { state: 'complete', reason: 'inline_comments_only', inlineCommentCount: copilotComments.length };
  }
  return { state: 'absent', reason: 'no_review', inlineCommentCount: 0 };
}

function normalizeReviewThread(thread) {
  const comments = thread?.comments?.nodes || [];
  const first = comments[0] || {};
  const author = first.author?.login || 'unknown';
  return {
    isResolved: Boolean(thread?.isResolved),
    reviewer: classifyReviewer(author),
    author,
    path: first.path || null,
    line: first.line ?? null,
    body: first.body || '',
    url: first.url || null,
    commentCount: comments.length,
  };
}

function normalizeReviewThreads(graphqlThreads) {
  return (graphqlThreads || []).map(normalizeReviewThread);
}

/**
 * `readyForTriage` — no automatic review still in progress, so `threads` is the full set to triage.
 * `mergeReady` — ready for triage, nothing unresolved, and the thread list was not truncated.
 */
function buildCollectReport({ prNumber, copilot, threads, timedOut = false, truncated = false }) {
  const unresolvedThreads = threads.filter((thread) => !thread.isResolved);
  const copilotThreads = unresolvedThreads.filter((thread) => thread.reviewer === 'copilot');
  const humanThreads = unresolvedThreads.filter((thread) => thread.reviewer === 'human');

  const copilotPending = copilot.state === 'pending';
  const readyForTriage = !copilotPending;
  const mergeReady = readyForTriage && unresolvedThreads.length === 0 && !truncated;

  const warnings = [];
  if (copilotPending) {
    warnings.push(
      timedOut
        ? 'Copilot review still pending after the wait timeout — treat Copilot as unavailable (pr-review-cost-efficiency.md §Copilot unavailable) and triage the threads present.'
        : 'Copilot review in progress — more threads may arrive. Run `wait` before triage or merge.'
    );
  }
  if (truncated) {
    warnings.push(
      'Review thread collection was truncated (GraphQL page limit). Inspect the GitHub UI for additional threads.'
    );
  }

  return {
    prNumber,
    reviewers: { copilot },
    threads: unresolvedThreads,
    summary: {
      unresolvedCount: unresolvedThreads.length,
      copilotCount: copilotThreads.length,
      humanCount: humanThreads.length,
      truncated,
    },
    readyForTriage,
    mergeReady,
    timedOut,
    warnings,
  };
}

function parsePrRef(prRef, defaultOwner, defaultRepo) {
  const raw = String(prRef || '').trim();
  if (!raw) {
    throw new Error('PR reference is required');
  }

  const urlMatch = raw.match(/github\.com\/([^/]+)\/([^/]+)\/pull\/(\d+)/i);
  if (urlMatch) {
    return { owner: urlMatch[1], repo: urlMatch[2], number: Number(urlMatch[3]) };
  }

  const slugMatch = raw.match(/^([^/#]+)\/([^#]+)#(\d+)$/);
  if (slugMatch) {
    return { owner: slugMatch[1], repo: slugMatch[2], number: Number(slugMatch[3]) };
  }

  if (/^\d+$/.test(raw)) {
    if (!defaultOwner || !defaultRepo) {
      throw new Error('PR number requires default owner/repo from gh context');
    }
    return { owner: defaultOwner, repo: defaultRepo, number: Number(raw) };
  }

  throw new Error(`Could not parse PR reference: ${raw}`);
}

module.exports = {
  classifyReviewer,
  isCopilotLogin,
  assessCopilotStatus,
  normalizeReviewThreads,
  buildCollectReport,
  parsePrRef,
};
