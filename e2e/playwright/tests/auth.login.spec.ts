/**
 * @bdd authentication.feature
 * Scenario: Logging in with valid credentials
 * Scenario: Logging in with incorrect password
 * Scenario: Logging in with a non-existent email
 * Scenario: Logging in without an email
 * Scenario: Logging in without a password
 * Scenario: Toggling password visibility on the login screen
 * Scenario: Navigating from login to signup
 * Scenario: Navigating from signup to login
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

  test('login fails with a non-existent email', async ({ page, landingPage }) => {
    await landingPage.goto();
    await landingPage.login('nobody@example.com', 'secret123');
    await landingPage.expectLoginValidation(/Invalid email or password/i);
    await expectHomeShellHidden(page);
  });

  test('login requires an email address', async ({ page, landingPage }) => {
    await landingPage.goto();
    await landingPage.submitLoginForm();
    await landingPage.expectLoginValidation('Email is required');
    await expectHomeShellHidden(page);
  });

  test('login requires a password', async ({ page, landingPage }) => {
    await landingPage.goto();
    await landingPage.fillLoginEmail('alice@example.com');
    await landingPage.submitLoginForm();
    await landingPage.expectLoginValidation('Password is required');
    await expectHomeShellHidden(page);
  });

  test('login password visibility toggle reveals and obscures text', async ({
    page,
    landingPage,
  }) => {
    await landingPage.goto();
    await landingPage.fillLoginPassword('secret123');
    await landingPage.expectLoginPasswordFieldType('password');
    await landingPage.toggleLoginPasswordVisibility();
    await landingPage.expectLoginPasswordFieldType('text');
    await landingPage.toggleLoginPasswordVisibility();
    await landingPage.expectLoginPasswordFieldType('password');
  });

  test('user can navigate from login to signup tab', async ({ page, landingPage }) => {
    await landingPage.goto();
    await landingPage.openCreateAccountTab();
    await landingPage.expectCreateAccountHeading();
  });

  test('user can navigate from signup to login tab', async ({ page, landingPage }) => {
    await landingPage.goto();
    await landingPage.openCreateAccountTab();
    await landingPage.openSignInTab();
    await landingPage.expectSignInHeading();
  });
});
