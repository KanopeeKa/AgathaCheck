/**
 * @bdd care_agenda.feature
 * Scenario: A care row opens its date, and the date links to the care item
 * Scenario: Care that needs a weight opens its date to enter the weight
 * Scenario: Several dates to sort out open the care item
 * Scenario: Upcoming care can be marked as done early
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { CareAgendaPage } from '../pages/care-agenda.page';
import { CareItemPage } from '../pages/care-item.page';
import { GuardianDashboardPage } from '../pages/guardian-dashboard.page';
import { OccurrencePage } from '../pages/occurrence.page';
import { createCareItem, withCareClock } from '../support/care-api';
import { createPet } from '../support/api';

test.describe('Care agenda (occurrence-first)', () => {
  test('row opens occurrence and links to care item', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const today = new Date().toISOString().slice(0, 10);
    await withCareClock(`${today}T08:30`, page);
    try {
      const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
      const entry = await createCareItem(baseURL, testUser.accessToken, pet.id, {
        name: 'Viewable Care',
        careFamily: 'grooming',
        frequency: 'once',
        dueDate: today,
      });
      await loginAs(page, testUser, { experience: 'guardian' });
      const dashboard = new GuardianDashboardPage(page);
      await dashboard.open();
      const agenda = new CareAgendaPage(page);
      await agenda.openRow(entry.id, entry.name);
      await expect(
        page.getByRole('heading', { name: 'Viewable Care', level: 2 }).first(),
      ).toBeVisible({ timeout: 30_000 });
      const aboutOccurrence = page.locator('[flt-semantics-identifier="occurrence_about_item"]');
      if (await aboutOccurrence.isVisible({ timeout: 3_000 }).catch(() => false)) {
        await aboutOccurrence.click();
      }
      await expect(
        page
          .getByRole('heading', { name: /About this care item/i })
          .or(page.locator('[flt-semantics-identifier="care_item_needs_attention_section"]')),
      ).toBeVisible({ timeout: 30_000 });
    } finally {
      await withCareClock(null, page);
    }
  });

  test('weight check occurrence requires weight before Done', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const today = '2026-06-12';
    await withCareClock(`${today}T09:00`, page);
    try {
      const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
      const entry = await createCareItem(baseURL, testUser.accessToken, pet.id, {
        name: 'Monthly weigh-in',
        careFamily: 'weight_monitoring',
        frequency: 'monthly',
        dueDate: today,
      });
      await loginAs(page, testUser, { experience: 'guardian' });
      const dashboard = new GuardianDashboardPage(page);
      await dashboard.open();
      const agenda = new CareAgendaPage(page);
      await agenda.openRow(entry.id, 'Monthly weigh-in');
      const occurrence = new OccurrencePage(page);
      await occurrence.expectLoaded();
      await occurrence.expectWeightRequiredBeforeDone();
      await occurrence.fillWeight('12.4');
      await occurrence.expectDoneEnabled();
    } finally {
      await withCareClock(null, page);
    }
  });

  test('stack mark done opens care item needs attention', async ({ page, testUser }) => {
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
      await agenda.markDone(entry.id);
      const careItem = new CareItemPage(page);
      await careItem.expectNeedsAttentionVisible();
    } finally {
      await withCareClock(null, page);
    }
  });

  test('upcoming care done early shows confirmation', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const today = '2026-06-01';
    const due = '2026-06-08';
    await withCareClock(`${today}T10:00`, page);
    try {
      const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
      const entry = await createCareItem(baseURL, testUser.accessToken, pet.id, {
        name: 'Future Groom',
        careFamily: 'grooming',
        frequency: 'weekly',
        dueDate: due,
      });
      await loginAs(page, testUser, { experience: 'guardian' });
      const dashboard = new GuardianDashboardPage(page);
      await dashboard.open();
      await dashboard.openEvents();
      const agenda = new CareAgendaPage(page);
      await agenda.showUpcomingCare();
      await agenda.expectRowVisible('Future Groom');
      await agenda.markDone(entry.id);
      await expect(
        page.getByText(/Planned for .+\. Mark it as done today\?|Prévu pour .+\. Le marquer comme fait aujourd'hui \?/i),
      ).toBeVisible({ timeout: 15_000 });
    } finally {
      await withCareClock(null, page);
    }
  });
});
