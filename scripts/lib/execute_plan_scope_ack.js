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

/** Latest review per owner on `headSha`; scope ack only if that review is APPROVING. */
function findOwnerScopeAckReview(reviews, opts) {
  const latestByOwner = new Map();
  const list = [...(reviews || [])].sort((a, b) => Number(b.id) - Number(a.id));
  for (const r of list) {
    if (!r || r.commit_id !== opts.headSha) continue;
    const login = r.user && r.user.login;
    if (!login || login === opts.botLogin) continue;
    if (!(opts.owners || []).includes(login)) continue;
    if (!latestByOwner.has(login)) latestByOwner.set(login, r);
  }
  for (const login of opts.owners || []) {
    const latest = latestByOwner.get(login);
    if (latest && qualifiesOwnerScopeAck(latest, opts)) return latest;
  }
  return null;
}

module.exports = { qualifiesOwnerScopeAck, findOwnerScopeAckReview };
