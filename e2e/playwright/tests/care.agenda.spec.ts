/**
 * @bdd care_agenda.feature
 * Scenario: A care row opens Care details
 * Scenario: Care that needs a weight opens Care date from Mark as done
 * Scenario: Several dates to sort out open the care item
 * Scenario: Upcoming care can be marked as done early
 * Closed care link and list — see closed care list test below
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { CareAgendaPage } from '../pages/care-agenda.page';
import { CareItemPage } from '../pages/care-item.page';
import { GuardianDashboardPage } from '../pages/guardian-dashboard.page';
import { OccurrencePage } from '../pages/occurrence.page';
import { createCareItem, getCareItem, withCareClock } from '../support/care-api';
import { createPet } from '../support/api';
import {
  enableFlutterAccessibility,
  flutterGotoUrl,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';

test.describe('Care agenda', () => {
  test('A care row opens Care details', async ({ page, testUser }) => {
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
      const careItem = new CareItemPage(page);
      await careItem.expectCareDetailsScreenTitle();
      await careItem.expectContextStripCareName('Viewable Care');
    } finally {
      await withCareClock(null, page);
    }
  });

  test('Care that needs a weight opens Care date from Mark as done', async ({
    page,
    testUser,
  }) => {
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
      await agenda.markDone(entry.id);
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
      await page.goto(flutterGotoUrl('/pc/events'));
      await enableFlutterAccessibility(page);
      await waitForFlutterRoutePattern(page, /\/pc\/events(?:\?|$)/, 60_000);
      const agenda = new CareAgendaPage(page);
      await expect(
        page.locator('[flt-semantics-identifier="care_list_today"]'),
      ).toBeVisible({ timeout: 30_000 });
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

  test('Closed care link lists stopped care without dates', async ({ page, testUser }) => {
    test.setTimeout(180_000);
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await withCareClock('2026-06-01T09:00', page);
    try {
      const pet = await createPet(baseURL, testUser.accessToken, 'Milo');
      const entry = await createCareItem(baseURL, testUser.accessToken, pet.id, {
        name: 'Monthly flea',
        careFamily: 'parasite_prevention',
        frequency: 'monthly',
        dueDate: '2026-06-05',
      });
      await loginAs(page, testUser, { experience: 'guardian' });
      const careItem = new CareItemPage(page);
      await careItem.open(pet.id, entry.id);
      await refreshFlutterAccessibility(page);
      await careItem.openCloseCare();
      await page.getByRole('alertdialog').waitFor({ timeout: 15_000 });
      await page.locator('[flt-semantics-identifier="care_close_confirm_button"]').click();
      await expect(
        page.locator('[flt-semantics-identifier="care_item_close_care_button"]'),
      ).toHaveCount(0, { timeout: 30_000 });
      await refreshFlutterAccessibility(page);

      await expect.poll(
        async () => (await getCareItem(baseURL, testUser.accessToken, entry.id)).status,
        { timeout: 30_000 },
      ).toBe('closed');

      await page.goto(flutterGotoUrl(`/pc/events?pet=${pet.id}`));
      await enableFlutterAccessibility(page);
      await waitForFlutterRoutePattern(page, /^\/pc\/events$/, 60_000);
      await expect(page.url()).toContain(`pet=${pet.id}`);
      const closedSection = page.locator(
        '[flt-semantics-identifier="global_events_closed_care"]',
      );
      await expect
        .poll(async () => closedSection.isVisible(), { timeout: 60_000 })
        .toBe(true);
      await closedSection.click();
      await refreshFlutterAccessibility(page);
      await expect(page.getByText(new RegExp(entry.name, 'i')).first()).toBeVisible({
        timeout: 30_000,
      });
      await expect(page.getByText(/Closed by you|Fermé par vous/i).first()).toBeVisible();
      await expect(page.getByText(new RegExp(entry.name, 'i')).first()).not.toContainText(
        /Jun|juin|2026-06/i,
      );
      // Row tap → detail is covered in widget tests; go_router hash is flaky from the
      // Material Closed care list overlay — open detail the same way as other agenda specs.
      await careItem.open(pet.id, entry.id);
      await expect(page.locator('[flt-semantics-identifier="care_item_close_care_button"]')).toHaveCount(
        0,
      );
    } finally {
      await withCareClock(null, page);
    }
  });
});
