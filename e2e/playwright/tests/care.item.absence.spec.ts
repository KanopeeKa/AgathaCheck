/**
 * @bdd care_item_absence.feature
 * Scenario: In-window care can be rescheduled or skipped from occurrence review during planned absence
 * Scenario: Care item absence strip shows Keep with carer and Review date opens occurrence review
 */
import { test, loginAs } from '../fixtures/auth.fixture';
import { CareItemPage } from '../pages/care-item.page';
import {
  createHealthEntry,
  createPet,
  createPlannedAbsence,
  signupUser,
  updatePlannedAbsence,
} from '../support/api';

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
  return { user, pet, entry, absence };
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

  test('Care item absence strip shows Keep with carer and Review date opens occurrence review', async ({
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
  });
});
