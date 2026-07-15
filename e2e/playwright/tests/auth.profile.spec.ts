/**
 * @bdd authentication.feature
 * Scenario: Logging out from the app
 * Scenario: Viewing user details
 * Scenario: Updating user profile
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { getCurrentUser } from '../support/api';
import { homeShellLocator, logOutFromApp } from '../support/flutter';
import { MyDetailsPage } from '../pages/my-details.page';
import { LandingPage } from '../pages/landing.page';

test.describe('Authentication – profile and session', () => {
  test('user can log out and is returned to the landing page', async ({ page, testUser }) => {
    await loginAs(page, testUser);

    await logOutFromApp(page);
    await page.waitForTimeout(2000);

    // Should be back on the landing / login page
    const landing = new LandingPage(page);
    await landing.goto();
    await expect(page.getByRole('button', { name: 'Sign In', exact: true })).toBeVisible();
    await expect(homeShellLocator(page)).not.toBeVisible();
  });

  test('user can view the My Details screen showing their name and email', async ({
    page,
    testUser,
  }) => {
    await loginAs(page, testUser);

    const myDetails = new MyDetailsPage(page);
    await myDetails.openFromUserMenu();
    await myDetails.expectEmail(testUser.email);
  });

  test('user can update their first name from My Details', async ({ page, testUser }) => {
    await loginAs(page, testUser);

    const myDetails = new MyDetailsPage(page);
    await myDetails.openFromUserMenu();

    // Open the editor sheet and update first name
    await myDetails.openEditSheet();
    const updatedName = `Updated${Date.now()}`;
    await myDetails.fillFirstName(updatedName);
    await myDetails.saveProfileEdits();

    await myDetails.expectProfileUpdated();
    await myDetails.expectDisplayName(updatedName);
  });

  test('user can update their bio from My Details', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await loginAs(page, testUser);

    const myDetails = new MyDetailsPage(page);
    await myDetails.openFromUserMenu();

    // Open the editor sheet and update bio
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
