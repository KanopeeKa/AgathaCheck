function resolveCandidate(baseURL?: string): string {
  return (baseURL ?? process.env.E2E_BASE_URL ?? '').trim();
}

/** Hostname from a base URL or host-like string; null if empty/unparseable. */
function hostnameOf(baseURL?: string): string | null {
  const raw = resolveCandidate(baseURL);
  if (!raw) return null;
  try {
    const withScheme = /^[a-z][a-z0-9+.-]*:/i.test(raw) ? raw : `https://${raw}`;
    return new URL(withScheme).hostname.toLowerCase();
  } catch {
    return null;
  }
}

/** Live production: agathatrack.com / www — not UAT. */
export function isLiveProdTarget(baseURL?: string): boolean {
  const host = hostnameOf(baseURL);
  return host === 'agathatrack.com' || host === 'www.agathatrack.com';
}

/** Live UAT: uat.agathatrack.com — WAF, E2E bypass, Basic Auth, stealth. */
export function isLiveUatTarget(baseURL?: string): boolean {
  const host = hostnameOf(baseURL);
  return host === 'uat.agathatrack.com';
}

/**
 * Any live Agatha Track host (*.agathatrack.com).
 * Prefer isLiveUatTarget / isLiveProdTarget for host-specific behavior;
 * keep this for shared “any live host” concerns (e.g. longer timeouts).
 */
export function isLiveHostingTarget(baseURL?: string): boolean {
  const host = hostnameOf(baseURL);
  return host != null && /(^|\.)agathatrack\.com$/i.test(host);
}
