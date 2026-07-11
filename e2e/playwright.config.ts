import { defineConfig, devices } from '@playwright/test';

const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
/** Live UAT (cPanel auto-SSL) may present a cert chain GitHub runners do not trust. */
const tlsInsecure = process.env.E2E_TLS_INSECURE === '1';
const isLiveUat = tlsInsecure;

export default defineConfig({
  testDir: './playwright/tests',
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: 1,
  workers: 1,
  reporter: [
    ['list'],
    ['html', { open: 'never', outputFolder: 'playwright-report' }],
  ],
  use: {
    baseURL,
    ignoreHTTPSErrors: tlsInsecure,
    headless: !isLiveUat,
    launchOptions: isLiveUat
      ? { args: ['--disable-blink-features=AutomationControlled'] }
      : undefined,
    viewport: { width: 1280, height: 720 },
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    ...devices['Desktop Chrome'],
  },
  timeout: isLiveUat ? 180_000 : 90_000,
  expect: { timeout: 15_000 },
  outputDir: 'test-results',
});
