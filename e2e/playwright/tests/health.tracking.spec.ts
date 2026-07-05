/**
 * @bdd health_tracking.feature
 * Scenario: Marking a health entry as taken
 * Scenario: Creating a medication entry
 */
import { test, expect, loginAs, seedPetWithDueHealthEntry } from '../fixtures/auth.fixture';
import { HealthDashboardPage } from '../pages/health-dashboard.page';
import { PetListPage } from '../pages/pet-list.page';
import { createPet, createHealthEntry, getHealthEntry, markHealthEntryTaken } from '../support/api';

test.describe('Health tracking', () => {
  test('due health entry appears on dashboard after API seed', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { entry } = await seedPetWithDueHealthEntry(baseURL, testUser, {
      petName: 'Bella',
      entryName: 'Heartworm Prevention',
    });

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openHealthDashboard();

    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.expectEntryVisible(entry.name);
  });

  test('user can mark a due health entry as done', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { entry } = await seedPetWithDueHealthEntry(baseURL, testUser, {
      entryName: 'Flea Treatment',
      frequency: 'once',
    });

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openHealthDashboard();

    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.expectEntryVisible(entry.name);

    await markHealthEntryTaken(baseURL, testUser.accessToken, entry.id);
    const updated = await getHealthEntry(baseURL, testUser.accessToken, entry.id);
    expect(updated.status).toBe('completed');
    expect(updated.completed_on).toBeTruthy();
  });

  test('user can create a medication entry from the health dashboard', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Max', 'Cat');
    const entryName = 'Annual Vaccination';
    const today = new Date().toISOString().slice(0, 10);
    await createHealthEntry(baseURL, testUser.accessToken, pet.id, {
      name: entryName,
      nextDueDate: today,
      dosage: '1 dose',
    });

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openHealthDashboard();

    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.expectEntryVisible(entryName);
  });
});
