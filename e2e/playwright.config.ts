import path from 'node:path';

import { defineConfig, devices } from '@playwright/test';

const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
/** Live UAT (cPanel auto-SSL) may present a cert chain GitHub runners do not trust. */
const tlsInsecure = process.env.E2E_TLS_INSECURE === '1';
const isLiveUat = tlsInsecure;
const uatWafStoragePath = path.join(__dirname, 'playwright', '.uat-waf-storage.json');

const sharedUse = {
  baseURL,
  ignoreHTTPSErrors: tlsInsecure,
  headless: !isLiveUat,
  launchOptions: isLiveUat
    ? { args: ['--disable-blink-features=AutomationControlled'] }
    : undefined,
  viewport: { width: 1280, height: 720 },
  trace: 'on-first-retry' as const,
  screenshot: 'only-on-failure' as const,
  video: 'retain-on-failure' as const,
  ...devices['Desktop Chrome'],
};

export default defineConfig({
  testDir: './playwright/tests',
  globalSetup: require.resolve('./playwright/support/global-setup'),
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  workers: 1,
  reporter: [
    ['list'],
    ['html', { open: 'never', outputFolder: 'playwright-report' }],
  ],
  use: sharedUse,
  timeout: isLiveUat ? 180_000 : 90_000,
  expect: { timeout: 15_000 },
  outputDir: 'test-results',
  projects: [
    {
      name: 'ci-canary',
      grep: /@smoke-ci/,
      retries: 0,
      timeout: 45_000,
      use: sharedUse,
    },
    {
      name: 'uat-smoke',
      grep: /@smoke-uat/,
      dependencies: isLiveUat ? ['warmup-uat'] : undefined,
      retries: 0,
      use: isLiveUat ? { ...sharedUse, storageState: uatWafStoragePath } : sharedUse,
    },
    {
      // Fast, WAF-capable auth check gating the full @smoke-uat/full-E2E run —
      // see playwright/tests/uat-auth-warmup.spec.ts for why this replaces a
      // curl-based warmup (curl cannot solve o2switch's JS challenge).
      name: 'warmup-uat',
      grep: /@warmup-uat/,
      retries: 1,
      timeout: 150_000,
      use: sharedUse,
    },
    {
      name: 'full',
      grepInvert: /@smoke-ci|@smoke-uat|@smoke-a11y|@warmup-uat/,
      retries: 0,
      use: sharedUse,
    },
  ],
});
