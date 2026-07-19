/**
 * Optional auth rate-limit bypass for audited CI traffic against live UAT.
 *
 * Requires BOTH:
 *   E2E_BYPASS_ALLOWED=true  (set only on UAT — never on production)
 *   E2E_BYPASS_TOKEN         (shared secret; also in GitHub Actions secrets)
 *
 * Clients send header X-E2E-Bypass-Token. Token value is never logged.
 */
import crypto from 'node:crypto';

export const E2E_BYPASS_HEADER = 'x-e2e-bypass-token';

let bypassSkipCount = 0;

export function getE2eAuthBypassSkipCount() {
  return bypassSkipCount;
}

export function resetE2eAuthBypassSkipCountForTests() {
  bypassSkipCount = 0;
}

export function isE2eAuthBypassConfigured() {
  return (
    process.env.E2E_BYPASS_ALLOWED === 'true' &&
    typeof process.env.E2E_BYPASS_TOKEN === 'string' &&
    process.env.E2E_BYPASS_TOKEN.length > 0
  );
}

export function isE2eAuthBypassAuthorized(req) {
  if (!isE2eAuthBypassConfigured()) {
    return false;
  }

  const provided = req.headers[E2E_BYPASS_HEADER] ?? req.headers['X-E2E-Bypass-Token'];
  if (typeof provided !== 'string' || provided.length === 0) {
    return false;
  }

  const expected = process.env.E2E_BYPASS_TOKEN;
  const providedBuf = Buffer.from(provided);
  const expectedBuf = Buffer.from(expected);
  if (providedBuf.length !== expectedBuf.length) {
    return false;
  }

  try {
    return crypto.timingSafeEqual(providedBuf, expectedBuf);
  } catch {
    return false;
  }
}

export function recordE2eAuthBypassSkip() {
  bypassSkipCount += 1;
  if (bypassSkipCount === 1 || bypassSkipCount % 25 === 0) {
    console.warn(
      `[e2e-bypass] auth rate-limit bypass used (count=${bypassSkipCount}; token not logged)`,
    );
  }
}

if (process.env.E2E_BYPASS_TOKEN && process.env.E2E_BYPASS_ALLOWED !== 'true') {
  console.warn(
    'E2E_BYPASS_TOKEN is set but E2E_BYPASS_ALLOWED is not true — auth bypass is disabled.',
  );
}
