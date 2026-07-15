/**
 * @bdd pet_profiles.feature
 * Scenario: Empty pet list shows prompt
 * Scenario: Creating a new pet with required fields
 * Scenario: Creating a pet with all fields populated
 * Scenario: Viewing the pet list
 * Scenario: Viewing pet details
 * Scenario: Editing a pet's name
 * Scenario: Editing a pet's breed
 * Scenario: Deleting a pet
 * Scenario: Cancelling pet deletion
 * Scenario: Marking a pet as passed away
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { createPet, getPet } from '../support/api';
import { PetFormPage } from '../pages/pet-form.page';
import { PetDetailPage } from '../pages/pet-detail.page';
import { PetListPage } from '../pages/pet-list.page';

test.describe('Pet profiles', () => {
  test('empty pet list shows prompt and add button', async ({ page, testUser }) => {
    const petList = await loginAs(page, testUser);
    await petList.expectEmptyState();
    await expect(page.getByText('No pets yet')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Add Pet' })).toBeVisible();
  });

  test('@smoke user can create a pet with required fields', async ({ page, testUser }) => {
    const petList = await loginAs(page, testUser);
    await petList.openAddPet();

    const form = new PetFormPage(page);
    await form.createPet('Bella', 'Dog');

    await petList.expectLoaded();
    await petList.expectPetVisible('Bella');
  });

  test('user can view pet details from the list', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await createPet(baseURL, testUser.accessToken, 'Bella', 'Dog');

    const petList = await loginAs(page, testUser);
    await petList.expectPetVisible('Bella');
    await petList.openPet('Bella');

    const detail = new PetDetailPage(page);
    await detail.expectLoaded('Bella');
    await detail.expectSpecies('Dog');
  });

  test('user can view the pet list with multiple pets', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await createPet(baseURL, testUser.accessToken, 'Bella', 'Dog');
    await createPet(baseURL, testUser.accessToken, 'Max', 'Cat');
    await createPet(baseURL, testUser.accessToken, 'Luna', 'Dog');

    const petList = await loginAs(page, testUser);
    await petList.expectLoaded();
    await petList.expectPetCount(3);
    await petList.expectPetVisible('Bella');
    await petList.expectPetVisible('Max');
    await petList.expectPetVisible('Luna');
  });

  test('user can edit a pet name', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await createPet(baseURL, testUser.accessToken, 'Bella', 'Dog');

    const petList = await loginAs(page, testUser);
    await petList.openPet('Bella');

    const detail = new PetDetailPage(page);
    await detail.expectLoaded('Bella');
    await detail.openEdit();

    const editForm = new PetFormPage(page);
    await editForm.expectLoaded();
    await editForm.fillName('Bella Rose');
    await editForm.save();

    await petList.expectLoaded();
    await petList.expectPetVisible('Bella Rose');
  });

  test('user can create a pet with all key optional fields populated', async ({
    page,
    testUser,
  }) => {
    const petList = await loginAs(page, testUser);
    await petList.openAddPet();

    const form = new PetFormPage(page);
    await form.expectLoaded();
    await form.selectSpecies('Dog');
    await page.waitForTimeout(300);
    await form.fillName('Rex');
    await form.fillBreed('Labrador Retriever');
    await form.save();

    await petList.expectLoaded();
    await petList.expectPetVisible('Rex');
  });

  test('user can edit a pet breed', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Max', 'Dog');

    const petList = await loginAs(page, testUser);
    await petList.openPet('Max');

    const detail = new PetDetailPage(page);
    await detail.expectLoaded('Max');
    await detail.openEdit();

    const editForm = new PetFormPage(page);
    await editForm.expectLoaded();
    await editForm.fillBreed('Golden Retriever');
    await editForm.save();

    const updated = await getPet(baseURL, testUser.accessToken, pet.id);
    expect(updated.breed).toBe('Golden Retriever');
  });

  test('user can delete a pet and it is removed from the list', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await createPet(baseURL, testUser.accessToken, 'Luna', 'Cat');

    const petList = await loginAs(page, testUser);
    await petList.openPet('Luna');

    const detail = new PetDetailPage(page);
    await detail.expectLoaded('Luna');
    await detail.openEdit();

    const editForm = new PetFormPage(page);
    await editForm.expectLoaded();
    await editForm.clickDeletePet();
    await editForm.confirmDelete();

    await petList.expectLoaded();
    await expect(
      page.getByRole('button', { name: /Pet:\s*Luna/i }),
    ).not.toBeVisible();
  });

  test('user can cancel pet deletion and the pet remains in the list', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await createPet(baseURL, testUser.accessToken, 'Charlie', 'Dog');

    const petList = await loginAs(page, testUser);
    await petList.openPet('Charlie');

    const detail = new PetDetailPage(page);
    await detail.expectLoaded('Charlie');
    await detail.openEdit();

    const editForm = new PetFormPage(page);
    await editForm.expectLoaded();
    await editForm.clickDeletePet();
    await editForm.cancelDelete();

    // Save without changes and confirm pet still exists
    await editForm.save();
    await petList.expectLoaded();
    await petList.expectPetVisible('Charlie');
  });

  test('user can mark a pet as passed away', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await createPet(baseURL, testUser.accessToken, 'Shadow', 'Dog');

    const petList = await loginAs(page, testUser);
    await petList.openPet('Shadow');

    const detail = new PetDetailPage(page);
    await detail.expectLoaded('Shadow');
    await detail.openEdit();

    const editForm = new PetFormPage(page);
    await editForm.expectLoaded();
    await editForm.clickPassedAway();
    await editForm.confirmPassedAway();

    // After confirming, we are redirected to the pet list
    await petList.expectLoaded();
  });
});
