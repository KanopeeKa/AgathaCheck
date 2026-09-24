/**
 * @bdd away_care_planning.feature
 * Scenario: Overdue open care shows its date on the away plan
 * Scenario: Completion-based care shows an estimated date on the away plan
 * Scenario: Changing a care date from the care item updates the next dates
 * Scenario: Accepting a planner suggestion reduces carer tasks during the absence
 */
import { test, loginAs, expect } from '../fixtures/auth.fixture';
import { AwayPlanningPage } from '../pages/away-planning.page';
import { CareItemPage } from '../pages/care-item.page';
import {
  createHealthEntry,
  createPet,
  createPlannedAbsence,
  getAbsenceCarePlan,
  seedPlannerOccurrenceChain,
  signupUser,
  type TestUser,
} from '../support/api';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

const dateOffset = (days: number): string => {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
};

test.describe.configure({ mode: 'serial' });

test.describe('Away care planning display', () => {
  let seededUser: TestUser;

  test.beforeAll(async () => {
    seededUser = await signupUser(baseURL());
  });

  test('Overdue open care shows its date on the away plan', async ({ page }) => {
    const root = baseURL();
    const user = seededUser;
    const pet = await createPet(root, user.accessToken, 'OverduePlanPet');
    const overdueDate = dateOffset(-3);
    const startsOn = dateOffset(7);
    const endsOn = dateOffset(14);
    const entry = await createHealthEntry(root, user.accessToken, pet.id, {
      name: 'Overdue Rabies Booster',
      nextDueDate: overdueDate,
      frequency: 'monthly',
      frequencyDays: 30,
      careFamily: 'vaccination',
    });
    const absence = await createPlannedAbsence(root, user.accessToken, {
      startsOn,
      endsOn,
      petIds: [pet.id],
    });

    await loginAs(page, user, { experience: 'guardian' });

    const away = new AwayPlanningPage(page);
    await away.openPlan(absence.id);
    await away.expectPlannedCareItemRow(entry.id, 'Overdue Rabies Booster');
    await away.expectPlannedCareRowShowsOverdue(
      entry.id,
      'Overdue Rabies Booster',
      /Overdue|En retard/i,
    );
    await expect(page.getByText(/Timing not yet known|Horaire pas encore connu/i)).toHaveCount(0);
  });

  test('Completion-based care shows an estimated date on the away plan', async ({ page }) => {
    const root = baseURL();
    const user = seededUser;
    const pet = await createPet(root, user.accessToken, 'EstimatedPlanPet');
    const startsOn = dateOffset(10);
    const endsOn = dateOffset(17);
    const inWindowDue = dateOffset(12);
    const entry = await createHealthEntry(root, user.accessToken, pet.id, {
      name: 'Weekly Grooming',
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

    await loginAs(page, user, { experience: 'guardian' });

    const away = new AwayPlanningPage(page);
    await away.openPlan(absence.id);
    await away.expectPlannedCareItemRow(entry.id, 'Weekly Grooming');
    await away.expectPlannedCareRowShowsEstimated(entry.id, 'Weekly Grooming');
  });

  test('Changing a care date from the care item updates the next dates', async ({ page }) => {
    const root = baseURL();
    const user = seededUser;
    const pet = await createPet(root, user.accessToken, 'ReschedulePet');
    const overdueDate = dateOffset(-2);
    const startsOn = dateOffset(7);
    const endsOn = dateOffset(14);
    const entry = await createHealthEntry(root, user.accessToken, pet.id, {
      name: 'Vaccination Series',
      nextDueDate: overdueDate,
      frequency: 'monthly',
      frequencyDays: 30,
      careFamily: 'vaccination',
    });
    const absence = await createPlannedAbsence(root, user.accessToken, {
      startsOn,
      endsOn,
      petIds: [pet.id],
    });

    await loginAs(page, user, { experience: 'guardian' });

    const away = new AwayPlanningPage(page);
    const careItem = new CareItemPage(page);
    await away.openPlan(absence.id);
    await away.openPlanThis(entry.id);
    await careItem.pickRescheduleDateInSheet(5);
    await careItem.expectReschedulePreviewNextDates();
    await careItem.confirmReschedule();
    await away.openPlan(absence.id);
    await away.expectPlannedCareItemRow(entry.id, 'Vaccination Series');
    await expect(page.getByText(/Overdue|En retard/i)).toHaveCount(0);
  });

  test('Accepting a planner suggestion reduces carer tasks during the absence', async ({
    page,
  }) => {
    const root = baseURL();
    const user = seededUser;
    const pet = await createPet(root, user.accessToken, 'PlannerPet');
    const startsOn = dateOffset(7);
    const endsOn = dateOffset(14);
    const entry = await createHealthEntry(root, user.accessToken, pet.id, {
      name: 'Weekly Grooming',
      nextDueDate: dateOffset(0),
      frequency: 'weekly',
      frequencyDays: 7,
      careFamily: 'grooming',
    });
    seedPlannerOccurrenceChain(entry.id, dateOffset(0), dateOffset(-7));
    const absence = await createPlannedAbsence(root, user.accessToken, {
      startsOn,
      endsOn,
      petIds: [pet.id],
    });
    const planBefore = await getAbsenceCarePlan(root, user.accessToken, absence.id);
    const petPlan = planBefore.pets.find((p) => p.pet_id === pet.id);
    const suggestion = petPlan?.suggestions?.[0];
    const countBefore = petPlan?.carer_tasks.count ?? 0;
    const inWindowBefore =
      suggestion?.in_window_before ?? countBefore;
    expect(inWindowBefore).toBeGreaterThan(0);
    if (suggestion) {
      expect(suggestion.in_window_after).toBeLessThan(suggestion.in_window_before);
    }

    await loginAs(page, user, { experience: 'guardian' });

    const away = new AwayPlanningPage(page);
    const careItem = new CareItemPage(page);
    await away.openPlan(absence.id);
    await away.expectPlannerSectionVisible(pet.id);

    const acceptVisible = await page
      .getByRole('button', { name: /^Accept$|^Accepter$/i })
      .first()
      .isVisible()
      .catch(() => false);
    if (acceptVisible) {
      await away.acceptPlannerSuggestion();
    } else {
      await away.openPlanThis(entry.id);
      await careItem.expectReschedulePreviewNextDates();
      await careItem.confirmReschedule();
    }

    await away.openPlan(absence.id);
    await expect(async () => {
      const planAfter = await getAbsenceCarePlan(root, user.accessToken, absence.id);
      const afterPet = planAfter.pets.find((p) => p.pet_id === pet.id);
      const afterCount = afterPet?.carer_tasks.count ?? 0;
      const afterSuggestions = afterPet?.suggestions?.length ?? 0;
      const workloadAfter = afterCount + afterSuggestions;
      expect(workloadAfter).toBeLessThan(inWindowBefore);
    }).toPass({ timeout: 15_000 });
    await away.expectPlannedCareItemRow(entry.id, 'Weekly Grooming');
  });
});
