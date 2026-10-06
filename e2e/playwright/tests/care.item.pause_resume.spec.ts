/**
 * @bdd care_pause_resume.feature
 * Scenario: PP-2 pause without end date then resume on the suggested date
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { CareItemPage } from '../pages/care-item.page';
import {
  createCareItem,
  getCareItem,
  withCareClock,
} from '../support/care-api';
import { createPet } from '../support/api';

test.describe('Care item pause and resume (PP-2)', () => {
  test('@smoke-ci @smoke-uat PP-2 pause without end date then resume on the suggested date', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await withCareClock('2026-06-01T09:00', page);
    try {
      const pet = await createPet(baseURL, testUser.accessToken, 'Rex');
      const entry = await createCareItem(baseURL, testUser.accessToken, pet.id, {
        name: 'Flea treatment',
        careFamily: 'parasite_prevention',
        frequency: 'monthly',
        dueDate: '2026-06-05',
        scheduleType: 'from_completion',
      });
      expect(entry.open_occurrences[0]?.scheduled_date).toBe('2026-06-05');

      await loginAs(page, testUser, { experience: 'guardian' });
      const careItem = new CareItemPage(page);
      await careItem.open(pet.id, entry.id);
      await careItem.expectContextStripCareName('Flea treatment');
      await careItem.expectPetContextTile('Rex');
      await careItem.pauseFromItemMenu({ noEndDate: true });
      await careItem.expectContextStripStatusChip(/^Paused$|^En pause$/i);
      await careItem.expectPausedBanner();

      let item = await getCareItem(baseURL, testUser.accessToken, entry.id);
      expect(item.status).toBe('paused');

      await withCareClock('2026-08-01T09:00', page);
      item = await getCareItem(baseURL, testUser.accessToken, entry.id);
      const resumeDate = item.resume_default_date!;
      expect(resumeDate).toBe('2026-08-05');

      await careItem.open(pet.id, entry.id);
      await careItem.resumeFromItemMenu();

      item = await getCareItem(baseURL, testUser.accessToken, entry.id);
      expect(item.status).toBe('active');
      expect(item.open_occurrences[0]?.scheduled_date).toBe(resumeDate);
    } finally {
      await withCareClock(null, page);
    }
  });
});
