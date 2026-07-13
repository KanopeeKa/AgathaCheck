import { test as base, expect } from '@playwright/test';
import { createHealthEntry, createPet, type TestUser } from '../support/api';
import { applyLiveHostingStealth } from '../support/stealth';
import { createTestUser } from '../support/ui-auth';
import { clearLiveApiAccess, passHostingWaf, prepareLiveApiAccess, resetHostingWafSession } from '../support/waf';
import { isLiveHostingTarget } from '../support/hosting';
import { LandingPage } from '../pages/landing.page';
import { PetListPage } from '../pages/pet-list.page';
import { refreshFlutterAccessibility } from '../support/flutter';

type AuthFixtures = {
  testUser: TestUser;
  landingPage: LandingPage;
  petListPage: PetListPage;
};

export const test = base.extend<AuthFixtures>({
  context: async ({ context }, use) => {
    await applyLiveHostingStealth(context);
    await use(context);
  },

  testUser: async ({ page }, use) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await prepareLiveApiAccess(page, baseURL);
    try {
      const user = await createTestUser(page, baseURL);
      await use(user);
    } finally {
      clearLiveApiAccess();
    }
  },

  landingPage: async ({ page }, use) => {
    await use(new LandingPage(page));
  },

  petListPage: async ({ page }, use) => {
    await use(new PetListPage(page));
  },
});

export { expect };

export async function loginAs(page: import('@playwright/test').Page, user: TestUser): Promise<PetListPage> {
  const landing = new LandingPage(page);
  const petList = new PetListPage(page);
  const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
  await page.context().clearCookies();
  if (isLiveHostingTarget(baseURL)) {
    resetHostingWafSession();
  }
  await page.goto('/');
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
  if (isLiveHostingTarget(baseURL)) {
    await passHostingWaf(page, baseURL);
  }
  await landing.goto();
  await landing.login(user.email, user.password);
  await refreshFlutterAccessibility(page);
  await petList.expectLoaded();
  return petList;
}

export async function seedPetWithDueHealthEntry(
  baseURL: string,
  user: TestUser,
  options: { petName?: string; entryName?: string; dueDate?: string; frequency?: string } = {},
) {
  const petName = options.petName ?? 'Bella';
  const entryName = options.entryName ?? 'Heartworm Prevention';
  const dueDate = options.dueDate ?? new Date().toISOString().slice(0, 10);

  const pet = await createPet(baseURL, user.accessToken, petName);
  const entry = await createHealthEntry(baseURL, user.accessToken, pet.id, {
    name: entryName,
    nextDueDate: dueDate,
    frequency: options.frequency,
  });
  return { pet, entry };
}
