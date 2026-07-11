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

type HealthProbe = 'ok' | 'waf' | 'down';

async function probeBackendHealth(page: Page, baseURL: string): Promise<HealthProbe> {
  const healthUrl = `${baseURL}/backend/health`;
  return page.evaluate(async (url) => {
    try {
      const res = await fetch(url, { credentials: 'include' });
      const body = await res.text();
      if (body.includes('"status":"OK"')) return 'ok';
      if (body.includes('o2s-browser-check') || body.includes('Security check')) return 'waf';
      return 'down';
    } catch {
      return 'down';
    }
  }, healthUrl);
}

function backendDownMessage(baseURL: string): string {
  return [
    `UAT backend is not healthy at ${baseURL}/backend/health`,
    '(expected JSON {"status":"OK"}, got HTML or an error).',
    'On cPanel: confirm Passenger/Node is running, Run NPM Install (CloudLinux symlink),',
    'and that the deployed .htaccess excludes /backend from the Flutter SPA rewrite.',
  ].join(' ');
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

  let sawWaf = false;
  const deadline = Date.now() + 90_000;
  while (Date.now() < deadline) {
    const html = await page.content();
    if (pageShowsWafChallenge(html)) {
      sawWaf = true;
      await page.waitForTimeout(3_000);
      continue;
    }

    const health = await probeBackendHealth(page, root);
    if (health === 'ok') {
      return;
    }
    if (health === 'waf') {
      sawWaf = true;
      await page.waitForTimeout(3_000);
      continue;
    }

    throw new Error(backendDownMessage(root));
  }

  if (sawWaf) {
    throw new Error('Hosting WAF challenge did not clear after visiting UAT');
  }
  throw new Error(backendDownMessage(root));
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
