import type { Page } from '@playwright/test';
import { setPlaywrightApiRequest } from './api-fetch';

const LIVE_HOST_PATTERN = /agathatrack\.com/i;
const WAF_MARKERS = ['o2s-browser-check', 'Security check', 'Test de sécurité'];

export function isLiveHostingTarget(baseURL?: string): boolean {
  const url = baseURL ?? process.env.E2E_BASE_URL ?? '';
  return LIVE_HOST_PATTERN.test(url);
}

function pageShowsWafChallenge(html: string): boolean {
  return WAF_MARKERS.some((marker) => html.includes(marker));
}

/**
 * o2switch serves a JavaScript browser challenge to non-browser clients.
 * Visit the site in Playwright first so API seeding can reuse the session cookies.
 */
export async function passHostingWaf(page: Page, baseURL?: string): Promise<void> {
  if (!isLiveHostingTarget(baseURL)) {
    return;
  }

  await page.goto('/', { waitUntil: 'domcontentloaded' });

  for (let attempt = 0; attempt < 12; attempt++) {
    const html = await page.content();
    if (!pageShowsWafChallenge(html)) {
      return;
    }
    await page.waitForTimeout(2_500);
  }

  const html = await page.content();
  if (pageShowsWafChallenge(html)) {
    throw new Error('Hosting WAF challenge did not clear after visiting UAT');
  }
}

/** Warm WAF cookies and route api.ts through page.request for live UAT runs. */
export async function prepareLiveApiAccess(page: Page, baseURL?: string): Promise<void> {
  await passHostingWaf(page, baseURL);
  if (isLiveHostingTarget(baseURL)) {
    setPlaywrightApiRequest(page.request);
  }
}

export function clearLiveApiAccess(): void {
  setPlaywrightApiRequest(null);
}
