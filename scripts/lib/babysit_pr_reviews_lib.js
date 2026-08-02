'use strict';

const BUGBOT_LOGINS = new Set(['cursor', 'cursor[bot]']);
const COPILOT_LOGIN_PREFIX = 'copilot-pull-request-reviewer';

const BUGBOT_UNAVAILABLE_PATTERNS = [
  'usage limit',
  "couldn't run",
  'could not run',
  'hit a usage',
  'spend limit',
];

function normalizeLogin(login) {
  return String(login || '').toLowerCase();
}

function classifyReviewer(login) {
  const normalized = normalizeLogin(login);
  if (BUGBOT_LOGINS.has(normalized)) return 'bugbot';
  if (normalized.startsWith(COPILOT_LOGIN_PREFIX)) return 'copilot';
  return 'human';
}

function isBugbotUnavailableComment(body) {
  const text = String(body || '').toLowerCase();
  return BUGBOT_UNAVAILABLE_PATTERNS.some((pattern) => text.includes(pattern));
}

function isBugbotLogin(login) {
  return BUGBOT_LOGINS.has(normalizeLogin(login));
}

function detectBugbotUnavailableFromIssueComments(comments) {
  for (const comment of comments || []) {
    const login = comment.user?.login || comment.author?.login;
    if (!isBugbotLogin(login)) continue;
    if (isBugbotUnavailableComment(comment.body)) {
      return {
        unavailable: true,
        reason: 'usage_limit',
        commentUrl: comment.html_url || comment.url || null,
      };
    }
  }
  return { unavailable: false };
}

function hasBugbotReview(reviews) {
  return (reviews || []).some((review) => {
    const login = review.user?.login || review.author?.login;
    return isBugbotLogin(login);
  });
}

function hasCopilotReview(reviews) {
  return (reviews || []).some((review) => {
    const login = normalizeLogin(review.user?.login || review.author?.login);
    return login.startsWith(COPILOT_LOGIN_PREFIX);
  });
}

function hasCursorBugbotCheck(checkRuns) {
  return (checkRuns || []).some((check) => {
    const name = String(check.name || '').toLowerCase();
    return name.includes('cursor bugbot') || name === 'bugbot';
  });
}

function assessBugbotStatus({ reviews, issueComments, checkRuns }) {
  const unavailable = detectBugbotUnavailableFromIssueComments(issueComments);
  if (unavailable.unavailable) {
    return {
      state: 'unavailable',
      reason: unavailable.reason,
      commentUrl: unavailable.commentUrl,
    };
  }

  if (hasBugbotReview(reviews)) {
    return { state: 'complete', reason: 'review_submitted' };
  }

  const bugbotCheck = (checkRuns || []).find((check) => {
    const name = String(check.name || '').toLowerCase();
    return name.includes('cursor bugbot') || name === 'bugbot';
  });
  if (bugbotCheck) {
    const status = String(bugbotCheck.status || '').toUpperCase();
    const conclusion = String(bugbotCheck.conclusion || '').toUpperCase();
    if (status === 'IN_PROGRESS' || status === 'QUEUED' || status === 'PENDING') {
      return { state: 'pending', reason: 'check_in_progress' };
    }
    if (status === 'COMPLETED' && conclusion) {
      return { state: 'complete', reason: 'check_finished' };
    }
  }

  if (hasCursorBugbotCheck(checkRuns)) {
    return { state: 'pending', reason: 'check_expected' };
  }

  return { state: 'pending', reason: 'not_seen_yet' };
}

function assessCopilotStatus({ reviews, reviewComments, reviewRequests }) {
  if (hasCopilotReview(reviews)) {
    const copilotComments = (reviewComments || []).filter(
      (comment) => classifyReviewer(comment.user?.login) === 'copilot'
    );
    return {
      state: 'complete',
      reason: 'review_submitted',
      inlineCommentCount: copilotComments.length,
    };
  }

  const requested = (reviewRequests || []).some((login) =>
    normalizeLogin(login).startsWith(COPILOT_LOGIN_PREFIX)
  );
  if (requested) {
    return { state: 'pending', reason: 'review_requested' };
  }

  const copilotComments = (reviewComments || []).filter(
    (comment) => classifyReviewer(comment.user?.login) === 'copilot'
  );
  if (copilotComments.length > 0) {
    return {
      state: 'complete',
      reason: 'inline_comments_only',
      inlineCommentCount: copilotComments.length,
    };
  }

  return { state: 'absent', reason: 'no_review' };
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

function buildCollectReport({
  prNumber,
  bugbot,
  copilot,
  threads,
  timedOut = false,
  truncated = false,
}) {
  const unresolvedThreads = threads.filter((thread) => !thread.isResolved);
  const copilotThreads = unresolvedThreads.filter((thread) => thread.reviewer === 'copilot');
  const bugbotThreads = unresolvedThreads.filter((thread) => thread.reviewer === 'bugbot');
  const humanThreads = unresolvedThreads.filter((thread) => thread.reviewer === 'human');

  const bugbotBlocking = bugbot.state === 'pending' && !timedOut;
  let haltReason = null;
  if (timedOut && bugbot.state === 'pending') {
    haltReason = 'bugbot_timeout';
  }
  const readyForTriage = !bugbotBlocking && !haltReason;

  const warnings = [];
  if (bugbot.state === 'unavailable' && copilotThreads.length > 0) {
    warnings.push(
      'Bugbot unavailable but Copilot left review threads — triage all Copilot threads before merge.'
    );
  }
  if (bugbot.state === 'unavailable' && unresolvedThreads.length === 0) {
    warnings.push('Bugbot unavailable and no unresolved review threads found.');
  }
  if (truncated) {
    warnings.push(
      'Review thread collection was truncated (GraphQL page limit). Re-run collect or inspect GitHub UI for additional threads.'
    );
  }

  return {
    prNumber,
    reviewers: { bugbot, copilot },
    threads: unresolvedThreads,
    summary: {
      unresolvedCount: unresolvedThreads.length,
      copilotCount: copilotThreads.length,
      bugbotCount: bugbotThreads.length,
      humanCount: humanThreads.length,
      truncated,
    },
    readyForTriage,
    halt: Boolean(haltReason),
    haltReason,
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
  BUGBOT_LOGINS,
  COPILOT_LOGIN_PREFIX,
  classifyReviewer,
  isBugbotLogin,
  detectBugbotUnavailableFromIssueComments,
  assessBugbotStatus,
  assessCopilotStatus,
  normalizeReviewThreads,
  buildCollectReport,
  parsePrRef,
};
