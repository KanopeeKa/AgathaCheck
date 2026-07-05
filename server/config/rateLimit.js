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

export function createAuthLimiter() {
  const windowMs = Number(process.env.AUTH_RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000;
  const limit = Number(process.env.AUTH_RATE_LIMIT_MAX) || 10;
  return rateLimit({
    windowMs,
    limit,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    skip: () =>
      process.env.AUTH_RATE_LIMIT_TEST !== '1' &&
      (process.env.NODE_ENV === 'test' || process.env.E2E === '1'),
    message: { error: 'Too many requests, please try again later.' },
  });
}
