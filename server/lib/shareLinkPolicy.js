/**
 * Share link expiry policy (F-04).
 * Product decisions locked 2026-09-05 — discovery report §A.
 */
export const DEFAULT_SHARE_EXPIRY_DAYS = 7;
export const MAX_SHARE_EXPIRY_DAYS = 90;

/**
 * @param {number | string | null | undefined} requestedDays
 * @returns {number}
 */
export function normalizeShareExpiryDays(requestedDays) {
  const parsed = Number(requestedDays);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return DEFAULT_SHARE_EXPIRY_DAYS;
  }
  return Math.min(MAX_SHARE_EXPIRY_DAYS, Math.floor(parsed));
}

/**
 * @param {Date | string | null | undefined} expiresAt
 * @returns {boolean}
 */
export function isShareLinkExpired(expiresAt) {
  if (!expiresAt) return true;
  const expiry = expiresAt instanceof Date ? expiresAt : new Date(expiresAt);
  if (Number.isNaN(expiry.getTime())) return true;
  return expiry.getTime() <= Date.now();
}

/**
 * @param {number} days
 * @returns {Date}
 */
export function shareExpiryFromNow(days) {
  const expires = new Date();
  expires.setUTCDate(expires.getUTCDate() + days);
  return expires;
}
