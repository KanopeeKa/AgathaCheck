/**
 * @bdd authentication.feature
 * Scenario: Signing up with valid credentials
 * Scenario: Signing up with mismatched passwords
 * Scenario: Signing up without an email
 * Scenario: Signing up with an invalid email
 * Scenario: Signing up with a password shorter than 6 characters
 * Scenario: Signing up with an already registered email
 */
import { test, expect } from '@playwright/test';
import { LandingPage } from '../pages/landing.page';
import { PetListPage } from '../pages/pet-list.page';
import { signupUser } from '../support/api';

test.describe('Authentication signup', () => {
  test('signup shows error when passwords do not match', async ({ page }) => {
    const landing = new LandingPage(page);

    await landing.goto();
    await landing.openSignupTab();
    await landing.signup({
      firstName: 'Alice',
      lastName: 'Smith',
      email: 'alice@example.com',
      password: 'secret123',
      confirmPassword: 'different456',
    });
    await landing.expectSignupValidation('Passwords do not match');
    await expect(page.getByRole('button', { name: 'To Do' })).not.toBeVisible();
  });

  test('signup requires an email address', async ({ page }) => {
    const landing = new LandingPage(page);

    await landing.goto();
    await landing.openSignupTab();
    await landing.submitSignupForm();
    await landing.expectSignupValidation('Email is required');
  });

  test('signup rejects an invalid email', async ({ page }) => {
    const landing = new LandingPage(page);

    await landing.goto();
    await landing.signup({
      firstName: 'Alice',
      lastName: 'Smith',
      email: 'not-an-email',
      password: 'secret123',
    });
    await landing.expectSignupValidation(/Enter a valid email|Email is required/);
  });

  test('signup rejects a password shorter than 6 characters', async ({ page }) => {
    const landing = new LandingPage(page);

    await landing.goto();
    await landing.openSignupTab();
    await landing.signup({
      firstName: 'Alice',
      lastName: 'Smith',
      email: `short-pw-${Date.now()}@example.com`,
      password: 'abc',
    });
    await landing.expectSignupValidation(/At least 6 characters|Password is required/);
  });

  test('signup rejects an already registered email', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const existing = await signupUser(baseURL, {
      email: `e2e-existing-${Date.now()}@example.com`,
      password: 'E2eTestPass1',
    });

    const landing = new LandingPage(page);
    await landing.goto();
    await landing.signup({
      firstName: 'Bob',
      lastName: 'Jones',
      email: existing.email,
      password: 'AnotherPass1',
      confirmPassword: 'AnotherPass1',
    });
    await landing.expectSignupValidation(/already exists/i);
    await expect(page.getByRole('button', { name: 'To Do' })).not.toBeVisible();
  });

  test('user can sign up with valid credentials and reach the pet list', async ({ page }) => {
    const suffix = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
    const email = `e2e-signup-${suffix}@example.com`;
    const password = 'E2eTestPass1';

    const landing = new LandingPage(page);
    const petList = new PetListPage(page);

    await landing.goto();
    await landing.signup({
      firstName: 'Alice',
      lastName: 'Smith',
      email,
      password,
    });
    await petList.expectLoaded();
    await expect(page.getByRole('button', { name: 'To Do' })).toBeVisible();
  });
});
