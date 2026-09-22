/**
 * @bdd away_plan_detail_v2.feature
 * Scenario: Away plan page hides coverage headers when carers and care are reassured
 * Scenario: Away plan planned care row opens care item detail
 * Scenario: Guardian can save handover note and delete away plan from edit screen
 */
import { test, loginAs, expect } from '../fixtures/auth.fixture';
import { AwayPlanningPage } from '../pages/away-planning.page';
import {
  createHealthEntry,
  createPet,
  createPlannedAbsence,
  signupUser,
  updatePlannedAbsence,
} from '../support/api';
import { refreshFlutterAccessibility, waitForFlutterRoutePattern } from '../support/flutter';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

const dateOffset = (days: number): string => {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
};

test.describe('Away plan detail V2', () => {
  test('Away plan page hides coverage headers when carers and care are reassured', async ({
    page,
  }) => {
    const root = baseURL();
    const user = await signupUser(root);
    const pet = await createPet(root, user.accessToken, 'ReassuredPet');
    const startsOn = dateOffset(7);
    const endsOn = dateOffset(14);
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
          carerName: 'Jane Sitter',
          carerNote: 'Has house keys',
        },
      ],
    });

    await loginAs(page, user, { experience: 'guardian' });

    const away = new AwayPlanningPage(page);
    await away.openPlan(absence.id);
    await away.expectCoverageHeadersHidden();
  });

  test('Away plan planned care row opens care item detail', async ({ page }) => {
    const root = baseURL();
    const user = await signupUser(root);
    const pet = await createPet(root, user.accessToken, 'CareListPet');
    const startsOn = dateOffset(7);
    const endsOn = dateOffset(14);
    const dueDate = dateOffset(10);
    const entry = await createHealthEntry(root, user.accessToken, pet.id, {
      name: 'Away Window Meds',
      nextDueDate: dueDate,
      frequency: 'once',
    });
    const absence = await createPlannedAbsence(root, user.accessToken, {
      startsOn,
      endsOn,
      petIds: [pet.id],
    });

    await loginAs(page, user, { experience: 'guardian' });

    const away = new AwayPlanningPage(page);
    await away.openPlan(absence.id);
    await away.expectPlannedCareItemRow(entry.id, 'Away Window Meds');
    await away.openPlannedCareItem(entry.id);

    await waitForFlutterRoutePattern(page, /\/pet\/[^/]+\/events\/[^/?#]+/, 45_000);
    await refreshFlutterAccessibility(page);
    await expect(page.getByText('Away Window Meds', { exact: false }).first()).toBeVisible({
      timeout: 15_000,
    });
  });

  test('Guardian can save handover note and delete away plan from edit screen', async ({
    page,
  }) => {
    const root = baseURL();
    const user = await signupUser(root);
    const pet = await createPet(root, user.accessToken, 'EditFlowPet');
    const absence = await createPlannedAbsence(root, user.accessToken, {
      startsOn: dateOffset(5),
      endsOn: dateOffset(12),
      petIds: [pet.id],
    });
    const note = 'Leave extra food in the pantry';

    await loginAs(page, user, { experience: 'guardian' });

    const away = new AwayPlanningPage(page);
    await away.openPlan(absence.id);
    await away.openEditScreen();
    await away.fillHandoverNote(note);
    await away.saveEdit();
    await away.expectHandoverNoteOnPlan(note);

    await away.openEditScreen();
    await away.deleteAwayPlan();
    await away.expectAbsenceNotListed('EditFlowPet');
    await away.expectEmptyHub();
  });
});
