/**
 * @bdd away_care_planning.feature
 * Scenario: Overdue open care shows its date on the away plan
 */
import { test, loginAs, expect } from '../fixtures/auth.fixture';
import { AwayPlanningPage } from '../pages/away-planning.page';
import {
  createHealthEntry,
  createPet,
  createPlannedAbsence,
  signupUser,
} from '../support/api';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

const dateOffset = (days: number): string => {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
};

test.describe('Away care planning display', () => {
  test('Overdue open care shows its date on the away plan', async ({ page }) => {
    const root = baseURL();
    const user = await signupUser(root);
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
    await away.expectPlannedCareRowShowsOverdue(entry.id, /Overdue|En retard/i);
    await expect(page.getByText(/Timing not yet known|Horaire pas encore connu/i)).toHaveCount(0);
  });
});
