/**
 * Confirms UAT auth (signup) is reachable through the o2switch Tiger Protect
 * WAF before the full @smoke-uat suite runs.
 *
 * Why not curl: Tiger Protect serves a JavaScript challenge (`o2s-browser-check`)
 * to non-browser clients. A bare HTTP client (curl, node fetch) can never solve
 * a JS challenge — there is no header/retry/User-Agent trick that passes it, so
 * a curl-based warmup fails 100% of the time once the WAF decides to challenge
 * CI traffic (see docs/e2e/uat-live-operations-runbook.md). The `testUser`
 * fixture below reuses the same real-browser + stealth path
 * (support/waf.ts passHostingWaf, support/stealth.ts) that @smoke-uat tests
 * already use successfully against this exact WAF.
 *
 * Runs as its own Playwright project (see playwright.config.ts `warmup-uat`)
 * so deploy-uat.yml can gate the full 30-min @smoke-uat/full-E2E run on a
 * single fast, WAF-capable check instead of a curl probe that cannot pass.
 */
import { test, expect } from '../fixtures/auth.fixture';
import { persistWafStorageState } from '../support/waf';

test('@warmup-uat UAT auth warmup — signup succeeds through hosting WAF', async ({ page, testUser }) => {
  expect(testUser.email).toBeTruthy();
  expect(testUser.accessToken).toBeTruthy();
  // Each Playwright test gets a fresh browser context — persist WAF cookies for uat-smoke.
  await persistWafStorageState(page);
});
