import type { BrowserContext } from '@playwright/test';
import { isLiveHostingTarget } from './hosting';

/** Reduce headless automation signals for o2switch Tiger Protect on live UAT. */
export async function applyLiveHostingStealth(context: BrowserContext): Promise<void> {
  if (!isLiveHostingTarget()) {
    return;
  }

  await context.addInitScript(() => {
    Object.defineProperty(navigator, 'webdriver', { get: () => false });

  });
}
