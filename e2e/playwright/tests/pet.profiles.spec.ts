/**
 * @bdd pet_profiles.feature
 * Scenario: Empty pet list shows prompt
 * Scenario: Creating a new pet with required fields
 * Scenario: Viewing pet details
 * Scenario: Editing a pet's name
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { createPet } from '../support/api';
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

  test('user can create a pet with required fields', async ({ page, testUser }) => {
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
});
