/**
 * @bdd care_close.feature
 * Scenario: CC-1 owner closes active care from the detail screen
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { CareItemPage } from '../pages/care-item.page';
import {
  createCareItem,
  getCareItem,
  withCareClock,
} from '../support/care-api';
import { createPet } from '../support/api';
import { refreshFlutterAccessibility } from '../support/flutter';

async function confirmCloseCare(page: import('@playwright/test').Page): Promise<void> {
  await refreshFlutterAccessibility(page);
  const closeButton = page
    .locator('[flt-semantics-identifier="care_item_close_care_button"]')
    .or(page.getByRole('button', { name: /^Close care$|^Clore le soin$/i }));
  await expect(closeButton.first()).toBeVisible({ timeout: 30_000 });
  await closeButton.first().click();
  await refreshFlutterAccessibility(page);
  const confirm = page
    .locator('[flt-semantics-identifier="care_close_confirm_button"]')
    .or(page.getByRole('button', { name: /^Close care$|^Clore le soin$/i }).last());
  await expect(confirm).toBeVisible({ timeout: 15_000 });
  await confirm.click();
  await refreshFlutterAccessibility(page);
}

test.describe('Close care (CC-1)', () => {
  test('owner closes care with stopped_by_user', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await withCareClock('2026-06-01T09:00', page);
    try {
      const pet = await createPet(baseURL, testUser.accessToken, 'Rex');
      const entry = await createCareItem(baseURL, testUser.accessToken, pet.id, {
        name: 'Flea',
        careFamily: 'parasite_prevention',
        frequency: 'monthly',
        dueDate: '2026-06-05',
      });

      await loginAs(page, testUser, { experience: 'guardian' });
      const careItem = new CareItemPage(page);
      await careItem.open(pet.id, entry.id);
      await confirmCloseCare(page);

      const item = await getCareItem(baseURL, testUser.accessToken, entry.id);
      expect(item.status).toBe('closed');
      expect(item.care_closed_reason).toBe('stopped_by_user');
      expect(item.open_occurrences).toEqual([]);
    } finally {
      await withCareClock(null, page);
    }
  });
});
