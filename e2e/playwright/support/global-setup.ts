// requires Node ≥ 18 (fetch + AbortSignal.timeout)

import { appendFileSync } from 'node:fs';
import { isLiveHostingTarget } from './hosting';

const WAF_MARKERS = ['o2s-browser-check', 'Security check', 'Test de sécurité'];
const HEALTH_OK_MARKER = '"status":"OK"';
const PREFLIGHT_TIMEOUT_MS = 15_000;
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
  for (let depth = 0; depth < 4 && current; depth += 1) {
    if (current && typeof current === 'object' && 'code' in current) {
      const code = (current as { code?: unknown }).code;
      if (typeof code === 'string' && code.length > 0) {
        codes.push(code);
      }
    }
    current =
      current && typeof current === 'object' && 'cause' in current
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

  try {
    const response = await fetch(healthURL, {
      signal: AbortSignal.timeout(PREFLIGHT_TIMEOUT_MS),
    });
    const body = await response.text();
    const elapsedMs = Date.now() - started;

    if (bodyShowsWafChallenge(body)) {
      throw new Error(
        `UAT pre-flight failed [waf-challenge]: GET ${healthURL} — ${bodySnippet(body)}`,
      );
    }

    if (response.status !== 200 || !body.includes(HEALTH_OK_MARKER)) {
      throw new Error(
        `UAT pre-flight failed [${response.status}]: ${bodySnippet(body)}`,
      );
    }

    writeSuccessSummary(elapsedMs);
  } catch (err) {
    if (err instanceof Error && err.message.startsWith('UAT pre-flight')) {
      throw err;
    }
    const failureClass = classifyNetworkError(err);
    const detail = err instanceof Error ? err.message : String(err);
    throw new Error(`UAT pre-flight failed [${failureClass}]: GET ${healthURL} — ${detail}`);
  }
}
