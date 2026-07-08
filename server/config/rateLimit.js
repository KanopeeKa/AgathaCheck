/**
 * Rate limiter for sensitive auth endpoints (login, signup, forgot/reset
 * password) to blunt credential-stuffing and reset-code brute force.
 *
 * Window/limit are configurable via env (`AUTH_RATE_LIMIT_WINDOW_MS`,
 * `AUTH_RATE_LIMIT_MAX`) and default to 10 requests per 15 minutes per IP.
 *
 * The limiter is skipped under `NODE_ENV=test` (Jest) and `E2E=1` (Playwright)
 * so automated suites are not throttled, unless a test opts in by setting
 * `AUTH_RATE_LIMIT_TEST=1` (used by the dedicated rate-limit test). Mirror any
 * behavior change in the Dart server's `lib/rate_limit.dart`.
 */
import rateLimit from 'express-rate-limit';

function shouldSkipRateLimit() {
  return process.env.NODE_ENV === 'test' || process.env.E2E === '1';
}

export function createAuthLimiter() {
  const windowMs = Number(process.env.AUTH_RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000;
  const limit = Number(process.env.AUTH_RATE_LIMIT_MAX) || 10;
  return rateLimit({
    windowMs,
    limit,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    skip: () =>
      process.env.AUTH_RATE_LIMIT_TEST !== '1' && shouldSkipRateLimit(),
    message: { error: 'Too many requests, please try again later.' },
  });
}

/**
 * General API rate limiter for authenticated CRUD routes (DB / file access).
 * Satisfies CodeQL js/missing-rate-limiting when applied via router.use().
 * Configurable via API_RATE_LIMIT_WINDOW_MS (default 1 min) and
 * API_RATE_LIMIT_MAX (default 200 requests per window per IP).
 */
export function createApiLimiter() {
  const windowMs = Number(process.env.API_RATE_LIMIT_WINDOW_MS) || 60 * 1000;
  const limit = Number(process.env.API_RATE_LIMIT_MAX) || 200;
  return rateLimit({
    windowMs,
    limit,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    skip: shouldSkipRateLimit,
    message: { error: 'Too many requests, please try again later.' },
  });
}
