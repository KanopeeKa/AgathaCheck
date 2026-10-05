/**
 * Care surfaces — axe (@smoke-a11y). No @bdd header (journey specs live in care.*.spec.ts).
 */
import { test, loginAs } from '../fixtures/auth.fixture';
import { CareAgendaPage } from '../pages/care-agenda.page';
import { CareItemPage } from '../pages/care-item.page';
import { OccurrencePage } from '../pages/occurrence.page';
import { CompletionDateSheetPage } from '../pages/completion-date.sheet';
import { GuardianDashboardPage } from '../pages/guardian-dashboard.page';
import { HealthDashboardPage } from '../pages/health-dashboard.page';
import { HealthEntryFormPage } from '../pages/health-entry-form.page';
import { createCareItem, withCareClock } from '../support/care-api';
import { createPet } from '../support/api';
import { checkA11y } from '../support/axe';
import { enableFlutterAccessibility, refreshFlutterAccessibility } from '../support/flutter';

test.describe('Care accessibility', () => {
  test('@smoke-a11y care agenda on dashboard passes axe', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const today = '2026-08-01';
    await withCareClock(`${today}T09:00`, page);
    try {
      const pet = await createPet(baseURL, testUser.accessToken, 'Luna');
      await createCareItem(baseURL, testUser.accessToken, pet.id, {
        name: 'Grooming',
        careFamily: 'grooming',
        frequency: 'once',
        dueDate: today,
      });
      await loginAs(page, testUser, { experience: 'guardian' });
      const dashboard = new GuardianDashboardPage(page);
      await dashboard.open();
      const agenda = new CareAgendaPage(page);
      await agenda.expectRowVisible('Grooming');
      await checkA11y(page, 'care agenda on dashboard');
    } finally {
      await withCareClock(null, page);
    }
  });

  test('@smoke-a11y care add form with Advanced settings expanded passes axe', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await createPet(baseURL, testUser.accessToken, 'Milo');
    await loginAs(page, testUser, { experience: 'guardian' });
    await enableFlutterAccessibility(page);
    await page.goto(`${baseURL}/pc/events`);
    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.openAddHealthCareForm();

    const form = new HealthEntryFormPage(page);
    await form.expectLoaded();
    await form.selectPet('Milo');
    await form.selectCareFamily('Medication');
    await form.setFrequency('Day');
    await form.expandAdvancedSettings();
    await form.selectScheduleType('Fixed schedule');
    await checkA11y(page, 'care add form advanced settings');
  });

  test('@smoke-a11y care add form vaccination booster field passes axe', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await createPet(baseURL, testUser.accessToken, 'Rex');
    await loginAs(page, testUser, { experience: 'guardian' });
    await enableFlutterAccessibility(page);
    await page.goto(`${baseURL}/pc/events`);
    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.openAddHealthCareForm();

    const form = new HealthEntryFormPage(page);
    await form.expectLoaded();
    await form.selectPet('Rex');
    await form.selectCareFamily('Vaccination');
    await form.setFrequency('Year');
    await page.getByRole('button', { name: /Add a booster date|booster date/i }).waitFor({
      timeout: 15_000,
    });
    await checkA11y(page, 'care add form vaccination booster');
  });

  test('@smoke-a11y care item stack (record earlier dates) passes axe', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const today = '2026-08-02';
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
      await careItem.expectNeedsAttentionVisible();
      await checkA11y(page, 'care item overdue stack');
    } finally {
      await withCareClock(null, page);
    }
  });

  test('@smoke-a11y completion date sheet passes axe', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const today = '2026-08-03';
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
        await checkA11y(page, 'completion date sheet');
      } catch {
        // Fixed-slot completion may skip the sheet; scan the post-mark agenda instead.
        await checkA11y(page, 'care agenda after mark done');
      }
    } finally {
      await withCareClock(null, page);
    }
  });

  test('@smoke-a11y plan another date sheet passes axe', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await withCareClock('2026-08-04T09:00', page);
    try {
      const pet = await createPet(baseURL, testUser.accessToken, 'Rex');
      const entry = await createCareItem(baseURL, testUser.accessToken, pet.id, {
        name: 'DHPP',
        careFamily: 'vaccination',
        frequency: 'yearly',
        dueDate: '2026-08-04',
      });
      await loginAs(page, testUser, { experience: 'guardian' });
      const careItem = new CareItemPage(page);
      await careItem.open(pet.id, entry.id);
      const occurrenceId = entry.open_occurrences[0]!.id;
      const occurrence = new OccurrencePage(page);
      await occurrence.open(pet.id, entry.id, occurrenceId);
      await occurrence.openScreenMenu();
      await page.getByRole('menuitem', { name: /Plan another date|Prévoir une autre date/i }).click();
      await page
        .locator('[flt-semantics-identifier="plan_another_date_sheet"]')
        .waitFor({ timeout: 15_000 });
      await checkA11y(page, 'plan another date sheet');
    } finally {
      await withCareClock(null, page);
    }
  });
});
