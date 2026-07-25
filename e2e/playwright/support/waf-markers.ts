export const WAF_MARKERS = ['o2s-browser-check', 'Security check', 'Test de sécurité'] as const;

export function bodyShowsWafChallenge(body: string): boolean {
  return WAF_MARKERS.some((marker) => body.includes(marker));
}
