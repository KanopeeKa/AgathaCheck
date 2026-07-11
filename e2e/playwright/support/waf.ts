import type { Page } from '@playwright/test';
import { clearApiFetchTransports, setPlaywrightPage } from './api-fetch';
import { isLiveHostingTarget } from './hosting';

const WAF_MARKERS = ['o2s-browser-check', 'Security check', 'Test de sécurité'];

function pageShowsWafChallenge(html: string): boolean {
  return WAF_MARKERS.some((marker) => html.includes(marker));
}

function resolveBaseURL(baseURL?: string): string {
  return (baseURL ?? process.env.E2E_BASE_URL ?? '').replace(/\/$/, '');
}

async function probeBackendHealth(page: Page, baseURL: string): Promise<boolean> {
  const healthUrl = `${baseURL}/backend/health`;
  return page.evaluate(async (url) => {
    try {
      const res = await fetch(url, { credentials: 'include' });
      if (!res.ok) return false;
      const body = await res.text();
      return body.includes('OK');
    } catch {
      return false;
    }
  }, healthUrl);
}

/**
 * o2switch Tiger Protect serves a JavaScript challenge to bot-like clients.
 * Load the app in Chromium, wait for the challenge to finish, then verify
 * `/backend/health` via in-browser fetch (same cookie jar as the UI).
 */
export async function passHostingWaf(page: Page, baseURL?: string): Promise<void> {
  if (!isLiveHostingTarget(baseURL)) {
    return;
  }

  const root = resolveBaseURL(baseURL);
  await page.goto('/', { waitUntil: 'domcontentloaded' });

  const deadline = Date.now() + 90_000;
  while (Date.now() < deadline) {
    const html = await page.content();
    if (!pageShowsWafChallenge(html)) {
      try {
        await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 15_000 });
      } catch {
        // Flutter may load on a routed path after the challenge redirect.
      }
      if (await probeBackendHealth(page, root)) {
        return;
      }
    }
    await page.waitForTimeout(3_000);
  }

  throw new Error('Hosting WAF challenge did not clear after visiting UAT');
}

/** Warm WAF cookies and route api.ts through in-browser fetch for live UAT runs. */
export async function prepareLiveApiAccess(page: Page, baseURL?: string): Promise<void> {
  await passHostingWaf(page, baseURL);
  if (isLiveHostingTarget(baseURL)) {
    setPlaywrightPage(page);
  }
}

export function clearLiveApiAccess(): void {
  clearApiFetchTransports();
}
