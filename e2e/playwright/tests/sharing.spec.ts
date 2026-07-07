/**
 * @bdd sharing.feature
 * Scenario: Creating a share link for a pet
 * Scenario: Viewing a shared pet without being logged in
 * Scenario: Viewing a shared pet's health entries
 * Scenario: Viewing a shared pet's vet information
 * Scenario: Viewing owner information on shared pet page
 * Scenario: Accepting a share into personal pet list
 * Scenario: Opening an expired or invalid share link
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  createHealthEntry,
  createPet,
  createShareLink,
  createVet,
  signupUser,
  updatePetVet,
} from '../support/api';
import { checkA11y } from '../support/axe';
import { PetDetailPage } from '../pages/pet-detail.page';
import { PetListPage } from '../pages/pet-list.page';
import { SharedPetPage } from '../pages/shared-pet.page';

test.describe('Pet sharing', () => {
  test('@smoke anonymous user can view a shared pet profile', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const owner = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
    const pet = await createPet(baseURL, owner.accessToken, 'Bella', 'Dog');
    const link = await createShareLink(baseURL, owner.accessToken, pet.id);

    const sharedPet = new SharedPetPage(page);
    await sharedPet.goto(link.share_code);
    await sharedPet.expectLoaded('Bella');
    await sharedPet.expectViewOnlyBadge();
    await sharedPet.expectSpecies('Dog');
    await checkA11y(page, 'shared pet preview');
  });

  test('owner can create a share link from the pet detail screen', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await createPet(baseURL, testUser.accessToken, 'Bella', 'Dog');

    const petList = await loginAs(page, testUser);
    await petList.openPet('Bella');

    const detail = new PetDetailPage(page);
    await detail.expectLoaded('Bella');
    await detail.createShareLink();
  });

  test('shared pet page shows health entries and owner name', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const owner = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
    const pet = await createPet(baseURL, owner.accessToken, 'Bella', 'Dog');
    await createHealthEntry(baseURL, owner.accessToken, pet.id, {
      name: 'Vaccination',
      nextDueDate: new Date().toISOString().slice(0, 10),
    });
    const link = await createShareLink(baseURL, owner.accessToken, pet.id);

    const sharedPet = new SharedPetPage(page);
    await sharedPet.goto(link.share_code);
    await sharedPet.expectLoaded('Bella');
    await sharedPet.expectOwnerName('Alice Owner');
    await sharedPet.expectHealthEntry('Vaccination');
  });

  test('shared pet page shows linked veterinarian', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const owner = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
    const pet = await createPet(baseURL, owner.accessToken, 'Bella', 'Dog');
    const vet = await createVet(baseURL, owner.accessToken, 'Dr. Smith');
    await updatePetVet(baseURL, owner.accessToken, pet.id, {
      name: 'Bella',
      species: 'Dog',
      vetId: vet.id,
    });
    const link = await createShareLink(baseURL, owner.accessToken, pet.id);

    const sharedPet = new SharedPetPage(page);
    await sharedPet.goto(link.share_code);
    await sharedPet.expectLoaded('Bella');
    await sharedPet.expectVet('Dr. Smith');
  });

  test('logged-in user can accept a share into their pet list', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const owner = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
    const pet = await createPet(baseURL, owner.accessToken, 'Bella', 'Dog');
    const link = await createShareLink(baseURL, owner.accessToken, pet.id);
    const bob = await signupUser(baseURL, { firstName: 'Bob', lastName: 'Follower' });

    await loginAs(page, bob);

    const sharedPet = new SharedPetPage(page);
    await sharedPet.goto(link.share_code);
    await sharedPet.expectLoaded('Bella');
    await sharedPet.acceptShare();

    const petList = new PetListPage(page);
    await petList.expectLoaded();
    await petList.expectPetVisible('Bella');
    await expect(page.getByText('Share accepted')).toBeVisible();
  });

  test('invalid share link shows an error with navigation home', async ({ page }) => {
    const sharedPet = new SharedPetPage(page);
    await sharedPet.goto('not-a-real-share-code');
    await sharedPet.expectInvalidLink();
  });
});
