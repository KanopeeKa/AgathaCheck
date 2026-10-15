/**
 * @bdd care_date_screen.feature
 * Scenario: CD-1 Care date shows four-block layout
 * Scenario: CD-2 Care name link opens Care details
 * Scenario: CD-3 After-it's-done overdue completes inline on the leaf without a date sheet
 * Scenario: CD-4 Neighbour chevron opens the adjacent occurrence on the same route
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { CareItemPage } from '../pages/care-item.page';
import { OccurrencePage } from '../pages/occurrence.page';
import {
  createCareItem,
  getCareItem,
  listHealthEntryOccurrences,
  withCareClock,
} from '../support/care-api';
import { createPet, type TestUser } from '../support/api';
import { createTestUser } from '../support/ui-auth';

test.describe('Care date screen v4', () => {
  test.describe.configure({ mode: 'serial' });

  let sharedUser: TestUser;
  test.beforeAll(async ({ browser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const context = await browser.newContext();
    const page = await context.newPage();
    sharedUser = await createTestUser(page, baseURL);
    await context.close();
  });

  test('CD-1 Care date shows four-block layout', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const today = '2026-06-10';
    await withCareClock(`${today}T09:00`, page);
    try {
      const pet = await createPet(baseURL, sharedUser.accessToken, 'Bella');
      const entry = await createCareItem(baseURL, sharedUser.accessToken, pet.id, {
        name: 'Spa day',
        careFamily: 'grooming',
        frequency: 'once',
        dueDate: today,
      });
      const occurrenceId = entry.open_occurrences[0]?.id;
      expect(occurrenceId).toBeTruthy();

      await loginAs(page, sharedUser, { experience: 'guardian' });
      const occurrence = new OccurrencePage(page);
      await occurrence.open(pet.id, entry.id, occurrenceId!);
      await occurrence.expectV4FourBlockLayout();
    } finally {
      await withCareClock(null, page);
    }
  });

  test('CD-2 Care name link opens Care details', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const today = '2026-06-11';
    await withCareClock(`${today}T09:00`, page);
    try {
      const pet = await createPet(baseURL, sharedUser.accessToken, 'Bella');
      const entry = await createCareItem(baseURL, sharedUser.accessToken, pet.id, {
        name: 'Spa day',
        careFamily: 'grooming',
        frequency: 'once',
        dueDate: today,
      });
      const occurrenceId = entry.open_occurrences[0]?.id;
      expect(occurrenceId).toBeTruthy();

      await loginAs(page, sharedUser, { experience: 'guardian' });
      const occurrence = new OccurrencePage(page);
      await occurrence.open(pet.id, entry.id, occurrenceId!);
      await occurrence.tapCareNameLink();
      const careItem = new CareItemPage(page);
      await careItem.expectCareDetailsScreenTitle();
      await careItem.expectContextStripCareName('Spa day');
    } finally {
      await withCareClock(null, page);
    }
  });

  test('CD-3 After-it\'s-done overdue completes inline on the leaf without a date sheet', async ({
    page,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const today = '2026-06-20';
    const due = '2026-06-10';
    await withCareClock(`${today}T10:00`, page);
    try {
      const pet = await createPet(baseURL, sharedUser.accessToken, 'Bella');
      const entry = await createCareItem(baseURL, sharedUser.accessToken, pet.id, {
        name: 'Flea treat',
        careFamily: 'parasite_prevention',
        frequency: 'monthly',
        dueDate: due,
        scheduleType: 'from_completion',
      });
      const occurrenceId = entry.open_occurrences[0]?.id;
      expect(occurrenceId).toBeTruthy();

      await loginAs(page, sharedUser, { experience: 'guardian' });
      const occurrence = new OccurrencePage(page);
      await occurrence.open(pet.id, entry.id, occurrenceId!);
      await occurrence.expectInlineCompletionDateVisible();
      await occurrence.markDone();
      await occurrence.expectCompletionDateSheetHidden();
    } finally {
      await withCareClock(null, page);
    }
  });

  test('CD-4 Neighbour chevron opens the adjacent occurrence on the same route', async ({
    page,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await withCareClock('2026-06-15T09:00', page);
    try {
      const pet = await createPet(baseURL, sharedUser.accessToken, 'Bella');
      const entry = await createCareItem(baseURL, sharedUser.accessToken, pet.id, {
        name: 'Course',
        careFamily: 'vaccination',
        frequency: 'yearly',
        dueDate: '2026-06-01',
        plannedDates: ['2026-06-15', '2026-07-01'],
      });
      const rows = await listHealthEntryOccurrences(baseURL, sharedUser.accessToken, entry.id);
      const middle = rows.find((r) => r.scheduled_date === '2026-06-15');
      const next = rows.find((r) => r.scheduled_date === '2026-07-01');
      expect(middle?.id).toBeTruthy();
      expect(next?.id).toBeTruthy();

      await loginAs(page, sharedUser, { experience: 'guardian' });
      const occurrence = new OccurrencePage(page);
      await occurrence.open(pet.id, entry.id, middle!.id);
      await occurrence.expectNeighborNextEnabled();
      await occurrence.tapNeighborNext();
      await occurrence.expectRouteOccurrenceId(next!.id);

      const item = await getCareItem(baseURL, sharedUser.accessToken, entry.id);
      const nextOpen = item.open_occurrences.find((o) => o.id === next!.id);
      expect(nextOpen?.scheduled_date).toBe('2026-07-01');
    } finally {
      await withCareClock(null, page);
    }
  });
});
