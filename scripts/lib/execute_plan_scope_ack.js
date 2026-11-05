'use strict';

/**
 * Owner scope acknowledgment via an APPROVING pull request review on the PR head.
 * Reusable by execute-plan scope (WP7a) and future unified safety gate (#1980).
 */

/**
 * @param {object} review  GitHub pull request review
 * @param {{ headSha: string, owners: string[], botLogin: string }} opts
 * @returns {boolean}
 */
function qualifiesOwnerScopeAck(review, { headSha, owners, botLogin }) {
  if (!review || String(review.state).toUpperCase() !== 'APPROVED') return false;
  if (review.commit_id !== headSha) return false;
  const login = review.user && review.user.login;
  if (!login || login === botLogin) return false;
  return (owners || []).includes(login);
}

/** Newest qualifying approving review on `headSha`, or null. */
function findOwnerScopeAckReview(reviews, opts) {
  const list = [...(reviews || [])].sort((a, b) => Number(b.id) - Number(a.id));
  return list.find((r) => qualifiesOwnerScopeAck(r, opts)) || null;
}

module.exports = { qualifiesOwnerScopeAck, findOwnerScopeAckReview };
