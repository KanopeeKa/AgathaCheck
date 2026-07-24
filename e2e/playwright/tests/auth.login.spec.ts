/**
 * @bdd authentication.feature
 * Scenario: Logging in with valid credentials
 * Scenario: Logging in with incorrect password
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { checkA11y } from '../support/axe';
import { expectHomeShellHidden } from '../support/flutter';

test.describe('Authentication', () => {
  test('@smoke-a11y @smoke-uat landing path cards pass axe accessibility scan', async ({
    page,
    landingPage,
  }) => {
    await landingPage.goto();
    await checkA11y(page, 'landing path cards');
  });

  test('@smoke-ci @smoke-uat user can log in with valid credentials and reach the pet list', async ({
    page,
    testUser,
  }) => {
    await loginAs(page, testUser);
  });

  test('@smoke-a11y @smoke-uat post-login pet list passes axe accessibility scan', async ({
    page,
    testUser,
  }) => {
    await loginAs(page, testUser);
    await checkA11y(page, 'post-login pet list');
  });

  test('login fails with incorrect password', async ({ page, testUser, landingPage }) => {
    await landingPage.goto();
    await landingPage.login(testUser.email, 'WrongPassword99');
    await page.waitForTimeout(1500);
    await expect(page.getByRole('button', { name: 'Sign In', exact: true })).toBeVisible();
    await expectHomeShellHidden(page);
  });
});
