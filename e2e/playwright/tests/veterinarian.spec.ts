/**
 * @bdd veterinarian_management.feature
 * Scenario: Creating a veterinarian with all details
 * Scenario: Creating a veterinarian with only a name
 * Scenario: Viewing the veterinarian list
 * Scenario: Empty vet list shows prompt
 * Scenario: Editing a veterinarian's phone number
 * Scenario: Deleting a veterinarian
 * Scenario: Navigating to vet list from the app bar
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  createVetFull,
  getVets,
  signupUser,
} from '../support/api';
import { checkA11y } from '../support/axe';
import { PetListPage } from '../pages/pet-list.page';
import { VetListPage } from '../pages/vet-list.page';
import { VetFormPage } from '../pages/vet-form.page';

test.describe('Veterinarian management', () => {
  test('@smoke user can create a vet with all details', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';

    const petList = await loginAs(page, testUser);
    await petList.openVets();

    const vetList = new VetListPage(page);
    await vetList.expectLoaded();
    await vetList.openAddForm();

    const vetForm = new VetFormPage(page);
    await vetForm.createVet({
      name: 'Dr. Smith',
      phone: '555-1234',
      email: 'drsmith@vetclinic.com',
      address: '123 Vet Lane',
      notes: 'Open on weekends',
    });

    await vetList.expectLoaded();
    await vetList.expectVetVisible('Dr. Smith');
    await vetList.expectPhoneVisible('555-1234');

    const vets = await getVets(baseURL, testUser.accessToken);
    const created = vets.find((v) => v.name === 'Dr. Smith');
    expect(created).toBeTruthy();
    expect(created?.phone).toBe('555-1234');

    await checkA11y(page, 'vet list after create');
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
    await vetList.clickEditVet('Dr. Smith');

    const vetForm = new VetFormPage(page);
    await vetForm.updatePhone('555-5678');

    await vetList.expectLoaded();
    await vetList.expectPhoneVisible('555-5678');

    const vets = await getVets(baseURL, user.accessToken);
    const updated = vets.find((v) => v.name === 'Dr. Smith');
    expect(updated?.phone).toBe('555-5678');
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

  test('user can navigate to vet list from the app bar', async ({ page, testUser }) => {
    await loginAs(page, testUser);

    const petList = new PetListPage(page);
    await petList.openVets();

    const vetList = new VetListPage(page);
    await vetList.expectLoaded();
  });
});
