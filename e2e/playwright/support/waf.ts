import type { Page } from '@playwright/test';
import { clearApiFetchTransports, setPlaywrightPage } from './api-fetch';
import { isLiveHostingTarget } from './hosting';

const WAF_MARKERS = ['o2s-browser-check', 'Security check', 'Test de sécurité'];

let sessionWafCleared = false;

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

async function waitForAppShell(page: Page, timeoutMs = 5_000): Promise<boolean> {
  try {
    await page.waitForSelector('flutter-view, flt-glass-pane', {
      state: 'attached',
      timeout: timeoutMs,
    });
    return true;
  } catch {
    return false;
  }
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
 * Load the app in Chromium (headed on CI), wait for the challenge to finish,
 * then verify the Flutter shell is reachable.
 */
export async function passHostingWaf(page: Page, baseURL?: string): Promise<void> {
  if (!isLiveHostingTarget(baseURL)) {
    return;
  }
  if (sessionWafCleared) {
    return;
  }

  const root = resolveBaseURL(baseURL);
  await page.goto('/landing', { waitUntil: 'domcontentloaded', timeout: 60_000 });

  const deadline = Date.now() + 120_000;
  while (Date.now() < deadline) {
    const html = await page.content();
    if (pageShowsWafChallenge(html)) {
      await page.waitForTimeout(2_000);
      continue;
    }

    if (await waitForAppShell(page)) {
      const health = await probeBackendHealth(page, root);
      if (health === 'ok') {
        sessionWafCleared = true;
        return;
      }
      if (health === 'waf') {
        // The Flutter shell loaded but the API health endpoint is still returning
        // a WAF challenge. Wait 3s and retry — the Tiger Protect session sometimes
        // takes a moment to propagate to API requests after the page challenge clears.
        await page.waitForTimeout(3_000);
        continue;
      }
      throw new Error(backendDownMessage(root));
    }

    await page.waitForTimeout(2_000);
  }

  if (pageShowsWafChallenge(await page.content())) {
    throw new Error(
      'Hosting WAF challenge did not clear after visiting UAT. '
      + 'Whitelist GitHub Actions IPs in o2switch Tiger Protect or disable browser challenges for UAT.',
    );
  }
  throw new Error(backendDownMessage(root));
}

/** Call after clearing cookies so the next navigation re-runs the WAF warmup. */
export function resetHostingWafSession(): void {
  sessionWafCleared = false;
}

/** Warm WAF cookies and route api.ts through in-browser fetch for live UAT runs. */
export async function prepareLiveApiAccess(page: Page, baseURL?: string): Promise<void> {
  if (!isLiveHostingTarget(baseURL)) {
    return;
  }

  const root = resolveBaseURL(baseURL);
  if (sessionWafCleared) {
    const health = await probeBackendHealth(page, root).catch((): HealthProbe => 'down');
    if (health !== 'ok') {
      sessionWafCleared = false;
    }
  }

  await passHostingWaf(page, baseURL);
  setPlaywrightPage(page);
}

export function clearLiveApiAccess(): void {
  clearApiFetchTransports();
}
