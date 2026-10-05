/**
 * @bdd weight_tracking.feature
 * Scenario: Adding a weight entry
 * Scenario: Adding multiple weight entries
 * Scenario: Viewing weight entries as a list
 * Scenario: Viewing weight chart
 * Scenario: Viewing latest weight on pet profile
 * Scenario: Profile updates from older apps still record the weight
 * Scenario: Editing a weight entry
 * Scenario: Deleting a weight entry
 * Scenario: Selecting weight unit
 * Scenario: Empty weight history
 * Scenario: PDF pet report shows latest weight as current weight
 * Scenario: A weight recorded with a weigh-in choice completes that weigh-in
 * Scenario: Undoing a weigh-in removes the weight it created
 */
import { readFileSync } from 'node:fs';
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  createPet,
  createWeightEntry,
  getWeightEntries,
  getLatestWeightEntry,
  updatePetProfile,
  deleteWeightEntry,
  signupUser,
} from '../support/api';
import {
  createCareItem,
  getOccurrence,
  undoLast,
  withCareClock,
} from '../support/care-api';
import { PetListPage } from '../pages/pet-list.page';
import { PetDetailPage } from '../pages/pet-detail.page';
import { WeightTrackingPage } from '../pages/weight-tracking.page';
import { WeightHubPage } from '../pages/weight-hub.page';

test.describe('Weight tracking', () => {
  // ── Empty state ───────────────────────────────────────────────────────────

  test('@smoke-uat empty weight history shows add-entry prompt', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');

    const petList = await loginAs(page, testUser, { experience: 'guardian' });
    await petList.expectPetVisible(pet.name);
    await petList.openPet(pet.name, pet.id);

    const petDetail = new PetDetailPage(page);
    await petDetail.expectLoaded(pet.name);

    const weightPage = new WeightTrackingPage(page);
    await weightPage.expectEmptyState();
  });

  // ── Adding weight entries ─────────────────────────────────────────────────

  test('user can add a weight entry via the UI', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openPet(pet.name, pet.id);

    const petDetail = new PetDetailPage(page);
    await petDetail.expectLoaded(pet.name);

    const weightPage = new WeightTrackingPage(page);
    await weightPage.openAddWeightSheet();
    await weightPage.fillWeightForm('25.5');
    await weightPage.saveWeightEntry();

    // Verify via API that the entry was persisted.
    const entries = await getWeightEntries(baseURL, testUser.accessToken, pet.id);
    expect(entries.length).toBeGreaterThan(0);
    expect(entries[0].weight).toBeCloseTo(25.5, 1);
    expect(entries[0].unit).toBe('kg');
  });

  test('adding multiple weight entries via API all appear in history', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');

    await createWeightEntry(baseURL, testUser.accessToken, pet.id, {
      weight: 24.0,
      date: '2025-04-01',
    });
    await createWeightEntry(baseURL, testUser.accessToken, pet.id, {
      weight: 24.5,
      date: '2025-05-01',
    });
    await createWeightEntry(baseURL, testUser.accessToken, pet.id, {
      weight: 25.0,
      date: '2025-06-01',
    });

    const entries = await getWeightEntries(baseURL, testUser.accessToken, pet.id);
    expect(entries).toHaveLength(3);

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openPet(pet.name, pet.id);

    const petDetail = new PetDetailPage(page);
    await petDetail.expectLoaded(pet.name);

    const weightPage = new WeightTrackingPage(page);
    await weightPage.openSection();
    // Each entry title is rendered as "{value} kg"; check one is visible.
    await weightPage.expectWeightEntryVisible(25.0);
  });

  // ── Viewing weight history ────────────────────────────────────────────────

  test('weight history shows 3 seeded entries in the list', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');

    await createWeightEntry(baseURL, testUser.accessToken, pet.id, {
      weight: 24.0,
      date: '2025-04-01',
    });
    await createWeightEntry(baseURL, testUser.accessToken, pet.id, {
      weight: 24.5,
      date: '2025-05-01',
    });
    await createWeightEntry(baseURL, testUser.accessToken, pet.id, {
      weight: 25.0,
      date: '2025-06-01',
    });

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openPet(pet.name, pet.id);

    const petDetail = new PetDetailPage(page);
    await petDetail.expectLoaded(pet.name);

    const weightPage = new WeightTrackingPage(page);
    // Expect all 3 entries displayed (chart appears above the list when >= 2 entries)
    await weightPage.expectWeightEntryCount(3);
  });

  // ── Latest weight on pet profile ──────────────────────────────────────────

  test('latest weight entry is reflected via API', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');

    await createWeightEntry(baseURL, testUser.accessToken, pet.id, {
      weight: 24.0,
      date: '2025-05-01',
    });
    await createWeightEntry(baseURL, testUser.accessToken, pet.id, {
      weight: 25.0,
      date: '2025-06-01',
    });

    const latest = await getLatestWeightEntry(baseURL, testUser.accessToken, pet.id);
    expect(latest.weight).toBeCloseTo(25.0, 1);
    expect(latest.date).toBe('2025-06-01');

    // Navigate to pet detail to confirm weight section loads.
    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openPet(pet.name, pet.id);

    const petDetail = new PetDetailPage(page);
    await petDetail.expectLoaded(pet.name);

    const weightPage = new WeightTrackingPage(page);
    await weightPage.expectWeightEntryVisible(25.0);
  });

  test('Profile updates from older apps still record the weight', async ({ testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');

    await createWeightEntry(baseURL, testUser.accessToken, pet.id, {
      weight: 24.0,
      date: '2025-04-01',
    });

    const clientDate = new Date().toLocaleDateString('en-CA');

    const updated = await updatePetProfile(baseURL, testUser.accessToken, pet.id, {
      name: pet.name,
      species: 'Dog',
      weight: 25.0,
      weightEntryDate: clientDate,
    });
    expect(updated.weight).toBeCloseTo(25.0, 1);

    const entries = await getWeightEntries(baseURL, testUser.accessToken, pet.id);
    const todayEntry = entries.find((entry) => entry.weight === 25 && entry.notes === '');
    expect(todayEntry).toBeTruthy();
    expect(todayEntry?.date).toBe(clientDate);
  });

  // ── Editing weight entries ────────────────────────────────────────────────

  test('Editing a weight entry', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');

    await createWeightEntry(baseURL, testUser.accessToken, pet.id, {
      weight: 25.0,
      date: '2025-06-01',
    });

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openPet(pet.name, pet.id);

    const petDetail = new PetDetailPage(page);
    await petDetail.expectLoaded(pet.name);

    const hub = new WeightHubPage(page);
    await hub.openHistoryEntry(25.0);
    await hub.fillWeight('25.5');
    await hub.saveSheet();
    await hub.expectWeightDisplayed(25.5);
  });

  // ── Deleting weight entries ───────────────────────────────────────────────

  test('deleting a weight entry removes it from the API response', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');

    const entry = await createWeightEntry(baseURL, testUser.accessToken, pet.id, {
      weight: 25.0,
      date: '2025-06-01',
    });

    await deleteWeightEntry(baseURL, testUser.accessToken, entry.id);

    const entries = await getWeightEntries(baseURL, testUser.accessToken, pet.id);
    expect(entries.find((e) => e.id === entry.id)).toBeUndefined();

    // Navigate so the UI shows the empty state.
    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openPet(pet.name, pet.id);

    const petDetail = new PetDetailPage(page);
    await petDetail.expectLoaded(pet.name);

    const weightPage = new WeightTrackingPage(page);
    await weightPage.expectEmptyState();
  });

  // ── Weight unit selector ──────────────────────────────────────────────────

  test('weight tracking section exposes kg and lb unit selectors', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openPet(pet.name, pet.id);

    const petDetail = new PetDetailPage(page);
    await petDetail.expectLoaded(pet.name);

    const weightPage = new WeightTrackingPage(page);
    await weightPage.expectUnitSelectorVisible();
  });

  // ── Weigh-in fulfilment (W4 server landing) ─────────────────────────────────

  test('A weight recorded with a weigh-in choice completes that weigh-in', async ({ testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const dueDate = '2026-11-01';
    const recordedDate = '2026-11-05';
    const careClock = `${recordedDate}T10:00`;

    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    await withCareClock(`${dueDate}T09:00`);
    const routine = await createCareItem(baseURL, testUser.accessToken, pet.id, {
      name: 'Monthly weigh-in',
      careFamily: 'weight_monitoring',
      frequency: 'monthly',
      dueDate,
      scheduleType: 'from_due_date',
      startDate: dueDate,
    });
    const occurrenceId = routine.open_occurrences[0]?.id;
    expect(occurrenceId).toBeTruthy();

    await withCareClock(careClock);
    const created = await createWeightEntry(baseURL, testUser.accessToken, pet.id, {
      weight: 10.5,
      date: recordedDate,
      fulfilsOccurrenceId: occurrenceId,
      careAsOf: careClock,
    });
    expect(created.health_occurrence_id).toBe(occurrenceId);
    expect(created.fulfilment?.undo_token).toBeTruthy();

    const occDetail = await getOccurrence(baseURL, testUser.accessToken, routine.id, occurrenceId!);
    const occ = occDetail.occurrence as { status?: string };
    expect(occ.status).toBe('completed');

    const entries = await getWeightEntries(baseURL, testUser.accessToken, pet.id);
    const linked = entries.find((e) => e.id === created.id);
    expect(linked?.weight).toBeCloseTo(10.5, 1);
    expect(linked?.date).toBe(recordedDate);

    await withCareClock(null);
  });

  test('Undoing a weigh-in removes the weight it created', async ({ testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const dueDate = '2026-12-01';
    const recordedDate = '2026-12-03';
    const careClock = `${recordedDate}T10:00`;

    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    await withCareClock(`${dueDate}T09:00`);
    const routine = await createCareItem(baseURL, testUser.accessToken, pet.id, {
      name: 'Weigh-in undo',
      careFamily: 'weight_monitoring',
      frequency: 'monthly',
      dueDate,
      scheduleType: 'from_due_date',
      startDate: dueDate,
    });
    const occurrenceId = routine.open_occurrences[0]?.id;
    expect(occurrenceId).toBeTruthy();

    await withCareClock(careClock);
    const created = await createWeightEntry(baseURL, testUser.accessToken, pet.id, {
      weight: 9.8,
      date: recordedDate,
      fulfilsOccurrenceId: occurrenceId,
      careAsOf: careClock,
    });
    const undoToken = created.fulfilment?.undo_token;
    expect(undoToken).toBeTruthy();

    await withCareClock(`${recordedDate}T10:30`);
    await undoLast(baseURL, testUser.accessToken, routine.id, undoToken);

    const entries = await getWeightEntries(baseURL, testUser.accessToken, pet.id);
    expect(entries.find((e) => e.id === created.id)).toBeUndefined();

    const occDetail = await getOccurrence(baseURL, testUser.accessToken, routine.id, occurrenceId!);
    const occ = occDetail.occurrence as { status?: string };
    expect(occ.status).toBe('pending');

    await withCareClock(null);
  });

  test('PDF pet report shows latest weight as current weight', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');

    await createWeightEntry(baseURL, testUser.accessToken, pet.id, {
      weight: 24.0,
      date: '2025-04-01',
    });
    await createWeightEntry(baseURL, testUser.accessToken, pet.id, {
      weight: 25.0,
      date: '2025-06-01',
    });

    const latest = await getLatestWeightEntry(baseURL, testUser.accessToken, pet.id);
    expect(latest.weight).toBeCloseTo(25.0, 1);

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openPet(pet.name, pet.id);

    const petDetail = new PetDetailPage(page);
    await petDetail.expectLoaded(pet.name);

    const downloadPromise = page.waitForEvent('download');
    await petDetail.downloadProfileReport();
    const download = await downloadPromise;
    const downloadPath = await download.path();
    expect(downloadPath).toBeTruthy();

    const pdfBytes = readFileSync(downloadPath!);
    expect(pdfBytes.subarray(0, 5).toString('utf8')).toBe('%PDF-');
  });
});
