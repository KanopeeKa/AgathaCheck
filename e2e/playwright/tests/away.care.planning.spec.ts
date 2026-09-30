/**
 * @bdd away_care_planning.feature
 * Scenario: Pre-departure overdue care links to the pet profile instead of listing on the plan
 * Scenario: After-it's-done care shows an estimated date on the away plan
 * Scenario: Changing a care date from the care item updates the next dates
 * Scenario: In-window care shows on the away plan during the absence
 * Scenario: Care done before the trip still appears on the away plan
 */
import { test, loginAs, expect } from '../fixtures/auth.fixture';
import { AwayPlanningPage } from '../pages/away-planning.page';
import { CareItemPage } from '../pages/care-item.page';
import {
  createHealthEntry,
  createPet,
  createPlannedAbsence,
  signupUser,
  type TestUser,
} from '../support/api';
import {
  completeNextOccurrence,
  createCareItem,
  getCareItem,
  getCarePeriodCoverage,
  withCareClock,
} from '../support/care-api';

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

  test('Pre-departure overdue care links to the pet profile instead of listing on the plan', async ({
    page,
  }) => {
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
    await away.expectPreAbsenceOverdueAction(pet.id);
    await away.expectPlannedCareItemRowHidden(entry.id, 'Overdue Rabies Booster');
    await expect(page.getByText(/Timing not yet known|Horaire pas encore connu/i)).toHaveCount(0);
  });

  test("After-it's-done care shows an estimated date on the away plan", async ({ page }) => {
    const root = baseURL();
    const user = seededUser;
    const pet = await createPet(root, user.accessToken, 'EstimatedPlanPet');
    const startsOn = dateOffset(10);
    const endsOn = dateOffset(14);
    const estimatedDate = dateOffset(10);
    // An open date before departure projects an estimated later hop in the
    // window. Keep the trip shorter than two intervals so the UI shows the
    // single date's "Estimated:" label rather than a multi-date range.
    const beforeDepartureDue = dateOffset(3);
    const entry = await createCareItem(root, user.accessToken, pet.id, {
      name: 'Weekly Grooming',
      dueDate: beforeDepartureDue,
      frequency: 'weekly',
      careFamily: 'grooming',
      scheduleType: 'from_completion',
    });
    const absence = await createPlannedAbsence(root, user.accessToken, {
      startsOn,
      endsOn,
      petIds: [pet.id],
    });
    const open = (await getCareItem(root, user.accessToken, entry.id)).open_occurrences[0];
    expect(open?.scheduled_date).toBe(beforeDepartureDue);
    const coverage = await getCarePeriodCoverage(root, user.accessToken, pet.id, startsOn, endsOn);
    // The projection's raw items include only the real open date. A
    // completion-dependent estimate is carried on the row's in_window contract,
    // not invented as an occurrence or as a projected raw item.
    expect(coverage.items).toEqual(expect.arrayContaining([
      expect.objectContaining({
        health_entry_id: entry.id,
        occurrence_id: open.id,
        scheduled_date: beforeDepartureDue,
        source: 'materialised',
      }),
    ]));
    expect(coverage.items.filter((item) => item.health_entry_id === entry.id
      && item.scheduled_date === estimatedDate)).toHaveLength(0);
    expect(coverage.planned_care_items.find((row) => row.health_entry_id === entry.id)?.in_window)
      .toEqual(expect.objectContaining({
        first_date: estimatedDate,
        last_date: estimatedDate,
        count: 1,
        date_basis: 'estimated',
      }));

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
      name: 'Grooming Series',
      nextDueDate: overdueDate,
      frequency: 'monthly',
      frequencyDays: 30,
      careFamily: 'grooming',
    });
    const absence = await createPlannedAbsence(root, user.accessToken, {
      startsOn,
      endsOn,
      petIds: [pet.id],
    });

    await loginAs(page, user, { experience: 'guardian' });

    const away = new AwayPlanningPage(page);
    const careItem = new CareItemPage(page);
    await careItem.open(pet.id, entry.id);
    await careItem.openRescheduleSheet();
    await careItem.pickRescheduleDateInSheet(5);
    await careItem.confirmReschedule();
    await away.openPlan(absence.id);
    await expect(page.getByText(/Overdue|En retard/i)).toHaveCount(0);
  });

  test('In-window care shows on the away plan during the absence', async ({
    page,
  }) => {
    const root = baseURL();
    const user = seededUser;
    const pet = await createPet(root, user.accessToken, 'PlannerPet');
    const startsOn = dateOffset(7);
    const endsOn = dateOffset(14);
    const inWindowDue = dateOffset(10);
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
  });

  test('Care done before the trip still appears on the away plan', async ({ page }) => {
    const root = baseURL();
    const user = seededUser;
    const pet = await createPet(root, user.accessToken, 'BeforeTripPet');
    const today = dateOffset(0);
    const startsOn = dateOffset(5);
    const endsOn = dateOffset(12);
    await withCareClock(`${today}T12:00`, page);
    try {
      const entry = await createCareItem(root, user.accessToken, pet.id, {
        name: 'Weekly coat care',
        careFamily: 'grooming',
        frequency: 'weekly',
        dueDate: today,
        scheduleType: 'from_completion',
      });
      const first = (await getCareItem(root, user.accessToken, entry.id)).open_occurrences[0];
      expect(first?.scheduled_date).toBe(today);
      await completeNextOccurrence(root, user.accessToken, entry.id, { completedOn: today });
      const next = (await getCareItem(root, user.accessToken, entry.id)).open_occurrences[0];
      expect(next?.id).toBeTruthy();
      expect(next.scheduled_date).toBe(dateOffset(7));
      expect(next.id).not.toBe(first.id);

      const absence = await createPlannedAbsence(root, user.accessToken, {
        startsOn,
        endsOn,
        petIds: [pet.id],
      });
      const coverage = await getCarePeriodCoverage(root, user.accessToken, pet.id, startsOn, endsOn);
      expect(coverage.items).toEqual(expect.arrayContaining([
        expect.objectContaining({
          health_entry_id: entry.id,
          occurrence_id: next.id,
          scheduled_date: next.scheduled_date,
          source: 'materialised',
        }),
      ]));
      expect(coverage.planned_care_items.some((row) => row.health_entry_id === entry.id)).toBe(true);

      await loginAs(page, user, { experience: 'guardian' });
      const away = new AwayPlanningPage(page);
      await away.openPlan(absence.id);
      await away.expectPlannedCareItemRow(entry.id, 'Weekly coat care');
    } finally {
      await withCareClock(null, page);
    }
  });
});
