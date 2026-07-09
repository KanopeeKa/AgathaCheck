/**
 * @bdd gdpr_data_rights.feature
 * Scenario: Exporting my personal data as JSON
 * Scenario: Deleting my account with password confirmation
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  createPet,
  exportUserData,
  tryLogin,
} from '../support/api';
import { LandingPage } from '../pages/landing.page';
import { MyDetailsPage } from '../pages/my-details.page';

test.describe('GDPR data rights', () => {
  test('exporting my personal data as JSON', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await createPet(baseURL, testUser.accessToken, 'Bella', 'Dog');

    const petList = await loginAs(page, testUser);
    await petList.expectLoaded();

    await page.getByRole('button', { name: /user.menu/i }).click();
    await page.waitForTimeout(500);
    await page
      .getByRole('menuitem', { name: /my.details/i })
      .or(page.getByText('My Details', { exact: true }))
      .first()
      .click();

    const myDetails = new MyDetailsPage(page);
    await myDetails.expectLoaded();
    await myDetails.exportMyData();

    const exportPayload = await exportUserData(baseURL, testUser.accessToken);
    expect(exportPayload.user.id).toBe(testUser.userId);
    expect(exportPayload.user.email).toBe(testUser.email);
    expect(exportPayload.exported_at).toBeTruthy();
    expect(exportPayload.pets.some((p) => p.name === 'Bella')).toBeTruthy();
  });

  test('deleting my account with password confirmation', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const petList = await loginAs(page, testUser);
    await petList.expectLoaded();

    await page.getByRole('button', { name: /user.menu/i }).click();
    await page.waitForTimeout(500);
    await page
      .getByRole('menuitem', { name: /my.details/i })
      .or(page.getByText('My Details', { exact: true }))
      .first()
      .click();

    const myDetails = new MyDetailsPage(page);
    await myDetails.expectLoaded();
    await myDetails.deleteAccount(testUser.password);

    const landing = new LandingPage(page);
    await landing.goto();
    await expect(page.getByRole('button', { name: 'Sign In', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'To Do' })).not.toBeVisible();

    const loginAttempt = await tryLogin(baseURL, testUser.email, testUser.password);
    expect(loginAttempt.ok).toBe(false);
    expect(loginAttempt.status).toBeGreaterThanOrEqual(400);
  });
});
