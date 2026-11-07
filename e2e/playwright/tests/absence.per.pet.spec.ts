/**
 * @bdd away_planning.feature
 * Scenario: Away planning hub shows Your absences for an owned absence
 */
import { test, loginAs } from '../fixtures/auth.fixture';
import { AwayPlanningPage } from '../pages/away-planning.page';
import { createPet, createPlannedAbsence } from '../support/api';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

const dateOffset = (days: number): string => {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
};

test.describe('Per-pet away plans', () => {
  test('Away planning hub lists a saved upcoming absence (ownership sections)', async ({
    page,
    testUser,
  }) => {
    const root = baseURL();
    const pet = await createPet(root, testUser.accessToken, 'HubOwnPet');
    await createPlannedAbsence(root, testUser.accessToken, {
      petIds: [pet.id],
      startsOn: dateOffset(7),
      endsOn: dateOffset(14),
    });
    await loginAs(page, testUser, { experience: 'guardian' });

    const away = new AwayPlanningPage(page);
    await away.openHub();
    await away.expectHubLoaded();
    await away.expectYourAbsencesSection();
    await away.expectHubCardForAbsence('HubOwnPet');
  });
});
