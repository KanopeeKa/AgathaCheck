import type { Page } from '@playwright/test';
import { LandingPage } from '../pages/landing.page';
import { PetListPage } from '../pages/pet-list.page';
import type { TestUser } from './api';
import { isLiveHostingTarget } from './hosting';
import { refreshFlutterAccessibility } from './flutter';
import { normalizeStoredToken } from './normalize-stored-token';

export async function readAccessTokenFromPage(page: Page): Promise<string> {
  const raw = await page.evaluate(() => {
    const keys = Object.keys(localStorage);
    for (const key of keys) {
      if (key.includes('auth_access_token')) {
        const value = localStorage.getItem(key);
        if (value) return value;
      }
    }
    return localStorage.getItem('auth_access_token');
  });
  if (!raw) {
    throw new Error('UI signup succeeded but no auth_access_token found in localStorage');
  }
  return normalizeStoredToken(raw);
}

/** Create a user through the Flutter signup form (no REST pre-seed). */
export async function signupUserViaUi(
  page: Page,
  overrides: Partial<{
    email: string;
    password: string;
    firstName: string;
    lastName: string;
  }> = {},
): Promise<TestUser> {
  const suffix = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  const email = overrides.email ?? `e2e-${suffix}@example.com`;
  const password = overrides.password ?? 'E2eTestPass1';
  const firstName = overrides.firstName ?? 'E2E';
  const lastName = overrides.lastName ?? 'User';

  const landing = new LandingPage(page);
  await landing.goto();
  await landing.signupAndReachHome({ firstName, lastName, email, password });

  await refreshFlutterAccessibility(page);
  const petList = new PetListPage(page);
  await petList.expectLoaded();

  const accessToken = await readAccessTokenFromPage(page);
  return {
    email,
    password,
    firstName,
    lastName,
    accessToken,
    userId: '',
  };
}

export async function createTestUser(
  page: Page,
  baseURL: string,
  overrides: Partial<{
    email: string;
    password: string;
    firstName: string;
    lastName: string;
  }> = {},
): Promise<TestUser> {
  const { signupUser, getCurrentUser } = await import('./api');

  if (!isLiveHostingTarget(baseURL)) {
    return signupUser(baseURL, overrides);
  }

  // Track the first successful API signup even when verification fails.
  // If getCurrentUser is blocked (WAF, cold-start) but the account was created,
  // use that user rather than falling back to UI signup which can be blocked by
  // the consent banner, form latency, or other live-UAT issues.
  let firstCreatedUser: TestUser | null = null;
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const user = await signupUser(baseURL, overrides);
      if (!firstCreatedUser) firstCreatedUser = user;
      const profile = await getCurrentUser(baseURL, user.accessToken);
      if (profile?.email === user.email) {
        return user;
      }
    } catch (err) {
      console.warn(
        `[createTestUser] browser-fetch attempt ${attempt + 1}/3 failed:`,
        err instanceof Error ? err.message : String(err),
      );
    }
    await page.waitForTimeout(1_500);
  }

  // Prefer the API-created user when available: avoids WAF / consent-banner
  // pitfalls in the UI signup path that can leave the browser on /landing.
  if (firstCreatedUser) return firstCreatedUser;

  return signupUserViaUi(page, overrides);
}
