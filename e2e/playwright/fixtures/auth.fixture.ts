import { test as base, expect } from '@playwright/test';
import { createHealthEntry, createPet, signupUser, type TestUser } from '../support/api';
import { LandingPage } from '../pages/landing.page';
import { PetListPage } from '../pages/pet-list.page';

type AuthFixtures = {
  testUser: TestUser;
  landingPage: LandingPage;
  petListPage: PetListPage;
};

export const test = base.extend<AuthFixtures>({
  testUser: async ({}, use) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const user = await signupUser(baseURL);
    await use(user);
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
  await landing.goto();
  await landing.login(user.email, user.password);
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
