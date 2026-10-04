/**
 * @bdd care_item_absence.feature
 * Scenario: In-window care can be rescheduled or skipped from occurrence review during planned absence
 * Scenario: Care item absence strip shows Keep with carer and Review date opens the date directly
 * Scenario: Moving care after the trip postpones it to the day after return
 * Scenario: A date planned during the trip can be looked after by the carer
 */
import { test, loginAs, expect } from '../fixtures/auth.fixture';
import { CareItemPage } from '../pages/care-item.page';
import {
  createHealthEntry,
  createPet,
  createPlannedAbsence,
  signupUser,
  updatePlannedAbsence,
} from '../support/api';
import {
  getCareItem,
  getHealthEntryAbsenceContext,
  planAnotherDate,
  postpone,
} from '../support/care-api';
const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

const dateOffset = (days: number): string => {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
};

async function seedAbsenceInWindowCare(
  root: string,
  options: { petName: string; entryName: string; carerName: string },
) {
  const user = await signupUser(root);
  const pet = await createPet(root, user.accessToken, options.petName);
  const startsOn = dateOffset(7);
  const endsOn = dateOffset(14);
  const inWindowDue = dateOffset(10);
  const entry = await createHealthEntry(root, user.accessToken, pet.id, {
    name: options.entryName,
    nextDueDate: inWindowDue,
    frequency: 'weekly',
    frequencyDays: 7,
    careFamily: 'grooming',
  });
  const absence = await createPlannedAbsence(root, user.accessToken, {
    startsOn,
    endsOn,
    petIds: [pet.id],
  });
  await updatePlannedAbsence(root, user.accessToken, absence.id, {
    petCarers: [
      {
        petId: pet.id,
        carerKind: 'note_only',
        carerName: options.carerName,
        carerNote: 'Has spare key',
      },
    ],
  });
  return { user, pet, entry, absence, startsOn, endsOn, inWindowDue };
}

test.describe('Care item absence review', () => {
  test('In-window care can be rescheduled or skipped from occurrence review during planned absence', async ({
    page,
  }) => {
    test.setTimeout(120_000);
    const root = baseURL();
    const { user, pet, entry } = await seedAbsenceInWindowCare(root, {
      petName: 'AbsenceSkipPet',
      entryName: 'Absence Window Grooming',
      carerName: 'Jamie Sitter',
    });

    await loginAs(page, user, { experience: 'guardian' });

    const careItem = new CareItemPage(page);
    await careItem.open(pet.id, entry.id);
    await careItem.expectAbsenceSectionVisible();
    await careItem.openAbsenceOccurrenceReview();
    await careItem.skipFromOccurrenceReviewSheet();
    await careItem.expectAbsenceReviewActionsHidden();
  });

  test('Care item absence strip shows Keep with carer and Review date opens the date directly', async ({
    page,
  }) => {
    test.setTimeout(120_000);
    const root = baseURL();
    const carerName = 'Alex Carer';
    const { user, pet, entry } = await seedAbsenceInWindowCare(root, {
      petName: 'AbsenceStripPet',
      entryName: 'Strip Review Grooming',
      carerName,
    });

    await loginAs(page, user, { experience: 'guardian' });

    const careItem = new CareItemPage(page);
    await careItem.open(pet.id, entry.id);
    await careItem.expectAbsenceSectionVisible();
    await careItem.expectAbsenceKeepWithCarer(carerName);
    await careItem.expectAbsenceReviewDateAction();
    await careItem.openAbsenceOccurrenceReview();
    await careItem.openChangeDateFromOccurrenceReview();
  });

  test('@smoke-uat Moving care after the trip postpones it to the day after return', async ({
    page,
  }) => {
    test.setTimeout(120_000);
    const root = baseURL();
    const { user, pet, entry, absence, endsOn } = await seedAbsenceInWindowCare(root, {
      petName: 'MoveAfterPet',
      entryName: 'Flea during trip',
      carerName: 'Trip Sitter',
    });
    const end = new Date(`${endsOn}T12:00:00Z`);
    end.setUTCDate(end.getUTCDate() + 1);
    const dayAfterReturn = end.toISOString().slice(0, 10);

    await postpone(root, user.accessToken, entry.id, dayAfterReturn, {
      reason: 'absence',
      absenceId: absence.id,
    });

    await loginAs(page, user, { experience: 'guardian' });

    const careItem = new CareItemPage(page);
    await careItem.open(pet.id, entry.id);

    const item = await getCareItem(root, user.accessToken, entry.id);
    const openOcc = item.open_occurrences[0];
    expect(openOcc?.scheduled_date).toBe(dayAfterReturn);
    await expect(
      page.locator(`[flt-semantics-identifier="care_item_occurrence_row_${openOcc?.id}"]`),
    ).toBeVisible({ timeout: 30_000 });
  });

  test('A date planned during the trip can be looked after by the carer', async ({ page }) => {
    test.setTimeout(120_000);
    const root = baseURL();
    const carerName = 'Carol';
    const user = await signupUser(root);
    const pet = await createPet(root, user.accessToken, 'PlannedTripPet');
    const startsOn = dateOffset(7);
    const endsOn = dateOffset(14);
    const beforeTripDue = dateOffset(3);
    const duringTrip = dateOffset(10);
    const entry = await createHealthEntry(root, user.accessToken, pet.id, {
      name: 'Trip grooming',
      nextDueDate: beforeTripDue,
      frequency: 'weekly',
      frequencyDays: 7,
      careFamily: 'grooming',
    });
    const absence = await createPlannedAbsence(root, user.accessToken, {
      startsOn,
      endsOn,
      petIds: [pet.id],
    });
    await updatePlannedAbsence(root, user.accessToken, absence.id, {
      petCarers: [
        {
          petId: pet.id,
          carerKind: 'note_only',
          carerName,
          carerNote: 'House key in lockbox',
        },
      ],
    });
    await planAnotherDate(root, user.accessToken, entry.id, duringTrip);

    await loginAs(page, user, { experience: 'guardian' });

    const careItem = new CareItemPage(page);
    await careItem.open(pet.id, entry.id);
    await careItem.expectAbsenceSectionVisible();
    await careItem.tapAbsenceKeepWithCarer(carerName);

    const context = await getHealthEntryAbsenceContext(root, user.accessToken, entry.id);
    const slice = context.absences.find((a) => a.planned_absence_id === absence.id);
    expect(slice?.planned_care?.looked_after_by?.carer_name).toBe(carerName);
    expect(slice?.planned_care?.planned_dates).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          scheduled_date: duringTrip,
          occurrence_id: expect.any(String),
        }),
      ]),
    );
  });
});
