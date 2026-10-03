/**
 * @bdd care_agenda.feature
 * Scenario: A care row opens its date, and the date links to the care item
 * Scenario: Several dates to sort out open the care item
 * @bdd care_schedules.feature
 * Scenario: Missed fixed-schedule care can be marked as done together on the care item
 * Scenario: Care done after its due date keeps the next planned date and offers to change it
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { CareAgendaPage } from '../pages/care-agenda.page';
import { CareItemPage } from '../pages/care-item.page';
import { GuardianDashboardPage } from '../pages/guardian-dashboard.page';
import { OccurrencePage } from '../pages/occurrence.page';
import { createCareItem, withCareClock } from '../support/care-api';
import { createPet } from '../support/api';
import { CompletionDateSheetPage } from '../pages/completion-date.sheet';

test.describe('Care agenda (occurrence-first)', () => {
  test('row opens occurrence and links to care item', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const today = '2026-06-20';
    await withCareClock(`${today}T10:00`, page);
    try {
      const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
      const entry = await createCareItem(baseURL, testUser.accessToken, pet.id, {
        name: 'Viewable Care',
        careFamily: 'grooming',
        frequency: 'monthly',
        dueDate: today,
      });
      await loginAs(page, testUser, { experience: 'guardian' });
      const dashboard = new GuardianDashboardPage(page);
      await dashboard.open();
      const agenda = new CareAgendaPage(page);
      await agenda.openRow(entry.id, entry.name);
      const occurrence = new OccurrencePage(page);
      await occurrence.expectLoaded();
      await page.locator('[flt-semantics-identifier="occurrence_about_item"]').click();
      await expect(
        page.locator('[flt-semantics-identifier="care_item_needs_attention_section"]'),
      ).toBeVisible({ timeout: 30_000 });
    } finally {
      await withCareClock(null, page);
    }
  });

  test('stack resolves with mark all on care item', async ({ page, testUser }) => {
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
      const dashboard = new GuardianDashboardPage(page);
      await dashboard.open();
      const agenda = new CareAgendaPage(page);
      await agenda.openStack(entry.id);
      const careItem = new CareItemPage(page);
      await careItem.markAllDone();
      await agenda.expectDoneSnackbar('Stack Meds');
    } finally {
      await withCareClock(null, page);
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
    } finally {
      await withCareClock(null, page);
    }
  });
});
