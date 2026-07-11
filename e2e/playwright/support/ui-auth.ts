import type { Page } from '@playwright/test';
import { LandingPage } from '../pages/landing.page';
import { PetListPage } from '../pages/pet-list.page';
import type { TestUser } from './api';
import { isLiveHostingTarget } from './hosting';

async function readAccessToken(page: Page): Promise<string> {
  const token = await page.evaluate(() => {
    const keys = Object.keys(localStorage);
    for (const key of keys) {
      if (key.includes('auth_access_token')) {
        const value = localStorage.getItem(key);
        if (value) return value;
      }
    }
    return localStorage.getItem('auth_access_token');
  });
  if (!token) {
    throw new Error('UI signup succeeded but no auth_access_token found in localStorage');
  }
  return token;
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
  await landing.signup({ firstName, lastName, email, password });

  const petList = new PetListPage(page);
  await petList.expectLoaded();

  const accessToken = await readAccessToken(page);
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
  if (!isLiveHostingTarget(baseURL)) {
    const { signupUser } = await import('./api');
    return signupUser(baseURL, overrides);
  }

  const { signupUser } = await import('./api');
  try {
    return await signupUser(baseURL, overrides);
  } catch {
    return signupUserViaUi(page, overrides);
  }
}
