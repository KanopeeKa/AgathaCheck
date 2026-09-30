import type { Page, Route } from '@playwright/test';

type ClockRoute = {
  matches: (url: URL) => boolean;
  handle: (route: Route) => Promise<void>;
};
const clockRoutes = new WeakMap<Page, ClockRoute>();

/** Never send the test clock to Flutter assets, fonts or third-party CDNs. */
export async function setPageCareClock(
  page: Page,
  clock: string | null,
  apiBaseUrl = new URL(
    process.env.E2E_API_PREFIX ?? '/backend/api',
    process.env.E2E_BASE_URL ?? 'http://localhost:3000',
  ).href,
): Promise<void> {
  const previous = clockRoutes.get(page);
  if (previous) {
    clockRoutes.delete(page);
    try {
      if (!page.isClosed()) await page.unroute(previous.matches, previous.handle);
    } catch (error) {
      // A timeout can close the page during cleanup. Preserve the original
      // failure; errors on a live page must still propagate.
      if (!page.isClosed()) throw error;
    }
  }
  if (clock === null) return;

  const api = new URL(apiBaseUrl);
  const prefix = api.pathname.replace(/\/+$/, '');
  const registration: ClockRoute = {
    matches: (url) => url.origin === api.origin
      && (url.pathname === prefix || url.pathname.startsWith(`${prefix}/`)),
    handle: async (route) => {
      await route.fallback({
        headers: { ...await route.request().allHeaders(), 'x-care-as-of': clock },
      });
    },
  };
  await page.route(registration.matches, registration.handle);
  clockRoutes.set(page, registration);
}