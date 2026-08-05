import type { BrowserContext } from '@playwright/test';
import { isLiveUatTarget } from './hosting';

/** Reduce headless automation signals for o2switch Tiger Protect on live UAT. */
export async function applyLiveHostingStealth(context: BrowserContext): Promise<void> {
  if (!isLiveUatTarget()) {
    return;
  }

  await context.addInitScript(() => {
    Object.defineProperty(navigator, 'webdriver', { get: () => false });

  });
}
