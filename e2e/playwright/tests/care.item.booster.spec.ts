/**
 * @bdd care_booster.feature
 * Scenario: PL-1 first dose then booster then yearly recurrence
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { CareItemPage } from '../pages/care-item.page';
import { OccurrencePage } from '../pages/occurrence.page';
import {
  createCareItem,
  getCareItem,
  withCareClock,
} from '../support/care-api';
import { createPet } from '../support/api';

test.describe('Vaccination booster (PL-1)', () => {
  test('first dose, booster, then yearly next date', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await withCareClock('2026-06-01T09:00', page);
    try {
      const pet = await createPet(baseURL, testUser.accessToken, 'Rex');
      const entry = await createCareItem(baseURL, testUser.accessToken, pet.id, {
        name: 'DHPP',
        careFamily: 'vaccination',
        frequency: 'yearly',
        dueDate: '2026-06-01',
        plannedDates: ['2026-07-01'],
      });
      expect(entry.open_occurrences.map((o) => o.scheduled_date)).toEqual(
        expect.arrayContaining(['2026-06-01', '2026-07-01']),
      );

      await loginAs(page, testUser, { experience: 'guardian' });
      const careItem = new CareItemPage(page);
      await careItem.open(pet.id, entry.id);
      await careItem.expectNeedsAttentionVisible();

      const firstId = entry.open_occurrences.find(
        (o) => o.scheduled_date === '2026-06-01',
      )!.id;
      await careItem.markLeadingDone();
      let item = await getCareItem(baseURL, testUser.accessToken, entry.id);
      expect(item.open_occurrences).toHaveLength(1);
      expect(item.open_occurrences[0].scheduled_date).toBe('2026-07-01');

      await withCareClock('2026-07-01T10:00', page);
      item = await getCareItem(baseURL, testUser.accessToken, entry.id);
      const boosterId = item.open_occurrences[0].id;
      const occurrence = new OccurrencePage(page);
      await occurrence.open(pet.id, entry.id, boosterId);
      await occurrence.markDone();

      item = await getCareItem(baseURL, testUser.accessToken, entry.id);
      expect(item.open_occurrences).toHaveLength(1);
      expect(item.open_occurrences[0].scheduled_date).toBe('2027-07-01');
    } finally {
      await withCareClock(null, page);
    }
  });
});
