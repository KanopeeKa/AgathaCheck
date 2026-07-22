/**
 * @bdd weight_tracking.feature
 * Scenario: Adding a weight entry
 * Scenario: Adding multiple weight entries
 * Scenario: Viewing weight entries as a list
 * Scenario: Viewing weight chart
 * Scenario: Viewing latest weight on pet profile
 * Scenario: Editing a weight entry
 * Scenario: Deleting a weight entry
 * Scenario: Selecting weight unit
 * Scenario: Empty weight history
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  createPet,
  createWeightEntry,
  getWeightEntries,
  getLatestWeightEntry,
  updateWeightEntry,
  deleteWeightEntry,
  signupUser,
} from '../support/api';
import { PetListPage } from '../pages/pet-list.page';
import { PetDetailPage } from '../pages/pet-detail.page';
import { WeightTrackingPage } from '../pages/weight-tracking.page';

test.describe('Weight tracking', () => {
  // ── Empty state ───────────────────────────────────────────────────────────

  test('@smoke-uat empty weight history shows add-entry prompt', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');

    const petList = await loginAs(page, testUser, { experience: 'guardian' });
    await petList.expectPetVisible(pet.name);
    await petList.openPet(pet.name);

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
    await petList.openPet(pet.name);

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
    await petList.openPet(pet.name);

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
    await petList.openPet(pet.name);

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
    await petList.openPet(pet.name);

    const petDetail = new PetDetailPage(page);
    await petDetail.expectLoaded(pet.name);

    const weightPage = new WeightTrackingPage(page);
    await weightPage.expectWeightEntryVisible(25.0);
  });

  // ── Editing weight entries ────────────────────────────────────────────────

  test('editing a weight entry via API updates the stored value', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');

    const entry = await createWeightEntry(baseURL, testUser.accessToken, pet.id, {
      weight: 25.0,
      date: '2025-06-01',
    });

    await updateWeightEntry(baseURL, testUser.accessToken, entry.id, {
      weight: 25.5,
      date: '2025-06-01',
    });

    const entries = await getWeightEntries(baseURL, testUser.accessToken, pet.id);
    const updated = entries.find((e) => e.id === entry.id);
    expect(updated).toBeTruthy();
    expect(updated!.weight).toBeCloseTo(25.5, 1);

    // Confirm the UI shows the updated weight.
    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openPet(pet.name);

    const petDetail = new PetDetailPage(page);
    await petDetail.expectLoaded(pet.name);

    const weightPage = new WeightTrackingPage(page);
    await weightPage.expectWeightEntryVisible(25.5);
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
    await petList.openPet(pet.name);

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
    await petList.openPet(pet.name);

    const petDetail = new PetDetailPage(page);
    await petDetail.expectLoaded(pet.name);

    const weightPage = new WeightTrackingPage(page);
    await weightPage.expectUnitSelectorVisible();
  });
});
