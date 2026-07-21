import { isLiveHostingTarget } from './hosting';

export const E2E_BYPASS_HEADER = 'X-E2E-Bypass-Token';

/** Headers for audited CI bypass of UAT auth rate limits (when secret is configured). */
export function e2eBypassHeadersForUrl(url: string): Record<string, string> {
  const token = process.env.E2E_BYPASS_TOKEN?.trim();
  if (!token || !isLiveHostingTarget(url)) {
    return {};
  }
  return { [E2E_BYPASS_HEADER]: token };
}
