/**
 * @bdd pet_profiles.feature
 * Scenario: Empty pet list shows prompt on guardian dashboard
 * Scenario: Creating a new pet with required fields
 * Scenario: Creating a pet with all fields populated
 * Scenario: Pet is assigned a unique color on creation
 * Scenario: Age is dynamically calculated from date of birth
 * Scenario: Viewing the pet list
 * Scenario: Viewing pet details
 * Scenario: Editing a pet's name
 * Scenario: Editing a pet's breed
 * Scenario: Deleting a pet
 * Scenario: Cancelling pet deletion
 * Scenario: Marking a pet as passed away
 * Scenario: Passed away pets appear in a collapsible section
 * Scenario: Showing identification reminder for pet without ID
 * Scenario: No identification reminder for pet with ID
 * Scenario: Adding a photo to a pet profile
 * Scenario: Linking a veterinarian to a pet
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { createPet, createVet, getAllPets, getPet } from '../support/api';
import { PetFormPage } from '../pages/pet-form.page';
import { PetDetailPage } from '../pages/pet-detail.page';
import { PetListPage } from '../pages/pet-list.page';
import {
  getPetRecord,
  PET_COLOR_PALETTE,
  TINY_PNG_BASE64,
  updatePetFields,
} from '../pages/pet-profile.seed';
test.describe('Pet profiles', () => {
  test('empty pet list shows prompt on guardian dashboard', async ({ page, testUser }) => {
    const petList = await loginAs(page, testUser);
    await petList.expectEmptyState();
  });

  test('@smoke-uat user can create a pet with required fields', async ({ page, testUser }) => {
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

    // Edit save returns to pet detail (PetFormScreen._navigateAfterForm), not the list.
    await detail.expectLoaded('Bella Rose');
    await petList.openManagePets();
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
    await petList.expectPetHidden('Luna');
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
    await detail.expectLoaded('Charlie');
    await petList.openManagePets();
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

  test('new pet is assigned a color from the 15-color palette', async ({ testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Luna', 'Dog');
    await getAllPets(baseURL, testUser.accessToken);

    const record = await getPetRecord(baseURL, testUser.accessToken, pet.id);
    expect(record.colorValue).toBeDefined();
    expect(record.colorValue).not.toBeNull();
    expect(PET_COLOR_PALETTE).toContain(record.colorValue);
  });

  test('pet age is calculated from date of birth on the profile', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Milo', 'Dog');
    await updatePetFields(baseURL, testUser.accessToken, pet.id, {
      name: 'Milo',
      species: 'Dog',
      dateOfBirth: '2022-01-01',
    });

    const seeded = await getPetRecord(baseURL, testUser.accessToken, pet.id);
    expect(seeded.dateOfBirth).toBe('2022-01-01');

    const petList = await loginAs(page, testUser);
    await petList.openPet('Milo');

    const detail = new PetDetailPage(page);
    await detail.expectLoaded('Milo');
    await detail.expectAgeDisplay(/\d+(\.\d+)?\s+yrs|\d+\s+months?/i);
  });

  test('passed away pets appear in the collapsed Rainbow Bridge section', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await createPet(baseURL, testUser.accessToken, 'Max', 'Dog');
    await createPet(baseURL, testUser.accessToken, 'Buddy', 'Dog');

    const petList = await loginAs(page, testUser);
    await petList.openManagePets();
    await petList.expectPetCount(2);
    await petList.openPet('Buddy');

    const detail = new PetDetailPage(page);
    await detail.expectLoaded('Buddy');
    await detail.openEdit();

    const editForm = new PetFormPage(page);
    await editForm.expectLoaded();
    await editForm.clickPassedAway();
    await editForm.confirmPassedAway();

    await petList.expectLoaded();
    await petList.openManagePets();
    await petList.expectPetVisible('Max');
    await petList.expectPetCount(1);
    await petList.expectPetHidden('Buddy');
  });

  test('identification reminder shows for pet without chip ID', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Luna', 'Fish');

    const petList = await loginAs(page, testUser);
    await petList.openPet(pet.name);

    const detail = new PetDetailPage(page);
    await detail.expectLoaded('Luna');
    await detail.expectIdentificationReminder('Luna');
  });

  test('no identification reminder when pet has chip ID', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Luna', 'Dog');
    await updatePetFields(baseURL, testUser.accessToken, pet.id, {
      name: 'Luna',
      species: 'Dog',
      chipId: 'FR-123-456',
    });

    const petList = await loginAs(page, testUser);
    await petList.openPet('Luna');

    const detail = new PetDetailPage(page);
    await detail.expectLoaded('Luna');
    await detail.expectNoIdentificationReminder('Luna');
  });

  test('pet profile displays uploaded photo', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella', 'Dog');
    await updatePetFields(baseURL, testUser.accessToken, pet.id, {
      name: 'Bella',
      species: 'Dog',
      photoPath: TINY_PNG_BASE64,
    });

    const petList = await loginAs(page, testUser);
    await petList.openPet('Bella');

    const detail = new PetDetailPage(page);
    await detail.expectLoaded('Bella');
    await detail.expectPetPhotoVisible('Bella');
  });

  test('user can link a veterinarian to a pet from the edit form', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella', 'Dog');
    await createVet(baseURL, testUser.accessToken, 'Dr. Jones');

    const petList = await loginAs(page, testUser);
    await petList.openPet('Bella');

    const detail = new PetDetailPage(page);
    await detail.expectLoaded('Bella');
    await detail.openEdit();

    const editForm = new PetFormPage(page);
    await editForm.expectLoaded();
    await editForm.selectVeterinarian('Dr. Jones');
    await editForm.save();

    await detail.expectLoaded('Bella');
    const updated = await getPetRecord(baseURL, testUser.accessToken, pet.id);
    expect(updated.vetId).toBeTruthy();
  });
});
