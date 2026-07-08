/**
 * @bdd authentication.feature
 * Scenario: Logging out from the app
 * Scenario: Viewing user details / My Details screen
 * Scenario: Updating user profile
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { MyDetailsPage } from '../pages/my-details.page';
import { LandingPage } from '../pages/landing.page';

test.describe('Authentication – profile and session', () => {
  test('user can log out and is returned to the landing page', async ({ page, testUser }) => {
    await loginAs(page, testUser);

    // Open the user menu (avatar / popup)
    await page.getByRole('button', { name: /user.menu/i }).click();
    await page.waitForTimeout(500);

    // Click "Log Out"
    await page.getByRole('menuitem', { name: /log.out/i })
      .or(page.getByText('Log Out', { exact: true }))
      .first()
      .click();
    await page.waitForTimeout(2000);

    // Should be back on the landing / login page
    const landing = new LandingPage(page);
    await landing.goto();
    await expect(page.getByRole('button', { name: 'Sign In', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'To Do' })).not.toBeVisible();
  });

  test('user can view the My Details screen showing their name and email', async ({
    page,
    testUser,
  }) => {
    await loginAs(page, testUser);

    // Open the user menu
    await page.getByRole('button', { name: /user.menu/i }).click();
    await page.waitForTimeout(500);

    // Click "My Details"
    await page.getByRole('menuitem', { name: /my.details/i })
      .or(page.getByText('My Details', { exact: true }))
      .first()
      .click();

    const myDetails = new MyDetailsPage(page);
    await myDetails.expectLoaded();
    await myDetails.expectEmail(testUser.email);
  });

  test('user can update their first name from My Details', async ({ page, testUser }) => {
    await loginAs(page, testUser);

    // Navigate to My Details via the user menu
    await page.getByRole('button', { name: /user.menu/i }).click();
    await page.waitForTimeout(500);
    await page.getByRole('menuitem', { name: /my.details/i })
      .or(page.getByText('My Details', { exact: true }))
      .first()
      .click();

    const myDetails = new MyDetailsPage(page);
    await myDetails.expectLoaded();

    // Open the editor sheet and update first name
    await myDetails.openEditSheet();
    const updatedName = `Updated${Date.now()}`;
    await myDetails.fillFirstName(updatedName);
    await myDetails.saveProfileEdits();

    await myDetails.expectProfileUpdated();
    await myDetails.expectDisplayName(updatedName);
  });

  test('user can update their bio from My Details', async ({ page, testUser }) => {
    await loginAs(page, testUser);

    // Navigate to My Details via the user menu
    await page.getByRole('button', { name: /user.menu/i }).click();
    await page.waitForTimeout(500);
    await page.getByRole('menuitem', { name: /my.details/i })
      .or(page.getByText('My Details', { exact: true }))
      .first()
      .click();

    const myDetails = new MyDetailsPage(page);
    await myDetails.expectLoaded();

    // Open the editor sheet and update bio
    await myDetails.openEditSheet();
    const bio = `E2E test bio ${Date.now()}`;
    await myDetails.fillBio(bio);
    await myDetails.saveProfileEdits();

    await myDetails.expectProfileUpdated();
    await myDetails.expectBio(bio);
  });
});
