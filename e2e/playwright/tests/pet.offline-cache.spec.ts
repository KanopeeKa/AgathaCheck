/**
 * @bdd pet_offline_cache.feature
 * Scenario: Pet list shows saved pets with an offline banner when the network fails
 * Scenario: Pet list does not show cached pets when the session is rejected
 */
import { test, loginAs } from '../fixtures/auth.fixture';
import { createPet } from '../support/api';
import { refreshFlutterAccessibility } from '../support/flutter';
import type { Page, Route } from '@playwright/test';

type PetsRouteMode = 'pass' | 'abort' | 'unauthorized';

function apiOrigin(baseURL: string): string {
  return new URL(baseURL).origin;
}

function apiPathPrefix(): string {
  const raw = process.env.E2E_API_PREFIX ?? '/backend/api';
  return raw.replace(/\/+$/, '');
}

function isPetsListRequest(url: URL, baseURL: string): boolean {
  if (url.origin !== apiOrigin(baseURL)) return false;
  const prefix = apiPathPrefix();
  const path = url.pathname;
  return path === `${prefix}/pets` || path.startsWith(`${prefix}/pets/`);
}

function isAuthRefreshRequest(url: URL, baseURL: string): boolean {
  if (url.origin !== apiOrigin(baseURL)) return false;
  return url.pathname === `${apiPathPrefix()}/auth/refresh`;
}

async function installPetsRouteHandler(
  page: Page,
  baseURL: string,
  getMode: () => PetsRouteMode,
): Promise<void> {
  const handler = async (route: Route) => {
    const url = new URL(route.request().url());
    const mode = getMode();
    if (mode === 'pass' || !isPetsListRequest(url, baseURL)) {
      await route.continue();
      return;
    }
    if (mode === 'abort') {
      await route.abort('failed');
      return;
    }
    await route.fulfill({
      status: 401,
      contentType: 'application/json',
      body: JSON.stringify({ error: 'Unauthorized' }),
    });
  };
  await page.route(
    (url) => isPetsListRequest(url, baseURL),
    handler,
  );
}

async function installUnauthorizedSessionHandler(page: Page, baseURL: string): Promise<void> {
  await page.route(
    (url) => isAuthRefreshRequest(url, baseURL),
    async (route) => {
      await route.fulfill({
        status: 401,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'Unauthorized' }),
      });
    },
  );
}

test.describe('Pet offline cache', () => {
  test('@P1 pet list shows saved pets with an offline banner when the network fails', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await createPet(baseURL, testUser.accessToken, 'Bella', 'Dog');

    let petsMode: PetsRouteMode = 'pass';
    await installPetsRouteHandler(page, baseURL, () => petsMode);

    const petList = await loginAs(page, testUser);
    await petList.expectPetVisible('Bella');

    petsMode = 'abort';
    await petList.reloadPetList();
    await petList.expectOfflineStaleBannerVisible();
    await petList.expectPetVisible('Bella');

    petsMode = 'pass';
    await petList.retryPetListLoad();
    await petList.expectOfflineStaleBannerHidden();
  });

  test('@P1 pet list does not show cached pets when the session is rejected', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await createPet(baseURL, testUser.accessToken, 'Bella', 'Dog');

    let petsMode: PetsRouteMode = 'pass';
    await installPetsRouteHandler(page, baseURL, () => petsMode);
    await installUnauthorizedSessionHandler(page, baseURL);

    const petList = await loginAs(page, testUser);
    await petList.expectPetVisible('Bella');

    petsMode = 'unauthorized';
    await page.reload();
    await refreshFlutterAccessibility(page);
    await petList.expectSessionRejected();
    await petList.expectPetHidden('Bella');
    await petList.expectOfflineStaleBannerHidden();
  });
});
