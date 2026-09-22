/**
 * @bdd away_planning.feature
 * Scenario: Dashboard away planning tile opens the hub
 * Scenario: Guardian can save a planned absence from the wizard
 * Scenario: Away planning hub lists a saved upcoming absence
 * Scenario: Away plan page shows who is caring for each pet
 * Scenario: Guardian assigns a shared carer on the away plan page
 */
import { test, loginAs } from '../fixtures/auth.fixture';
import { AwayPlanningPage } from '../pages/away-planning.page';
import { GuardianDashboardPage } from '../pages/guardian-dashboard.page';
import { createPet, createPlannedAbsence, signupUser } from '../support/api';
import { flutterGotoUrl, refreshFlutterAccessibility } from '../support/flutter';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

const dateOffset = (days: number): string => {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
};

test.describe('Away planning', () => {
  test('Dashboard away planning tile opens the hub', async ({ page, testUser }) => {
    const root = baseURL();
    await createPet(root, testUser.accessToken, 'AwayPet');
    await loginAs(page, testUser, { experience: 'guardian' });

    const dashboard = new GuardianDashboardPage(page);
    await dashboard.open();

    const away = new AwayPlanningPage(page);
    await away.openFromDashboardTile();
    await away.expectHubLoaded();
    await away.expectEmptyHub();
  });

  test('Guardian can save a planned absence from the wizard', async ({ page, testUser }) => {
    const root = baseURL();
    const pet = await createPet(root, testUser.accessToken, 'WizardPet');
    await loginAs(page, testUser, { experience: 'guardian' });

    const away = new AwayPlanningPage(page);
    await away.openWizard();

    const startsOn = dateOffset(7);
    const endsOn = dateOffset(14);
    await away.pickAbsenceDates(startsOn, endsOn);
    await away.continueWizard();
    await away.selectPet(pet.id, pet.name);
    await away.continueWizard();
    await away.saveAbsence();

    await away.expectPlanPageLoaded();
    await away.expectWhoIsCaringSection();
    await away.expectPetCarerRow(pet.id, 'WizardPet', 'No carer assigned');
  });

  test('Away planning hub lists a saved upcoming absence', async ({ page, testUser }) => {
    const root = baseURL();
    const pet = await createPet(root, testUser.accessToken, 'HubPet');
    await createPlannedAbsence(root, testUser.accessToken, {
      startsOn: dateOffset(10),
      endsOn: dateOffset(17),
      petIds: [pet.id],
    });
    await loginAs(page, testUser, { experience: 'guardian' });

    const away = new AwayPlanningPage(page);
    await away.openHub();
    await away.expectHubLoaded();
    await away.expectUpcomingAbsenceVisible('HubPet');
  });

  test('Away plan page shows who is caring for each pet', async ({ page }) => {
    const root = baseURL();
    const user = await signupUser(root);
    const pet = await createPet(root, user.accessToken, 'PlanPet');
    const absence = await createPlannedAbsence(root, user.accessToken, {
      startsOn: dateOffset(5),
      endsOn: dateOffset(12),
      petIds: [pet.id],
    });
    await loginAs(page, user, { experience: 'guardian' });

    const away = new AwayPlanningPage(page);
    await page.goto(flutterGotoUrl(`/pc/away/${absence.id}`));
    await refreshFlutterAccessibility(page);

    await away.expectPlanPageLoaded();
    await away.expectWhoIsCaringSection();
    await away.expectPetCarerRow(pet.id, 'PlanPet', 'No carer assigned');
  });

  test.skip('Guardian assigns a shared carer on the away plan page', async () => {
    // TODO: implement when e2e has pet-sharing API helpers (share collaborator, assign carer, assert label).
  });
});
