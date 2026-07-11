const LIVE_HOST_PATTERN = /agathatrack\.com/i;

export function isLiveHostingTarget(baseURL?: string): boolean {
  const url = baseURL ?? process.env.E2E_BASE_URL ?? '';
  return LIVE_HOST_PATTERN.test(url);
}
