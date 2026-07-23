// requires Node ≥ 18 (fetch + AbortSignal.timeout)

import { appendFileSync } from 'node:fs';
import { isLiveHostingTarget } from './hosting';

const WAF_MARKERS = ['o2s-browser-check', 'Security check', 'Test de sécurité'];
const HEALTH_OK_MARKER = '"status":"OK"';
const PREFLIGHT_TIMEOUT_MS = 15_000;
/** Match scripts/uat-post-deploy-smoke.sh — Tiger Protect can challenge fresh runner IPs. */
const WAF_RETRY_ATTEMPTS = 18;
const WAF_RETRY_SLEEP_MS = 10_000;
const WAF_FAIL_FAST_STREAK = Number(process.env.WAF_FAIL_FAST_STREAK ?? '3') || 3;
const CONFIG_ERROR =
  'UAT pre-flight config error: E2E_BASE_URL (or UAT_BASE_URL fallback) is missing or malformed.';

function resolveLiveBaseUrl(): string {
  const raw = (process.env.E2E_BASE_URL ?? process.env.UAT_BASE_URL ?? '').trim();
  if (!raw) {
    throw new Error(CONFIG_ERROR);
  }

  let parsed: URL;
  try {
    parsed = new URL(raw);
  } catch {
    throw new Error(CONFIG_ERROR);
  }

  if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
    throw new Error(CONFIG_ERROR);
  }

  return parsed.origin;
}

function errorCodes(err: unknown): string[] {
  const codes: string[] = [];
  let current: unknown = err;
  for (let depth = 0; depth < 4 && current != null; depth += 1) {
    if (typeof current === 'object' && 'code' in current) {
      const code = (current as { code?: unknown }).code;
      if (typeof code === 'string' && code.length > 0) {
        codes.push(code);
      }
    }
    current =
      typeof current === 'object' && 'cause' in current
        ? (current as { cause?: unknown }).cause
        : undefined;
  }
  return codes;
}

function classifyNetworkError(err: unknown): string {
  const codes = errorCodes(err);
  if (codes.some((code) => code === 'ECONNREFUSED')) return 'connection refused';
  if (codes.some((code) => code === 'ENOTFOUND' || code === 'EAI_AGAIN')) return 'dns';
  if (
    codes.some((code) =>
      code === 'ETIMEDOUT' ||
      code === 'UND_ERR_CONNECT_TIMEOUT' ||
      code === 'ABORT_ERR',
    )
  ) {
    return 'timeout';
  }
  if (
    codes.some((code) =>
      code === 'DEPTH_ZERO_SELF_SIGNED_CERT' ||
      code === 'UNABLE_TO_VERIFY_LEAF_SIGNATURE' ||
      code === 'CERT_HAS_EXPIRED' ||
      code === 'SELF_SIGNED_CERT_IN_CHAIN',
    )
  ) {
    return 'tls';
  }

  const msg = err instanceof Error ? err.message : String(err);
  if (msg.includes('ECONNREFUSED')) return 'connection refused';
  if (msg.includes('ENOTFOUND')) return 'dns';
  if (
    msg.includes('ETIMEDOUT') ||
    msg.includes('AbortError') ||
    msg.includes('aborted') ||
    msg.includes('timed out')
  ) {
    return 'timeout';
  }
  if (msg.includes('certificate') || msg.includes('self-signed')) return 'tls';
  return 'unknown';
}

function bodyShowsWafChallenge(body: string): boolean {
  return WAF_MARKERS.some((marker) => body.includes(marker));
}

function bodySnippet(body: string): string {
  return body.slice(0, 200).replace(/[\r\n]+/g, ' ');
}

function writeSuccessSummary(elapsedMs: number): void {
  const line = `✅ UAT pre-flight OK — /backend/health → 200 in ${elapsedMs}ms`;
  console.log(line);
  const summaryPath = process.env.GITHUB_STEP_SUMMARY;
  if (summaryPath) {
    appendFileSync(summaryPath, `${line}\n`);
  }
}

/** Fail fast when live UAT is unreachable before Playwright workers start. */
export default async function globalSetup(): Promise<void> {
  const baseUrlCandidate = process.env.E2E_BASE_URL ?? process.env.UAT_BASE_URL ?? '';
  if (!isLiveHostingTarget(baseUrlCandidate)) {
    return;
  }

  const baseURL = resolveLiveBaseUrl();
  const healthURL = `${baseURL}/backend/health`;
  const started = Date.now();
  let wafStreak = 0;

  try {
    for (let attempt = 1; attempt <= WAF_RETRY_ATTEMPTS; attempt += 1) {
      const response = await fetch(healthURL, {
        signal: AbortSignal.timeout(PREFLIGHT_TIMEOUT_MS),
      });
      const body = await response.text();

      if (bodyShowsWafChallenge(body)) {
        wafStreak += 1;
        if (wafStreak >= WAF_FAIL_FAST_STREAK) {
          throw new Error(
            `UAT pre-flight failed [waf-challenge]: ${WAF_FAIL_FAST_STREAK} consecutive WAF responses from GitHub Actions — fail-fast (cannot whitelist o2switch). Last body: ${bodySnippet(body)}`,
          );
        }
        if (attempt < WAF_RETRY_ATTEMPTS) {
          console.log(
            `UAT pre-flight WAF challenge (${wafStreak}/${WAF_FAIL_FAST_STREAK} streak, attempt ${attempt}/${WAF_RETRY_ATTEMPTS}), retrying in ${WAF_RETRY_SLEEP_MS / 1000}s...`,
          );
          await new Promise((resolve) => setTimeout(resolve, WAF_RETRY_SLEEP_MS));
          continue;
        }
        throw new Error(
          `UAT pre-flight failed [waf-challenge]: GET ${healthURL} — ${bodySnippet(body)}`,
        );
      }

      if (response.status !== 200 || !body.includes(HEALTH_OK_MARKER)) {
        throw new Error(
          `UAT pre-flight failed [${response.status}]: ${bodySnippet(body)}`,
        );
      }

      writeSuccessSummary(Date.now() - started);
      return;
    }
  } catch (err) {
    if (err instanceof Error && err.message.startsWith('UAT pre-flight')) {
      throw err;
    }
    const failureClass = classifyNetworkError(err);
    const detail = err instanceof Error ? err.message : String(err);
    throw new Error(`UAT pre-flight failed [${failureClass}]: GET ${healthURL} — ${detail}`);
  }
}
