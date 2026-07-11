import { test as base, expect } from '@playwright/test';
import { applyLiveHostingStealth } from '../support/stealth';

/** Base Playwright test with live-hosting stealth applied to every browser context. */
export const test = base.extend({
  context: async ({ context }, use) => {
    await applyLiveHostingStealth(context);
    await use(context);
  },
});

export { expect };
