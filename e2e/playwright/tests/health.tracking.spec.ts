/**
 * @bdd health_tracking.feature
 * Scenario: Marking a health entry as taken
 * Scenario: Creating a medication entry
 * Scenario: Empty health dashboard shows prompt
 * Scenario: Creating a preventive entry
 * Scenario: Creating a vet visit entry
 * Scenario: Creating a procedure entry
 * Scenario: Editing a health entry
 * Scenario: Deleting a health entry
 * Scenario: Undoing a completed entry
 * Scenario: Snoozing a health entry
 * Scenario: Filtering entries by type using tabs
 * Scenario: Due events appear on the pet list screen
 * Scenario: No due events shows all caught up
 * Scenario: Exporting health entries as CSV
 */
import { test, expect, loginAs, seedPetWithDueHealthEntry } from '../fixtures/auth.fixture';
import { HealthDashboardPage } from '../pages/health-dashboard.page';
import { PetListPage } from '../pages/pet-list.page';
import { refreshFlutterAccessibility } from '../support/flutter';
import {
  createPet,
  createHealthEntry,
  getHealthEntry,
  markHealthEntryTaken,
  updateHealthEntry,
  deleteHealthEntry,
  undoCompleteHealthEntry,
  getHealthEntries,
  exportHealthEntriesCsv,
} from '../support/api';

test.describe('Health tracking', () => {
  // ── Existing Wave 0 tests ─────────────────────────────────────────────────

  test('@smoke due health entry appears on dashboard after API seed', async ({ page, testUser }) => {
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

  // ── Wave A: Empty state ───────────────────────────────────────────────────

  test('empty health dashboard shows "No entries yet" prompt', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await createPet(baseURL, testUser.accessToken, 'Bella');

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openHealthDashboard();

    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.expectEmptyState();
  });

  // ── Wave A: Creating entries by type ─────────────────────────────────────

  test('preventive entry appears on dashboard after API seed', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    const today = new Date().toISOString().slice(0, 10);
    const entry = await createHealthEntry(baseURL, testUser.accessToken, pet.id, {
      name: 'Flea Treatment',
      type: 'preventive',
      nextDueDate: today,
    });

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openHealthDashboard();

    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.expectEntryVisible(entry.name);
  });

  test('vet visit entry appears on dashboard after API seed', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    const today = new Date().toISOString().slice(0, 10);
    const entry = await createHealthEntry(baseURL, testUser.accessToken, pet.id, {
      name: 'Annual Checkup',
      type: 'vet_visit',
      nextDueDate: today,
    });

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openHealthDashboard();

    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.expectEntryVisible(entry.name);
  });

  test('procedure entry appears on dashboard after API seed', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    const today = new Date().toISOString().slice(0, 10);
    const entry = await createHealthEntry(baseURL, testUser.accessToken, pet.id, {
      name: 'Dental Cleaning',
      type: 'procedure',
      nextDueDate: today,
    });

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openHealthDashboard();

    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.expectEntryVisible(entry.name);
  });

  // ── Wave C: Edit / delete ─────────────────────────────────────────────────

  test('editing a health entry dosage persists via API', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    const today = new Date().toISOString().slice(0, 10);
    const entry = await createHealthEntry(baseURL, testUser.accessToken, pet.id, {
      name: 'Heartworm',
      nextDueDate: today,
      dosage: '1 tablet',
    });

    await updateHealthEntry(baseURL, testUser.accessToken, entry.id, {
      name: 'Heartworm',
      nextDueDate: today,
      dosage: '2 tablets',
    });

    const updated = await getHealthEntry(baseURL, testUser.accessToken, entry.id);
    expect(updated.name).toBe('Heartworm');
    expect(updated.dosage).toBe('2 tablets');

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openHealthDashboard();

    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.expectEntryVisible(entry.name);
  });

  test('deleting a health entry removes it from the dashboard', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    const today = new Date().toISOString().slice(0, 10);
    const entry = await createHealthEntry(baseURL, testUser.accessToken, pet.id, {
      name: 'Old Treatment',
      nextDueDate: today,
    });

    await deleteHealthEntry(baseURL, testUser.accessToken, entry.id);

    const remaining = await getHealthEntries(baseURL, testUser.accessToken);
    expect(remaining.find((e) => e.id === entry.id)).toBeUndefined();

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openHealthDashboard();

    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.expectEmptyState();
  });

  // ── Wave C: Undo / snooze ─────────────────────────────────────────────────

  test('undoing a completed entry restores it to active status', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    const today = new Date().toISOString().slice(0, 10);
    const entry = await createHealthEntry(baseURL, testUser.accessToken, pet.id, {
      name: 'Heartworm',
      nextDueDate: today,
      frequency: 'once',
    });

    await markHealthEntryTaken(baseURL, testUser.accessToken, entry.id);
    const completed = await getHealthEntry(baseURL, testUser.accessToken, entry.id);
    expect(completed.status).toBe('completed');

    const restored = await undoCompleteHealthEntry(baseURL, testUser.accessToken, entry.id);
    expect(restored.status).toBe('active');

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openHealthDashboard();

    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.expectEntryVisible(entry.name);
  });

  test('snoozing a health entry pushes the due date forward', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    const today = new Date().toISOString().slice(0, 10);
    const entry = await createHealthEntry(baseURL, testUser.accessToken, pet.id, {
      name: 'Flea Treatment',
      nextDueDate: today,
    });

    const expectedDue = new Date(`${today}T12:00:00`);
    expectedDue.setDate(expectedDue.getDate() + 3);
    const snoozedDueDate = expectedDue.toISOString().slice(0, 10);

    await updateHealthEntry(baseURL, testUser.accessToken, entry.id, {
      name: entry.name,
      nextDueDate: snoozedDueDate,
    });

    const updated = await getHealthEntry(baseURL, testUser.accessToken, entry.id);
    expect(updated.name).toBe(entry.name);
    expect(updated.next_due_date).toBe(snoozedDueDate);

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openHealthDashboard();

    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.expectEntryVisible(entry.name);
  });

  // ── Wave C: Tab filtering ─────────────────────────────────────────────────

  test('Medications tab shows medication entries', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    const today = new Date().toISOString().slice(0, 10);
    await createHealthEntry(baseURL, testUser.accessToken, pet.id, {
      name: 'Heartworm',
      type: 'medication',
      nextDueDate: today,
    });

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openHealthDashboard();

    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.selectTab('Medications');
    await dashboard.expectEntryVisible('Heartworm');
  });

  // ── Wave C: Pet list due events ───────────────────────────────────────────

  test('due events section appears on pet list when an entry is due today', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const { entry } = await seedPetWithDueHealthEntry(baseURL, testUser, {
      petName: 'Bella',
      entryName: 'Flea Prevention',
      dueDate: yesterday.toISOString().slice(0, 10),
    });

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.expectLoaded();
    await petList.expectPetVisible('Bella');
    await expect(async () => {
      await refreshFlutterAccessibility(page);
      await expect(page.getByText(/Upcoming events/i).first()).toBeVisible();
      await expect(page.getByText(entry.name, { exact: false }).first()).toBeVisible();
    }).toPass({ timeout: 45_000 });
  });

  test('pet list shows "You\'re all caught up" when no entries are due', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 30);
    await createHealthEntry(baseURL, testUser.accessToken, pet.id, {
      name: 'Future Treatment',
      nextDueDate: futureDate.toISOString().slice(0, 10),
    });

    await loginAs(page, testUser);
    await page
      .getByText("You're all caught up", { exact: false })
      .first()
      .waitFor({ timeout: 20_000 });
  });

  // ── Wave C: CSV export ────────────────────────────────────────────────────

  test('CSV export returns health entries as CSV data', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    const today = new Date().toISOString().slice(0, 10);
    await createHealthEntry(baseURL, testUser.accessToken, pet.id, {
      name: 'Vaccination',
      nextDueDate: today,
    });

    const csv = await exportHealthEntriesCsv(baseURL, testUser.accessToken);
    expect(csv).toContain('Vaccination');
    expect(csv).toContain('id,pet_name,name,type');

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openHealthDashboard();

    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.expectEntryVisible('Vaccination');
  });
});
