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

// The ruleset's Copilot request lands seconds after the PR opens; until then a young PR is not "no review".
const COPILOT_REQUEST_GRACE_MS = 3 * 60 * 1000;

/**
 * A pending request wins over an earlier review: GitHub keeps Copilot in `requested_reviewers`
 * until the (re-)review is submitted, so threads from that review are not in yet.
 */
function assessCopilotStatus({ reviews, reviewComments, requestedReviewers, createdAt, now = Date.now() }) {
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
  const age = createdAt ? now - Date.parse(createdAt) : Infinity;
  if (age < COPILOT_REQUEST_GRACE_MS) {
    return { state: 'pending', reason: 'awaiting_request', inlineCommentCount: 0 };
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
 * One `reviewThreads` page. `gh api graphql` can exit 0 with an `errors` array and no `data`:
 * that must throw, never read as zero threads.
 */
function readReviewThreadPage(graphql, prNumber) {
  if (Array.isArray(graphql?.errors) && graphql.errors.length > 0) {
    throw new Error(`review threads query failed: ${graphql.errors.map((e) => e.message).join('; ')}`);
  }
  const connection = graphql?.data?.repository?.pullRequest?.reviewThreads;
  if (!connection || !Array.isArray(connection.nodes)) {
    throw new Error(`review threads query returned no reviewThreads for PR #${prNumber}`);
  }
  const nextCursor = connection.pageInfo?.hasNextPage ? connection.pageInfo.endCursor || null : null;
  if (connection.pageInfo?.hasNextPage && !nextCursor) {
    throw new Error(`review threads page for PR #${prNumber} has a next page but no cursor`);
  }
  return { nodes: connection.nodes, nextCursor };
}

/**
 * `readyForTriage` — `threads` is the full set to triage: no Copilot review in progress, or the wait
 *   timed out and Copilot counts as unavailable (`copilotUnavailable`).
 * `mergeReady` — no Copilot review in progress and nothing unresolved.
 */
function buildCollectReport({ prNumber, copilot, threads, timedOut = false }) {
  const unresolvedThreads = threads.filter((thread) => !thread.isResolved);
  const copilotThreads = unresolvedThreads.filter((thread) => thread.reviewer === 'copilot');
  const humanThreads = unresolvedThreads.filter((thread) => thread.reviewer === 'human');

  const copilotPending = copilot.state === 'pending';
  const copilotUnavailable = copilotPending && timedOut;
  const readyForTriage = !copilotPending || copilotUnavailable;
  const mergeReady = !copilotPending && unresolvedThreads.length === 0;

  const warnings = [];
  if (copilotUnavailable) {
    warnings.push(
      'Copilot review still pending after the wait timeout — treat Copilot as unavailable (pr-review-cost-efficiency.md §Copilot unavailable) and triage the threads present.'
    );
  } else if (copilotPending) {
    warnings.push('Copilot review in progress — more threads may arrive. Run `wait` before triage or merge.');
  }

  return {
    prNumber,
    reviewers: { copilot },
    threads: unresolvedThreads,
    summary: {
      unresolvedCount: unresolvedThreads.length,
      copilotCount: copilotThreads.length,
      humanCount: humanThreads.length,
    },
    readyForTriage,
    mergeReady,
    copilotUnavailable,
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
  COPILOT_REQUEST_GRACE_MS,
  classifyReviewer,
  isCopilotLogin,
  assessCopilotStatus,
  normalizeReviewThreads,
  buildCollectReport,
  parsePrRef,
  readReviewThreadPage,
};
