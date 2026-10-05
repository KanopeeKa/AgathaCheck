/**
 * @bdd weight_tracking.feature
 * Scenario: Recording a weight that counts as the due weigh-in
 * Scenario: Recording a weight without counting it as a weigh-in
 * Scenario: Choosing which weigh-in a weight counts as
 * Scenario: Undoing a weight that counted as a weigh-in
 * Scenario: Deleting a weight that counted as a weigh-in asks for confirmation
 * Scenario: Weight unit preference follows the user
 * Scenario: Weight screen suggests a weigh-in routine when there is none
 * Scenario: Pet profile weight is read-only and links to the weight screen
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  createPet,
  createWeightEntry,
  getWeightEntries,
  updateUserProfile,
} from '../support/api';
import { createCareItem, getOccurrence, undoLast, withCareClock } from '../support/care-api';
import { PetListPage } from '../pages/pet-list.page';
import { PetDetailPage } from '../pages/pet-detail.page';
import { WeightHubPage } from '../pages/weight-hub.page';

/** Calendar day for care clock + weight sheet default date (UTC, matches CI). */
function careDueDateToday(): string {
  return new Date().toISOString().slice(0, 10);
}

async function openPetWeight(
  page: import('@playwright/test').Page,
  testUser: { accessToken: string },
  pet: { id: string; name: string },
) {
  await loginAs(page, testUser);
  const petList = new PetListPage(page);
  await petList.openPet(pet.name, pet.id);
  const petDetail = new PetDetailPage(page);
  await petDetail.expectLoaded(pet.name);
  return new WeightHubPage(page);
}

test.describe('Weight hub', () => {
  test('@smoke-uat Recording a weight that counts as the due weigh-in', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const dueDate = careDueDateToday();
    const careClock = `${dueDate}T10:00`;

    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    await withCareClock(`${dueDate}T09:00`);
    const routine = await createCareItem(baseURL, testUser.accessToken, pet.id, {
      name: 'Hub weigh-in',
      careFamily: 'weight_monitoring',
      frequency: 'monthly',
      dueDate,
      scheduleType: 'from_due_date',
      startDate: dueDate,
    });
    const occurrenceId = routine.open_occurrences[0]?.id;
    expect(occurrenceId).toBeTruthy();

    await withCareClock(careClock, page);
    const hub = await openPetWeight(page, testUser, pet);
    await hub.openRecordWeightSheet();
    await hub.fillWeight('10.5');
    await hub.waitForCountsAsReady();
    await hub.setCountsAsSwitch(true);
    await hub.saveSheet();

    const occDetail = await getOccurrence(baseURL, testUser.accessToken, routine.id, occurrenceId!);
    expect((occDetail.occurrence as { status?: string }).status).toBe('completed');

    const entries = await getWeightEntries(baseURL, testUser.accessToken, pet.id);
    const linked = entries.find((e) => e.health_occurrence_id === occurrenceId);
    expect(linked?.weight).toBeCloseTo(10.5, 1);

    await withCareClock(null, page);
  });

  test('Recording a weight without counting it as a weigh-in', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const dueDate = careDueDateToday();
    const careClock = `${dueDate}T11:00`;

    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    await withCareClock(`${dueDate}T09:00`);
    const routine = await createCareItem(baseURL, testUser.accessToken, pet.id, {
      name: 'Skip fulfil weigh-in',
      careFamily: 'weight_monitoring',
      frequency: 'monthly',
      dueDate,
      scheduleType: 'from_due_date',
      startDate: dueDate,
    });
    const occurrenceId = routine.open_occurrences[0]?.id;
    expect(occurrenceId).toBeTruthy();

    await withCareClock(careClock, page);
    const hub = await openPetWeight(page, testUser, pet);
    await hub.openRecordWeightSheet();
    await hub.fillWeight('11.0');
    await hub.waitForCountsAsReady();
    await hub.setCountsAsSwitch(false);
    await hub.saveSheet();

    const occDetail = await getOccurrence(baseURL, testUser.accessToken, routine.id, occurrenceId!);
    expect((occDetail.occurrence as { status?: string }).status).toBe('pending');

    const entries = await getWeightEntries(baseURL, testUser.accessToken, pet.id);
    expect(entries).toHaveLength(1);
    expect(entries[0].weight).toBeCloseTo(11.0, 1);
    expect(entries[0].health_occurrence_id).toBeFalsy();

    await withCareClock(null, page);
  });

  test('Choosing which weigh-in a weight counts as', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const dueDate = careDueDateToday();
    const careClock = `${dueDate}T12:00`;

    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    await withCareClock(`${dueDate}T09:00`);
    const routineA = await createCareItem(baseURL, testUser.accessToken, pet.id, {
      name: 'Weigh-in Alpha',
      careFamily: 'weight_monitoring',
      frequency: 'monthly',
      dueDate,
      scheduleType: 'from_due_date',
      startDate: dueDate,
    });
    const routineB = await createCareItem(baseURL, testUser.accessToken, pet.id, {
      name: 'Weigh-in Beta',
      careFamily: 'weight_monitoring',
      frequency: 'monthly',
      dueDate,
      scheduleType: 'from_due_date',
      startDate: dueDate,
    });
    const occA = routineA.open_occurrences[0]?.id;
    const occB = routineB.open_occurrences[0]?.id;
    expect(occA).toBeTruthy();
    expect(occB).toBeTruthy();

    await withCareClock(careClock, page);
    const hub = await openPetWeight(page, testUser, pet);
    await hub.openRecordWeightSheet();
    await hub.fillWeight('12.3');
    await hub.waitForCountsAsReady();
    await hub.chooseWeighInRoutine(/Weigh-in Beta/i);
    await hub.saveSheet();

    const occBDetail = await getOccurrence(baseURL, testUser.accessToken, routineB.id, occB!);
    expect((occBDetail.occurrence as { status?: string }).status).toBe('completed');

    const occADetail = await getOccurrence(baseURL, testUser.accessToken, routineA.id, occA!);
    expect((occADetail.occurrence as { status?: string }).status).toBe('pending');

    await withCareClock(null, page);
  });

  test('Undoing a weight that counted as a weigh-in', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const dueDate = careDueDateToday();
    const careClock = `${dueDate}T10:00`;

    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    await withCareClock(`${dueDate}T09:00`);
    const routine = await createCareItem(baseURL, testUser.accessToken, pet.id, {
      name: 'Undo hub weigh-in',
      careFamily: 'weight_monitoring',
      frequency: 'monthly',
      dueDate,
      scheduleType: 'from_due_date',
      startDate: dueDate,
    });
    const occurrenceId = routine.open_occurrences[0]?.id;
    expect(occurrenceId).toBeTruthy();

    let fulfilmentUndo: { entry_id: string; undo_token: string } | null = null;
    page.on('response', async (response) => {
      if (
        response.request().method() !== 'POST' ||
        !response.url().includes('/api/weight-entries') ||
        !response.ok()
      ) {
        return;
      }
      try {
        const body = (await response.json()) as {
          fulfilment?: { entry_id?: string; undo_token?: string };
        };
        if (body.fulfilment?.undo_token && body.fulfilment.entry_id) {
          fulfilmentUndo = {
            entry_id: body.fulfilment.entry_id,
            undo_token: body.fulfilment.undo_token,
          };
        }
      } catch {
        /* non-JSON */
      }
    });

    await withCareClock(careClock, page);
    const hub = await openPetWeight(page, testUser, pet);
    await hub.openRecordWeightSheet();
    await hub.fillWeight('9.5');
    await hub.waitForCountsAsReady();
    await hub.setCountsAsSwitch(true);
    await hub.saveSheet();

    await expect.poll(() => fulfilmentUndo?.undo_token).toBeTruthy();
    await undoLast(
      baseURL,
      testUser.accessToken,
      fulfilmentUndo!.entry_id,
      fulfilmentUndo!.undo_token,
    );

    const entries = await getWeightEntries(baseURL, testUser.accessToken, pet.id);
    expect(entries).toHaveLength(0);

    const occDetail = await getOccurrence(baseURL, testUser.accessToken, routine.id, occurrenceId!);
    expect((occDetail.occurrence as { status?: string }).status).toBe('pending');

    await withCareClock(null, page);
  });

  test('Deleting a weight that counted as a weigh-in asks for confirmation', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const dueDate = careDueDateToday();
    const careClock = `${dueDate}T10:00`;

    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    await withCareClock(`${dueDate}T09:00`);
    const routine = await createCareItem(baseURL, testUser.accessToken, pet.id, {
      name: 'Delete confirm weigh-in',
      careFamily: 'weight_monitoring',
      frequency: 'monthly',
      dueDate,
      scheduleType: 'from_due_date',
      startDate: dueDate,
    });
    expect(routine.open_occurrences[0]?.id).toBeTruthy();

    await withCareClock(careClock, page);
    const hub = await openPetWeight(page, testUser, pet);
    await hub.openRecordWeightSheet();
    await hub.fillWeight('10.0');
    await hub.waitForCountsAsReady();
    await hub.setCountsAsSwitch(true);
    await hub.saveSheet();

    await hub.clickDeleteOnEntryRow(10.0);
    await hub.expectLinkedDeleteConfirmation(/Delete confirm weigh-in/i);

    await withCareClock(null, page);
  });

  test('Weight unit preference follows the user', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await updateUserProfile(baseURL, testUser.accessToken, { weight_unit: 'lb' });

    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    await createWeightEntry(baseURL, testUser.accessToken, pet.id, {
      weight: 22.0,
      unit: 'lb',
      date: '2027-01-15',
    });

    const hub = await openPetWeight(page, testUser, pet);
    await hub.expectWeightDisplayed(22.0, 'lb');

    await updateUserProfile(baseURL, testUser.accessToken, { weight_unit: 'kg' });
  });

  test('Weight screen suggests a weigh-in routine when there is none', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');

    const hub = await openPetWeight(page, testUser, pet);
    await hub.expectSetUpWeighInRoutinePrompt();
  });

  test('Pet profile weight is read-only and links to the weight screen', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    await createWeightEntry(baseURL, testUser.accessToken, pet.id, {
      weight: 24.0,
      date: '2025-04-01',
    });

    await loginAs(page, testUser);
    const petList = new PetListPage(page);
    await petList.openPet(pet.name, pet.id);
    const petDetail = new PetDetailPage(page);
    await petDetail.expectLoaded(pet.name);
    await petDetail.openEdit();

    const hub = new WeightHubPage(page);
    await hub.expectReadOnlyWeightOnPetEdit();
    await hub.followRecordWeightLinkOnEditForm();
  });
});
