/**
 * @bdd authentication.feature
 * Scenario: Logging out from the app
 * Scenario: Viewing user details
 * Scenario: Updating user profile
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { getCurrentUser } from '../support/api';
import { expectHomeShellHidden, logOutFromApp } from '../support/flutter';
import { MyDetailsPage } from '../pages/my-details.page';
import { LandingPage } from '../pages/landing.page';

test.describe('Authentication – profile and session', () => {
  test('Logging out from the app', async ({ page, testUser }) => {
    await loginAs(page, testUser);

    await logOutFromApp(page);
    await page.waitForTimeout(2000);

    const landing = new LandingPage(page);
    await landing.goto();
    await expect(page.getByRole('button', { name: 'Sign In', exact: true })).toBeVisible();
    await expectHomeShellHidden(page);
  });

  test('Viewing user details', async ({ page, testUser }) => {
    await loginAs(page, testUser);

    const myDetails = new MyDetailsPage(page);
    await myDetails.openFromUserMenu();
    await myDetails.expectDisplayName(`${testUser.firstName} ${testUser.lastName}`);
    await myDetails.expectEmail(testUser.email);
  });

  test('Updating user profile', async ({ page, testUser }) => {
    await loginAs(page, testUser);

    const myDetails = new MyDetailsPage(page);
    await myDetails.openFromUserMenu();
    await myDetails.openEditSheet();
    await myDetails.fillFirstName('Bob');
    await myDetails.fillLastName('Jones');
    await myDetails.saveProfileEdits();

    await myDetails.expectProfileUpdated();
    await myDetails.expectDisplayName('Bob Jones');
  });

  test('user can update their bio from My Details', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await loginAs(page, testUser);

    const myDetails = new MyDetailsPage(page);
    await myDetails.openFromUserMenu();

    await myDetails.openEditSheet();
    const bio = `E2E test bio ${Date.now()}`;
    await myDetails.fillBio(bio);
    await myDetails.saveProfileEdits();

    await myDetails.expectProfileUpdated();
    await myDetails.expectBio(bio);
    await expect(async () => {
      const profile = await getCurrentUser(baseURL, testUser.accessToken);
      expect(profile.bio).toBe(bio);
    }).toPass({ timeout: 15_000 });
  });
});
