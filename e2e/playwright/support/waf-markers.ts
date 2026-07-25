export const WAF_MARKERS = ['o2s-browser-check', 'Security check', 'Test de sécurité'] as const;

export function bodyShowsWafChallenge(body: string): boolean {
  return WAF_MARKERS.some((marker) => body.includes(marker));
}

/** Classify an invalid-body signup probe — JSON 4xx = app reachable; WAF HTML = not ready. */
export function authSignupProbeReachable(
  status: number,
  body: string,
): 'ok' | 'waf' | 'down' {
  if (bodyShowsWafChallenge(body)) {
    return 'waf';
  }
  if (status === 400 && body.includes('"error"')) {
    return 'ok';
  }
  if (status >= 400 && status < 500 && body.trimStart().startsWith('{') && body.includes('"error"')) {
    return 'ok';
  }
  return 'down';
}
