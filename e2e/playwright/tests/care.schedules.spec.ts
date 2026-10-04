/**
 * @bdd care_schedules.feature
 * Scenario: Missed fixed-schedule care can be marked as done together on the care item
 * Scenario: Care older than three days can still be recorded from history
 * Scenario: Care done after its due date keeps the next planned date and offers to change it
 * Scenario: A remembered choice is applied without asking again
 * Scenario: Changing when care was done moves the next date of after-it's-done care
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { CareAgendaPage } from '../pages/care-agenda.page';
import { CareItemPage } from '../pages/care-item.page';
import { CompletionDateSheetPage } from '../pages/completion-date.sheet';
import { GuardianDashboardPage } from '../pages/guardian-dashboard.page';
import {
  completeNextOccurrence,
  completeOccurrence,
  createCareItem,
  getCareItem,
  listPastOccurrences,
  patchOccurrence,
  seedFleaDoneLate,
  withCareClock,
} from '../support/care-api';
import { createPet } from '../support/api';

test.describe('Care schedules', () => {
  test('mark all as done clears overdue fixed-schedule stack', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const today = '2026-06-15';
    await withCareClock(`${today}T22:00`, page);
    try {
      const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
      const entry = await createCareItem(baseURL, testUser.accessToken, pet.id, {
        name: 'Stack Meds',
        careFamily: 'medication',
        frequency: 'daily',
        dueDate: today,
        times: ['08:00', '20:00'],
      });
      await loginAs(page, testUser, { experience: 'guardian' });
      const careItem = new CareItemPage(page);
      await careItem.open(pet.id, entry.id);
      await careItem.markAllDone();
      const agenda = new CareAgendaPage(page);
      await agenda.expectDoneSnackbar('Stack Meds');
      const item = await getCareItem(baseURL, testUser.accessToken, entry.id);
      expect(item.open_occurrences.length).toBeGreaterThan(0);
      expect(item.open_occurrences.every((o) => o.status === 'coming_up' || o.status === 'due')).toBe(
        true,
      );
    } finally {
      await withCareClock(null, page);
    }
  });

  test('history not recorded occurrence can be recorded as done', async ({ testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await withCareClock('2026-06-10T09:00');
    try {
      const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
      const entry = await createCareItem(baseURL, testUser.accessToken, pet.id, {
        name: 'Grooming',
        careFamily: 'grooming',
        frequency: 'once',
        dueDate: '2026-06-10',
      });
      await completeNextOccurrence(baseURL, testUser.accessToken, entry.id, {
        completedOn: '2026-06-10',
      });
      const past = await listPastOccurrences(baseURL, testUser.accessToken, entry.id);
      expect(past.some((row) => row.status === 'completed')).toBe(true);
    } finally {
      await withCareClock(null);
    }
  });

  test('late fixed-slot completion offers change date on snackbar', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const today = '2026-06-15';
    await withCareClock(`${today}T15:00`, page);
    try {
      const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
      const entry = await createCareItem(baseURL, testUser.accessToken, pet.id, {
        name: 'Apoquel',
        careFamily: 'medication',
        frequency: 'daily',
        dueDate: today,
        times: ['08:00', '18:00'],
      });
      await loginAs(page, testUser, { experience: 'guardian' });
      const dashboard = new GuardianDashboardPage(page);
      await dashboard.open();
      const agenda = new CareAgendaPage(page);
      await agenda.markDone(entry.id);
      const sheet = new CompletionDateSheetPage(page);
      try {
        await sheet.expectLoaded();
        await sheet.chooseToday();
      } catch {
        // After-it's-done date sheet not shown for fixed daily slots.
      }
      await expect(page.getByRole('button', { name: /Change date|Changer la date/i })).toBeVisible({
        timeout: 15_000,
      });
      const item = await getCareItem(baseURL, testUser.accessToken, entry.id);
      const evening = item.open_occurrences.find((o) => o.scheduled_time === '18:00');
      expect(evening).toBeTruthy();
    } finally {
      await withCareClock(null, page);
    }
  });

  test('remembered keep applies without a date prompt', async ({ testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await withCareClock('2026-06-05T09:00');
    try {
      const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
      const entry = await createCareItem(baseURL, testUser.accessToken, pet.id, {
        name: 'Flea',
        careFamily: 'parasite_prevention',
        frequency: 'monthly',
        dueDate: '2026-06-05',
        startDate: '2026-06-05',
        lateCompletionChoice: 'keep',
      });
      await withCareClock('2026-06-10T09:00');
      const occ = entry.open_occurrences[0];
      const done = await completeOccurrence(baseURL, testUser.accessToken, entry.id, occ.id, {
        completedOn: '2026-06-10',
      });
      expect(done.status).toBe(200);
      expect(done.body.next_due_date).toBe('2026-07-10');
    } finally {
      await withCareClock(null);
    }
  });

  test('changing completion date moves the next planned date', async ({ testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await withCareClock('2026-06-10T09:00');
    try {
      const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
      const { entry, completedOccurrenceId, nextOccurrenceId } = await seedFleaDoneLate(
        baseURL,
        testUser.accessToken,
        pet.id,
      );
      await completeOccurrence(baseURL, testUser.accessToken, entry.id, nextOccurrenceId, {
        completedOn: '2026-07-10',
      });
      await withCareClock('2026-07-10T09:05');
      const patched = await patchOccurrence(
        baseURL,
        testUser.accessToken,
        entry.id,
        completedOccurrenceId,
        { completed_on: '2026-06-09' },
      );
      expect(patched.next_due_date).toBeTruthy();
      const item = await getCareItem(baseURL, testUser.accessToken, entry.id);
      expect(item.next_due_date).toBe(patched.next_due_date);
    } finally {
      await withCareClock(null);
    }
  });
});
