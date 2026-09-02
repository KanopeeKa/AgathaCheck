/**
 * @bdd sharing.feature
 * Scenario: Creating a share link for a pet
 * Scenario: Viewing a shared pet without being logged in
 * Scenario: Viewing a shared pet's health entries
 * Scenario: Viewing a shared pet's vet information
 * Scenario: Viewing owner information on shared pet page
 * Scenario: Accepting a share into personal pet list
 * Scenario: Opening an expired or invalid share link
 * Scenario: Hiding a shared pet via swipe
 * Scenario: Pending share appears in pet list
 * Scenario: Accepting a pending share into personal list
 * Scenario: Accepting a pending share into an organisation
 * Scenario: Declining a pending share
 * Scenario: Unhiding a shared pet
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  acceptShareByCode,
  createHealthEntry,
  createPet,
  createShareLink,
  createVet,
  hideFosteredPet,
  seedOrgWithMember,
  signupUser,
  updatePetVet,
} from '../support/api';
import {
  acceptPendingShareApi,
  declinePendingShareApi,
  fetchPendingShares,
} from '../pages/pet-profile.seed';
import { checkA11y } from '../support/axe';
import { clearLiveApiAccess, prepareLiveApiAccess } from '../support/waf';
import { clearBrowserSessionState } from '../support/session';
import { createTestUser } from '../support/ui-auth';
import { PetDetailPage } from '../pages/pet-detail.page';
import { PetListPage } from '../pages/pet-list.page';
import { refreshFlutterAccessibility, flutterGotoUrl } from '../support/flutter';
import { SharedPetPage } from '../pages/shared-pet.page';

test.describe('Pet sharing', () => {
  test('@smoke-ci @smoke-uat anonymous user can view a shared pet profile', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await prepareLiveApiAccess(page, baseURL);
    try {
      const owner = await createTestUser(page, baseURL, { firstName: 'Alice', lastName: 'Owner' });
      const pet = await createPet(baseURL, owner.accessToken, 'Bella', 'Dog');
      const link = await createShareLink(baseURL, owner.accessToken, pet.id);

      await clearBrowserSessionState(page);
      await prepareLiveApiAccess(page, baseURL);

      const sharedPet = new SharedPetPage(page);
      await sharedPet.goto(link.share_code);
      await sharedPet.expectLoaded('Bella');
      await sharedPet.expectViewOnlyBadge();
      await sharedPet.expectSpecies('Dog');
    } finally {
      clearLiveApiAccess();
    }
  });

  test('@smoke-a11y @smoke-uat shared pet preview passes axe accessibility scan', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await prepareLiveApiAccess(page, baseURL);
    try {
      const owner = await createTestUser(page, baseURL, { firstName: 'Alice', lastName: 'Owner' });
      const pet = await createPet(baseURL, owner.accessToken, 'Bella', 'Dog');
      const link = await createShareLink(baseURL, owner.accessToken, pet.id);

      await clearBrowserSessionState(page);
      await prepareLiveApiAccess(page, baseURL);

      const sharedPet = new SharedPetPage(page);
      await sharedPet.goto(link.share_code);
      await sharedPet.expectLoaded('Bella');
      await checkA11y(page, 'shared pet preview');
    } finally {
      clearLiveApiAccess();
    }
  });

  test('owner can create a share link from the pet detail screen', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella', 'Dog');

    const petList = await loginAs(page, testUser);
    await petList.openPet('Bella', pet.id);

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

  test('@legacy pending share API returns empty and pet list has no pending section', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pending = await fetchPendingShares(baseURL, testUser.accessToken);
    expect(pending).toEqual([]);

    const petList = await loginAs(page, testUser);
    await petList.openManagePets();
    await petList.expectNoPendingSharesSection();
  });

  test('accepting a share link adds pet to personal list (pending-flow equivalent)', async ({
    page,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const owner = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
    const pet = await createPet(baseURL, owner.accessToken, 'Bella', 'Dog');
    const link = await createShareLink(baseURL, owner.accessToken, pet.id);
    const bob = await signupUser(baseURL, { firstName: 'Bob', lastName: 'Follower' });

    await loginAs(page, bob);
    const sharedPet = new SharedPetPage(page);
    await sharedPet.goto(link.share_code);
    await sharedPet.acceptShare();

    const petList = new PetListPage(page);
    await petList.expectLoaded();
    await petList.expectPetVisible('Bella');
  });

  test('@legacy accepting pending share into organisation returns deprecated status', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const owner = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
    const bob = await signupUser(baseURL, { firstName: 'Bob', lastName: 'Member' });
    const org = await seedOrgWithMember(baseURL, owner, bob, 'Pet Care Team');
    const pet = await createPet(baseURL, owner.accessToken, 'Bella', 'Dog');

    const status = await acceptPendingShareApi(baseURL, bob.accessToken, pet.id, org.id);
    expect(status).toBe(410);
  });

  test('@legacy declining pending share returns deprecated status', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const owner = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
    const bob = await signupUser(baseURL, { firstName: 'Bob', lastName: 'Follower' });
    const pet = await createPet(baseURL, owner.accessToken, 'Bella', 'Dog');

    const status = await declinePendingShareApi(baseURL, bob.accessToken, pet.id);
    expect(status).toBe(410);
    const pending = await fetchPendingShares(baseURL, bob.accessToken);
    expect(pending).toEqual([]);
  });

  test('user can unhide a previously hidden shared pet', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const owner = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
    const bob = await signupUser(baseURL, { firstName: 'Bob', lastName: 'Follower' });
    const pet = await createPet(baseURL, owner.accessToken, 'Bella', 'Dog');
    const link = await createShareLink(baseURL, owner.accessToken, pet.id);
    await acceptShareByCode(baseURL, bob.accessToken, link.share_code);
    await hideFosteredPet(baseURL, bob.accessToken, pet.id, true);
    await hideFosteredPet(baseURL, bob.accessToken, pet.id, false);

    await loginAs(page, bob);
    await page.goto(flutterGotoUrl('/pc/pets'));
    await refreshFlutterAccessibility(page);
    const petList = new PetListPage(page);
    await petList.expectLoaded();
    await petList.expectPetVisible('Bella');
  });
});
