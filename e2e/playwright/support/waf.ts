import type { Page } from '@playwright/test';
import { clearApiFetchTransports, setPlaywrightPage } from './api-fetch';
import { e2eBypassHeadersForUrl } from './e2e-bypass';
import { isLiveHostingTarget } from './hosting';
import { bodyShowsWafChallenge, WAF_MARKERS } from './waf-markers';

let sessionWafCleared = false;

export { bodyShowsWafChallenge } from './waf-markers';

function pageShowsWafChallenge(html: string): boolean {
  return bodyShowsWafChallenge(html);
}

function resolveBaseURL(baseURL?: string): string {
  return (baseURL ?? process.env.E2E_BASE_URL ?? '').replace(/\/$/, '');
}

type ProbeResult = 'ok' | 'waf' | 'health_down' | 'auth_down';

async function probeBackendHealth(page: Page, baseURL: string): Promise<ProbeResult> {
  const healthUrl = `${baseURL}/backend/health`;
  const result = await page.evaluate(async ([url, markers]: [string, string[]]) => {
    try {
      const res = await fetch(url, { credentials: 'include' });
      const body = await res.text();
      if (body.includes('"status":"OK"')) return 'ok';
      if (markers.some((m) => body.includes(m))) return 'waf';
      return 'down';
    } catch {
      return 'down';
    }
  }, [healthUrl, WAF_MARKERS] as [string, string[]]);

  if (result === 'ok' || result === 'waf') {
    return result;
  }
  return 'health_down';
}

/**
 * Tiger Protect scrutinizes auth endpoints more than /backend/health. Probe signup
 * with an intentionally invalid body — a JSON 400 means the app is reachable;
 * WAF HTML (often 503) means the session is not ready for createTestUser yet.
 */
async function probeAuthSignup(page: Page, baseURL: string): Promise<ProbeResult> {
  const signupUrl = `${baseURL}/backend/api/auth/signup`;
  const bypassHeaders = e2eBypassHeadersForUrl(baseURL);
  const result = await page.evaluate(
    async ([url, markers, headers]: [string, string[], Record<string, string>]) => {
      try {
        const res = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', ...headers },
          credentials: 'include',
          body: JSON.stringify({}),
        });
        const body = await res.text();
        if (markers.some((m) => body.includes(m))) return 'waf';
        if (res.status === 400 && body.includes('"error"')) return 'ok';
        if (res.status >= 400 && res.status < 500 && body.trimStart().startsWith('{') && body.includes('"error"')) {
          return 'ok';
        }
        return 'down';
      } catch {
        return 'down';
      }
    },
    [signupUrl, WAF_MARKERS, bypassHeaders] as [string, string[], Record<string, string>],
  );

  if (result === 'ok' || result === 'waf') {
    return result;
  }
  return 'auth_down';
}

async function liveApiProbesReady(page: Page, baseURL: string): Promise<ProbeResult> {
  const health = await probeBackendHealth(page, baseURL);
  if (health !== 'ok') {
    return health;
  }
  return probeAuthSignup(page, baseURL);
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

function authBlockedMessage(baseURL: string): string {
  return [
    `UAT auth signup is still blocked by hosting WAF at ${baseURL}/backend/api/auth/signup`,
    'after the page challenge cleared. Tiger Protect often allows /backend/health before',
    'auth endpoints — retry or whitelist GitHub Actions egress in o2switch Tiger Protect.',
  ].join(' ');
}

function authUnreachableMessage(baseURL: string): string {
  return [
    `UAT auth signup is not reachable at ${baseURL}/backend/api/auth/signup`,
    '(expected JSON 400 validation error for an empty body, got HTML or a server error).',
    'Health may be OK while Passenger/auth routes are still failing — check UAT deploy logs.',
  ].join(' ');
}

function probeFailureMessage(baseURL: string, probe: ProbeResult): string {
  if (probe === 'waf') {
    return authBlockedMessage(baseURL);
  }
  if (probe === 'auth_down') {
    return authUnreachableMessage(baseURL);
  }
  return backendDownMessage(baseURL);
}

/**
 * o2switch Tiger Protect serves a JavaScript challenge to bot-like clients.
 * Load the app in Chromium (headed on CI), wait for the challenge to finish,
 * then verify both health and auth signup probes succeed in-browser.
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
      const probes = await liveApiProbesReady(page, root);
      if (probes === 'ok') {
        sessionWafCleared = true;
        return;
      }
      if (probes === 'waf') {
        // Health or auth may still be challenged after the page shell loads.
        await page.waitForTimeout(3_000);
        continue;
      }
      throw new Error(probeFailureMessage(root, probes));
    }

    await page.waitForTimeout(2_000);
  }

  if (pageShowsWafChallenge(await page.content())) {
    throw new Error(
      'Hosting WAF challenge did not clear after visiting UAT. '
      + 'Whitelist GitHub Actions IPs in o2switch Tiger Protect or disable browser challenges for UAT.',
    );
  }

  const finalProbe = await liveApiProbesReady(page, root);
  if (finalProbe === 'ok') {
    sessionWafCleared = true;
    return;
  }
  throw new Error(probeFailureMessage(root, finalProbe));
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
    const probes = await liveApiProbesReady(page, root).catch((): ProbeResult => 'health_down');
    if (probes !== 'ok') {
      sessionWafCleared = false;
    }
  }

  await passHostingWaf(page, baseURL);
  setPlaywrightPage(page);
}

export function clearLiveApiAccess(): void {
  clearApiFetchTransports();
}
