import type { Page } from '@playwright/test';

/**
 * Clear cookies and browser storage for a fresh anonymous session.
 * Navigates to `/` first so `localStorage`/`sessionStorage` are reachable
 * (they throw on `about:blank` when tests seed via REST without navigating).
 */
export async function clearBrowserSessionState(page: Page): Promise<void> {
  await page.context().clearCookies();
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await page.evaluate(async () => {
    window.localStorage.clear();
    window.sessionStorage.clear();
    if ('indexedDB' in window && typeof indexedDB.databases === 'function') {
      const databases = await indexedDB.databases();
      await Promise.all(
        databases
          .map((db) => db.name)
          .filter((name): name is string => Boolean(name))
          .map((name) => new Promise<void>((resolve) => {
            const request = indexedDB.deleteDatabase(name);
            request.onsuccess = () => resolve();
            request.onerror = () => resolve();
            request.onblocked = () => resolve();
          })),
      );
    }
  });
}
