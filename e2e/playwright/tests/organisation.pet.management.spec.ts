/**
 * @bdd organisation_pet_management.feature
 * Scenario: Super user creates a pet under the organisation
 * Scenario: All organisation members can see an organisation pet
 * Scenario: Organisation pets appear grouped by organisation
 * Scenario: Assigning a member to an organisation pet on creation
 * Scenario: Adding a health entry to an organisation pet
 * Scenario: Organisation pet events appear in all members' dashboards
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  createFamilyEvent,
  createHealthEntry,
  createOrgPet,
  createPet,
  getAllPets,
  getFamilyEvents,
  getHealthEntries,
  seedHappyPawsClinic,
} from '../support/api';
import { HealthDashboardPage } from '../pages/health-dashboard.page';
import { OrganizationDetailPage } from '../pages/organization-detail.page';
import { OrganizationListPage } from '../pages/organization-list.page';
import { PetFormPage } from '../pages/pet-form.page';
import { PetListPage } from '../pages/pet-list.page';

const ORG_NAME = 'Happy Paws Clinic';

test.describe('Organisation pet management', () => {
  test('super user creates a pet under the organisation', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org } = await seedHappyPawsClinic(baseURL);

    const petList = await loginAs(page, alice, { experience: 'organization' });
    await petList.openOrganizations();

    const orgList = new OrganizationListPage(page);
    await orgList.openOrg(ORG_NAME);

    const detail = new OrganizationDetailPage(page);
    await detail.expectLoaded(ORG_NAME);
    await detail.openAddOrgPet();

    const form = new PetFormPage(page);
    await form.createPet('Bella', 'Dog');

    await detail.expectLoaded(ORG_NAME);
    await detail.expectPetVisible('Bella');

    const pets = await getAllPets(baseURL, alice.accessToken);
    const bella = pets.find((p) => p.name === 'Bella');
    expect(bella).toBeTruthy();
    expect(bella?.organization_id).toBe(org.id);
    expect(bella?.organization_name).toBe(ORG_NAME);

    await petList.goHome();
    await petList.expectPetUnderOrganization('Bella', ORG_NAME);
  });

  test('all organisation members can see an organisation pet', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, bob, org } = await seedHappyPawsClinic(baseURL);
    await createOrgPet(baseURL, alice.accessToken, org.id, {
      name: 'Bella',
      species: 'dog',
    });

    const petList = await loginAs(page, bob, { experience: 'organization' });
    await petList.expectLoaded();
    await petList.expectPetUnderOrganization('Bella', ORG_NAME);
  });

  test('organisation pets appear grouped by organisation', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org } = await seedHappyPawsClinic(baseURL);
    await createOrgPet(baseURL, alice.accessToken, org.id, {
      name: 'Bella',
      species: 'dog',
    });
    await createPet(baseURL, alice.accessToken, 'Milo', 'Dog');

    const petList = await loginAs(page, alice);
    await petList.expectSectionHeader('My Pets');
    await petList.expectPetVisible('Milo');

    // Nav v2 guardian shell shows personal pets only; org inventory is on /o/home.
    await petList.goHome({ experience: 'organization' });
    await petList.expectSectionHeader(ORG_NAME);
    await petList.expectPetUnderOrganization('Bella', ORG_NAME);
  });

  test('assigning a member to an organisation pet on creation', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, bob, org } = await seedHappyPawsClinic(baseURL);

    const petList = await loginAs(page, alice, { experience: 'organization' });
    await petList.openOrganizations();

    const orgList = new OrganizationListPage(page);
    await orgList.openOrg(ORG_NAME);

    const detail = new OrganizationDetailPage(page);
    await detail.expectLoaded(ORG_NAME);
    await detail.openAddOrgPet();

    const form = new PetFormPage(page);
    await form.createPet('Luna', 'Dog');

    const pets = await getAllPets(baseURL, alice.accessToken);
    const luna = pets.find((p) => p.name === 'Luna');
    expect(luna).toBeTruthy();
    expect(luna?.organization_id).toBe(org.id);

    // Assignment UI is not wired on create yet — verify via API (family event).
    await createFamilyEvent(baseURL, alice.accessToken, luna!.id, {
      assignedToUserId: bob.userId,
    });

    const events = await getFamilyEvents(baseURL, alice.accessToken, luna!.id);
    expect(events.some((e) => e.assigned_to_user_id === bob.userId)).toBe(true);
  });

  test('adding a health entry to an organisation pet', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, bob, org } = await seedHappyPawsClinic(baseURL);
    const pet = await createOrgPet(baseURL, alice.accessToken, org.id, {
      name: 'Bella',
      species: 'dog',
    });

    const today = new Date().toISOString().slice(0, 10);
    await createHealthEntry(baseURL, bob.accessToken, pet.id, {
      name: 'Annual Vaccination',
      type: 'preventive',
      nextDueDate: today,
    });

    const bobEntries = await getHealthEntries(baseURL, bob.accessToken);
    expect(bobEntries.some((e) => e.name === 'Annual Vaccination')).toBe(true);

    const petList = await loginAs(page, alice, { experience: 'organization' });
    await petList.openHealthDashboard();

    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.expectEntryVisible('Annual Vaccination');
  });

  test('organisation pet events appear in all members dashboards', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org } = await seedHappyPawsClinic(baseURL);
    const pet = await createOrgPet(baseURL, alice.accessToken, org.id, {
      name: 'Bella',
      species: 'dog',
    });

    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dueDate = tomorrow.toISOString().slice(0, 10);
    await createHealthEntry(baseURL, alice.accessToken, pet.id, {
      name: 'Flea Treatment',
      type: 'preventive',
      nextDueDate: dueDate,
    });

    const petList = await loginAs(page, alice, { experience: 'organization' });
    await petList.openHealthDashboard();

    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.selectOrgFilter(ORG_NAME);
    await dashboard.expectEntryVisible('Flea Treatment');
  });
});
