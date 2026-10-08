/**
 * @bdd weight_tracking.feature
 * Scenario: Skipping a weigh-in with a reason
 * Scenario: Completing a weigh-in in pounds
 * Scenario: Care item view shows the weight section
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { CareAgendaPage } from '../pages/care-agenda.page';
import { CareItemPage } from '../pages/care-item.page';
import { GuardianDashboardPage } from '../pages/guardian-dashboard.page';
import { OccurrencePage } from '../pages/occurrence.page';
import { WeightCarePage } from '../pages/weight-care.page';
import { createCareItem, getOccurrence, withCareClock } from '../support/care-api';
import { createPet, getWeightEntries, updateUserProfile } from '../support/api';

test.describe('Weight care (occurrence + care item)', () => {
  test('Skipping a weigh-in with a reason', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const today = '2026-07-08';
    await withCareClock(`${today}T09:00`, page);
    try {
      const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
      const entry = await createCareItem(baseURL, testUser.accessToken, pet.id, {
        name: 'Monthly weigh-in',
        careFamily: 'weight_monitoring',
        frequency: 'monthly',
        dueDate: today,
        startDate: today,
      });
      const occurrenceId = entry.open_occurrences[0]?.id;
      expect(occurrenceId).toBeTruthy();

      await loginAs(page, testUser, { experience: 'guardian' });
      const dashboard = new GuardianDashboardPage(page);
      await dashboard.open();
      const agenda = new CareAgendaPage(page);
      await agenda.openRow(entry.id, 'Monthly weigh-in');
      const careItem = new CareItemPage(page);
      await careItem.expectNeedsAttentionVisible();
      await careItem.openOccurrenceFromNeedsAttention(occurrenceId!);

      const occurrence = new OccurrencePage(page);
      await occurrence.expectLoaded();
      await occurrence.tapSkip();
      await occurrence.expectSkipWeighInSheet();
      await occurrence.selectSkipReason(/Couldn't weigh|Impossible de peser/i);
      await occurrence.fillSkipNote('Too wiggly');
      await occurrence.confirmSkipWeighIn();

      const occDetail = await getOccurrence(
        baseURL,
        testUser.accessToken,
        entry.id,
        occurrenceId!,
      );
      expect((occDetail.occurrence as { status?: string }).status).toBe('skipped');

      await occurrence.expectSkippedWeighIn(/Couldn't weigh|Impossible de peser/i);
    } finally {
      await withCareClock(null, page);
    }
  });

  test('Completing a weigh-in in pounds', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const today = '2026-07-09';
    await updateUserProfile(baseURL, testUser.accessToken, { weight_unit: 'lb' });
    await withCareClock(`${today}T10:00`, page);
    try {
      const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
      const entry = await createCareItem(baseURL, testUser.accessToken, pet.id, {
        name: 'Lb weigh-in',
        careFamily: 'weight_monitoring',
        frequency: 'monthly',
        dueDate: today,
        startDate: today,
      });
      const occurrenceId = entry.open_occurrences[0]?.id;
      expect(occurrenceId).toBeTruthy();

      await loginAs(page, testUser, { experience: 'guardian' });
      const dashboard = new GuardianDashboardPage(page);
      await dashboard.open();
      const agenda = new CareAgendaPage(page);
      await agenda.markDone(entry.id);

      const occurrence = new OccurrencePage(page);
      await occurrence.expectLoaded();
      await occurrence.expectWeightFieldUnit('lb');
      await occurrence.fillWeight('22.0', 'lb');
      await occurrence.expectDoneEnabled();
      await occurrence.markDone();

      const occDetail = await getOccurrence(
        baseURL,
        testUser.accessToken,
        entry.id,
        occurrenceId!,
      );
      expect((occDetail.occurrence as { status?: string }).status).toBe('completed');

      const entries = await getWeightEntries(baseURL, testUser.accessToken, pet.id);
      expect(entries).toHaveLength(1);
      // Occurrence complete-weight stores canonical kg on the wire (22 lb ≈ 9.98 kg).
      expect(entries[0].weight).toBeCloseTo(9.98, 1);
      expect(entries[0].unit).toBe('kg');
      expect(entries[0].health_occurrence_id).toBe(occurrenceId);
    } finally {
      await withCareClock(null, page);
      await updateUserProfile(baseURL, testUser.accessToken, { weight_unit: 'kg' });
    }
  });

  test('Care item view shows the weight section', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const today = '2026-07-10';
    await withCareClock(`${today}T08:00`, page);
    try {
      const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
      const entry = await createCareItem(baseURL, testUser.accessToken, pet.id, {
        name: 'Routine weigh-in',
        careFamily: 'weight_monitoring',
        frequency: 'monthly',
        dueDate: today,
        startDate: today,
      });

      await loginAs(page, testUser, { experience: 'guardian' });
      const weightCare = new WeightCarePage(page);
      await weightCare.open(pet.id, entry.id);
      await weightCare.expectWeightSectionVisible();
    } finally {
      await withCareClock(null, page);
    }
  });
});
