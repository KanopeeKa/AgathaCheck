/**
 * @bdd away_planning.feature
 * Scenario: Co-parent sees only their pet pill and no trip Edit
 * Scenario: Co-parent edits the pet note on the away plan page
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { AwayPlanningPage } from '../pages/away-planning.page';
import { PetListPage } from '../pages/pet-list.page';
import { PeoplePage } from '../pages/people.page';
import {
  createPet,
  createPlannedAbsence,
  patchPerPetAwayPlan,
  seedCoParentOnPet,
  signupUser,
} from '../support/api';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

const dateOffset = (days: number): string => {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
};

async function seedFrederiqueAndDave(base: string) {
  const frederique = await signupUser(base, {
    firstName: 'Frederique',
    lastName: 'Guardian',
  });
  const dave = await signupUser(base, {
    firstName: 'Dave',
    lastName: 'CoParent',
  });
  const buddy = await createPet(base, frederique.accessToken, 'Buddy', 'Dog');
  const whiskers = await createPet(base, frederique.accessToken, 'Whiskers', 'Cat');
  const pebble = await createPet(base, frederique.accessToken, 'Pebble', 'Dog');
  await seedCoParentOnPet(base, frederique, dave, buddy.id);
  const absence = await createPlannedAbsence(base, frederique.accessToken, {
    startsOn: dateOffset(8),
    endsOn: dateOffset(15),
    petIds: [buddy.id, whiskers.id, pebble.id],
  });
  return { frederique, dave, buddy, whiskers, pebble, absence };
}

test.describe('Away plan journeys', () => {
  test('Reference: three-pet absence, pet plan, See absence returns to trip', async ({
    page,
    testUser,
  }) => {
    const root = baseURL();
    const a = await createPet(root, testUser.accessToken, 'RefA', 'Dog');
    const b = await createPet(root, testUser.accessToken, 'RefB', 'Dog');
    const c = await createPet(root, testUser.accessToken, 'RefC', 'Dog');
    await loginAs(page, testUser, { experience: 'guardian' });

    const away = new AwayPlanningPage(page);
    await away.openWizard();
    await away.pickAbsenceDates(dateOffset(9), dateOffset(16));
    await away.selectPet(a.id, a.name);
    await away.selectPet(b.id, b.name);
    await away.selectPet(c.id, c.name);
    await away.saveAbsence();
    await away.expectAbsenceScreenLoaded();
    await away.expectAbsencePetPillCount(3);

    const absenceMatch = page.url().match(/\/pc\/away\/([^/?#]+)/);
    const absenceId = absenceMatch?.[1];
    if (!absenceId) throw new Error('Expected absence id in URL');
    await away.openPetAwayPlan(absenceId, a.id);
    await away.clickSeeAbsence();
    await away.expectAbsenceScreenLoaded();
  });

  test('Reference journey on mobile viewport', async ({ page, testUser }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    const root = baseURL();
    const pet = await createPet(root, testUser.accessToken, 'MobPet', 'Dog');
    const absence = await createPlannedAbsence(root, testUser.accessToken, {
      startsOn: dateOffset(5),
      endsOn: dateOffset(12),
      petIds: [pet.id],
    });
    await loginAs(page, testUser, { experience: 'guardian' });
    const away = new AwayPlanningPage(page);
    await away.openPetAwayPlan(absence.id, pet.id);
    await away.expectPetAwayPlanScreen('MobPet', pet.id);
  });

  test('Co-parent Dave sees Frederique away, one pill, no Edit or Add pet', async ({ page }) => {
    const root = baseURL();
    const { dave, frederique, buddy, absence } = await seedFrederiqueAndDave(root);
    await loginAs(page, dave, { experience: 'guardian' });

    const away = new AwayPlanningPage(page);
    await away.openHub();
    await away.expectOtherPeoplesAbsencesHeading();
    await away.expectTravellerAwayLine('Frederique');
    await away.openAbsencePlan(absence.id);
    await away.expectAbsencePetPillCount(1);
    await away.expectTripEditHidden();
    await away.expectAddPetHidden();
    await away.openPetAwayPlan(absence.id, buddy.id);
    await away.savePetNote(buddy.id, 'Dave co-parent UI note');
  });

  test('Co-parent edits Buddy pet note and full-trip PDF succeeds', async ({ page }) => {
    const root = baseURL();
    const { dave, buddy, absence } = await seedFrederiqueAndDave(root);
    await patchPerPetAwayPlan(root, dave.accessToken, absence.id, buddy.id, {
      pet_note: 'Dave co-parent note',
    });
    await loginAs(page, dave, { experience: 'guardian' });

    const away = new AwayPlanningPage(page);
    await away.openAbsencePlan(absence.id);
    await away.triggerFullTripHandoverDownload();
  });

  test('Declarer adds and removes pets; last pet removes absence', async ({ page, testUser }) => {
    const root = baseURL();
    const keep = await createPet(root, testUser.accessToken, 'KeepPet', 'Dog');
    const extra = await createPet(root, testUser.accessToken, 'ExtraPet', 'Dog');
    const absence = await createPlannedAbsence(root, testUser.accessToken, {
      startsOn: dateOffset(6),
      endsOn: dateOffset(13),
      petIds: [keep.id],
    });
    await loginAs(page, testUser, { experience: 'guardian' });

    const away = new AwayPlanningPage(page);
    await away.openAbsencePlan(absence.id);
    await away.clickAddPetOnAbsence();
    await away.pickAddPetCandidate(extra.id);
    await away.expectAbsencePetPillCount(2);

    await away.openPetAwayPlan(absence.id, extra.id);
    await away.removePetFromAbsence(extra.id);
    await away.expectAbsencePetPillCount(1);

    await away.openPetAwayPlan(absence.id, keep.id);
    await away.removePetFromAbsence(keep.id);
    await away.openHub();
    await away.expectAbsenceNotListed('KeepPet');
  });

  test('Pet page shows away plan above People and opens plan', async ({ page, testUser }) => {
    const root = baseURL();
    const pet = await createPet(root, testUser.accessToken, 'PagePet', 'Dog');
    const absence = await createPlannedAbsence(root, testUser.accessToken, {
      startsOn: dateOffset(4),
      endsOn: dateOffset(11),
      petIds: [pet.id],
    });
    await loginAs(page, testUser, { experience: 'guardian' });

    const petList = new PetListPage(page);
    await petList.openPet('PagePet', pet.id);

    const away = new AwayPlanningPage(page);
    await away.expectPetPageAwayRow(absence.id);
    const people = new PeoplePage(page);
    await people.expectPeopleAroundPetSection('PagePet');
    await page.locator(`[flt-semantics-identifier="pet_page_away_row_${absence.id}"]`).click();
    await away.expectPetAwayPlanScreen('PagePet', pet.id);
  });
});
