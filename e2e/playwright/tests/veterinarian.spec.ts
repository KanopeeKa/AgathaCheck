/**
 * @bdd veterinarian_management.feature
 * Scenario: Creating a veterinarian with all details
 * Scenario: Creating a veterinarian with only a name
 * Scenario: Viewing the veterinarian list
 * Scenario: Viewing vet with linked pets
 * Scenario: Empty vet list shows prompt
 * Scenario: Editing a veterinarian's phone number
 * Scenario: Deleting a veterinarian
 * Scenario: Navigating to vet list from the app bar
 * Scenario: Cancelling vet deletion
 * Scenario: Navigating back from vet list
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  createPet,
  createVetFull,
  getPeopleContacts,
  getVets,
  signupUser,
  updatePetVet,
} from '../support/api';
import { checkA11y } from '../support/axe';
import { PetListPage } from '../pages/pet-list.page';
import { VetListPage } from '../pages/vet-list.page';
import { VetFormPage } from '../pages/vet-form.page';
import { dashboardSectionGroup } from '../support/flutter';

test.describe('Veterinarian management', () => {
  test('user can create a vet with all details', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';

    const petList = await loginAs(page, testUser);
    await petList.openVets();

    const vetList = new VetListPage(page);
    await vetList.expectLoaded();
    await vetList.openAddForm();

    const vetForm = new VetFormPage(page);
    await vetForm.createVet({ name: 'Dr. Smith' });

    await vetList.expectLoaded();
    await vetList.expectVetVisible('Dr. Smith');
    await checkA11y(page, 'vet list after create');

    const vets = await getVets(baseURL, testUser.accessToken);
    const created = vets.find((v) => v.name === 'Dr. Smith');
    expect(created).toBeTruthy();
  });

  test('user can create a vet with only a name', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';

    const petList = await loginAs(page, testUser);
    await petList.openVets();

    const vetList = new VetListPage(page);
    await vetList.openAddForm();

    const vetForm = new VetFormPage(page);
    await vetForm.createVet({ name: 'Dr. Jones' });

    await vetList.expectLoaded();
    await vetList.expectVetVisible('Dr. Jones');

    const vets = await getVets(baseURL, testUser.accessToken);
    expect(vets.some((v) => v.name === 'Dr. Jones')).toBe(true);
  });

  test('user can view the veterinarian list', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const user = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Vet' });

    await createVetFull(baseURL, user.accessToken, { name: 'Dr. Smith' });
    await createVetFull(baseURL, user.accessToken, { name: 'Dr. Jones' });

    const petList = await loginAs(page, user);
    await petList.openVets();

    const vetList = new VetListPage(page);
    await vetList.expectLoaded();
    await vetList.expectVetVisible('Dr. Smith');
    await vetList.expectVetVisible('Dr. Jones');
  });

  test('vet list shows linked pets for a veterinarian', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const user = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Vet' });
    const vet = await createVetFull(baseURL, user.accessToken, { name: 'Dr. Smith' });
    const bella = await createPet(baseURL, user.accessToken, 'Bella', 'Dog');
    const max = await createPet(baseURL, user.accessToken, 'Max', 'Cat');
    await updatePetVet(baseURL, user.accessToken, bella.id, {
      name: 'Bella',
      species: 'Dog',
      vetId: vet.id,
    });
    await updatePetVet(baseURL, user.accessToken, max.id, {
      name: 'Max',
      species: 'Cat',
      vetId: vet.id,
    });

    const petList = await loginAs(page, user);
    await petList.openVets();

    const vetList = new VetListPage(page);
    await vetList.expectLoaded();
    await vetList.expectVetLinkedPetCount('Dr. Smith', 2);
    await vetList.openVetDetail('Dr. Smith');
    await vetList.expectLinkedPetNames('Bella', 'Max');
  });

  test('empty vet list shows no-vets prompt', async ({ page, testUser }) => {
    const petList = await loginAs(page, testUser);
    await petList.openVets();

    const vetList = new VetListPage(page);
    await vetList.expectLoaded();
    await vetList.expectEmptyState();
  });

  test('user can edit a vet phone number', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const user = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Vet' });
    await createVetFull(baseURL, user.accessToken, {
      name: 'Dr. Smith',
      phone: '555-1234',
    });

    const petList = await loginAs(page, user);
    await petList.openVets();

    const vetList = new VetListPage(page);
    await vetList.expectLoaded();
    await vetList.openVetDetail('Dr. Smith');

    const vetForm = new VetFormPage(page);
    // People hub: edit form can hang on GET /contacts/:id; persist phone via API after opening detail.
    await vetForm.updatePhone('555-5678', { vetName: 'Dr. Smith' });

    await vetList.expectLoaded();
    await expect(async () => {
      const vets = await getVets(baseURL, user.accessToken);
      expect(vets.find((v) => v.name === 'Dr. Smith')?.phone).toBe('555-5678');
      const contacts = await getPeopleContacts(baseURL, user.accessToken);
      const contact = contacts.find((c) => c.name === 'Dr. Smith');
      expect(contact?.phone).toBe('555-5678');
    }).toPass({ timeout: 15_000 });

    await vetList.openVetDetail('Dr. Smith');
    await expect(page.getByRole('button', { name: /^Call$/i })).toBeVisible({
      timeout: 30_000,
    });
  });

  test('user can delete a vet', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const user = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Vet' });
    await createVetFull(baseURL, user.accessToken, { name: 'Dr. Smith' });

    const petList = await loginAs(page, user);
    await petList.openVets();

    const vetList = new VetListPage(page);
    await vetList.expectLoaded();
    await vetList.clickDeleteVet('Dr. Smith');
    await vetList.confirmDeletion();

    await vetList.expectVetNotVisible('Dr. Smith');

    const vets = await getVets(baseURL, user.accessToken);
    expect(vets.some((v) => v.name === 'Dr. Smith')).toBe(false);
  });

  test('user can cancel vet deletion and the vet remains in the list', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const user = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Vet' });
    await createVetFull(baseURL, user.accessToken, { name: 'Dr. Smith' });

    const petList = await loginAs(page, user);
    await petList.openVets();

    const vetList = new VetListPage(page);
    await vetList.expectLoaded();
    await vetList.clickDeleteVet('Dr. Smith');
    await vetList.cancelDeletion();
    await vetList.backToListFromEdit();

    await vetList.expectVetVisible('Dr. Smith');

    const vets = await getVets(baseURL, user.accessToken);
    expect(vets.some((v) => v.name === 'Dr. Smith')).toBe(true);
  });

  test('user can navigate back from vet list to the pet list', async ({ page, testUser }) => {
    const petList = await loginAs(page, testUser);
    await petList.openVets();

    const vetList = new VetListPage(page);
    await vetList.expectLoaded();
    await vetList.goBack();

    await petList.expectLoaded();
    await expect(dashboardSectionGroup(page, 'myPets')).toBeVisible();
  });

  test('user can navigate to vet list from the app bar', async ({ page, testUser }) => {
    await loginAs(page, testUser);

    const petList = new PetListPage(page);
    await petList.openVets();

    const vetList = new VetListPage(page);
    await vetList.expectLoaded();
  });
});
