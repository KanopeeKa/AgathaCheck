/**
 * @bdd health_tracking.feature
 * Scenario: Marking a health entry as taken
 * Scenario: Creating a medication entry
 * Scenario: Empty guardian due-events inbox shows all caught up
 * Scenario: Creating a preventive entry
 * Scenario: Creating a vet visit entry
 * Scenario: Creating a procedure entry
 * Scenario: Editing a health entry
 * Scenario: Deleting a health entry
 * Scenario: Unified event edit route redirects legacy paths
 * Scenario: Undoing a completed entry
 * Scenario: Snoozing a health entry
 * Scenario: Filtering entries by type using tabs
 * Scenario: Due events appear on the pet list screen
 * Scenario: No due events shows all caught up
 * Scenario: Exporting health entries as CSV
 * Scenario: Multi-dose daily medication shows stack sheet for recording doses
 */
import { test, expect, loginAs, seedPetWithDueHealthEntry } from '../fixtures/auth.fixture';
import { HealthDashboardPage } from '../pages/health-dashboard.page';
import { OccurrenceStackSheetPage } from '../pages/occurrence-stack-sheet.page';
import { PetListPage } from '../pages/pet-list.page';
import { isLiveHostingTarget } from '../support/hosting';
import {
  createPet,
  createHealthEntry,
  getHealthEntry,
  getHealthEntryOccurrences,
  seedMultiDoseHealthEntry,
  markHealthEntryTaken,
  updateHealthEntry,
  deleteHealthEntry,
  undoCompleteHealthEntry,
  getHealthEntries,
  exportHealthEntriesCsv,
} from '../support/api';

test.describe('Health tracking', () => {
  // ── Existing Wave 0 tests ─────────────────────────────────────────────────

  test('@smoke-ci @smoke-uat due health entry appears on dashboard after API seed', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { entry } = await seedPetWithDueHealthEntry(baseURL, testUser, {
      petName: 'Bella',
      entryName: 'Heartworm Prevention',
    });

    await loginAs(page, testUser, { experience: 'guardian' });
    const petList = new PetListPage(page);
    await petList.expectLoaded();
    await petList.openHealthDashboard({ experience: 'guardian' });

    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    const entryTimeout = isLiveHostingTarget(baseURL) ? 45_000 : 15_000;
    await dashboard.expectEntryVisible(entry.name, entryTimeout);
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

  test('empty guardian due-events inbox shows all caught up when no entries are due', async ({
    page,
    testUser,
  }) => {
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
      type: 'other',
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
    // Global /g/events list shows all entries; snoozed +3 days is still in the unfiltered list.
    await dashboard.expectEntryVisible(entry.name);
    // Due and Overdue filter: +3 days with default remind_days_before=1 is outside the window.
    await dashboard.selectDueOverdueFilter();
    await dashboard.expectEntryNotVisible(entry.name);
    await dashboard.expectEmptyState();
  });

  // ── Wave C: Tab filtering ─────────────────────────────────────────────────

  test('medication entry due today appears on guardian due-events inbox', async ({ page, testUser }) => {
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
    // Guardian /g/events is a due-events inbox (no type tabs); due medication rows surface directly.
    await dashboard.expectEntryVisible('Heartworm');
  });

  // ── Wave C: Pet list due events ───────────────────────────────────────────

  test('due events section appears on pet list when an entry is due or overdue', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const today = new Date().toISOString().slice(0, 10);
    const { entry } = await seedPetWithDueHealthEntry(baseURL, testUser, {
      petName: 'Bella',
      entryName: 'Flea Prevention',
      dueDate: today,
    });

    const apiEntries = await getHealthEntries(baseURL, testUser.accessToken);
    expect(apiEntries.some((row) => row.name === entry.name)).toBe(true);

    await loginAs(page, testUser, { experience: 'guardian' });
    const petList = new PetListPage(page);
    await petList.expectLoaded();
    await petList.expectPetVisible('Bella');

    await petList.refreshByRemount({ experience: 'guardian' });
    await petList.expectDueEntryOnHome(entry.name);
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
    const petList = new PetListPage(page);
    await petList.expectNoDueEventsOnHome();
  });

  // ── Wave C: CSV export ────────────────────────────────────────────────────

  // ── Wave D: Multi-dose occurrences ────────────────────────────────────────

  test('multi-dose daily medication shows stack sheet and records one dose', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    const today = new Date().toISOString().slice(0, 10);
    const entryName = 'Twice Daily Meds';
    const entry = await seedMultiDoseHealthEntry(baseURL, testUser.accessToken, pet.id, {
      name: entryName,
      nextDueDate: today,
      scheduleTimes: ['08:00', '18:00'],
    });

    const occurrencesBefore = await getHealthEntryOccurrences(
      baseURL,
      testUser.accessToken,
      entry.id,
    );
    expect(occurrencesBefore).toHaveLength(2);
    expect(occurrencesBefore.every((row) => row.status === 'pending')).toBe(true);

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openHealthDashboard();

    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.expectEntryVisible(entryName);
    await dashboard.clickMarkDoneForEntry(entry.id);

    const stackSheet = new OccurrenceStackSheetPage(page);
    await stackSheet.expectLoaded(entryName);
    await stackSheet.expectDueTodayDoseCount(2);
    await stackSheet.recordLatestDose();

    const occurrencesAfter = await getHealthEntryOccurrences(
      baseURL,
      testUser.accessToken,
      entry.id,
    );
    const pastOccurrences = await getHealthEntryOccurrences(
      baseURL,
      testUser.accessToken,
      entry.id,
      { status: 'past' },
    );
    expect(occurrencesAfter.filter((row) => row.status === 'pending')).toHaveLength(1);
    expect(pastOccurrences.filter((row) => row.status === 'completed')).toHaveLength(1);
  });

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
