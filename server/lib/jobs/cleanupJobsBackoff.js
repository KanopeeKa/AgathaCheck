/** Backoff schedule after a retryable failure (attempt index 0 = first retry). */
export const CLEANUP_JOB_BACKOFF_MS = [
  60 * 1000,
  5 * 60 * 1000,
  30 * 60 * 1000,
  2 * 60 * 60 * 1000,
  6 * 60 * 60 * 1000,
  12 * 60 * 60 * 1000,
  24 * 60 * 60 * 1000,
];

export const DEFAULT_MAX_CLEANUP_ATTEMPTS = 8;

export function nextAttemptAfterFailure(attemptsAfterIncrement) {
  const index = Math.max(0, attemptsAfterIncrement - 1);
  const ms = CLEANUP_JOB_BACKOFF_MS[Math.min(index, CLEANUP_JOB_BACKOFF_MS.length - 1)];
  return new Date(Date.now() + ms);
}
