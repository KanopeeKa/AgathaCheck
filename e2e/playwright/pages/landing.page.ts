import type { Page } from '@playwright/test';
import { fillLabelledField, refreshFlutterAccessibility, waitForFlutter } from '../support/flutter';

export interface SignupDetails {
  firstName: string;
  lastName: string;
  email: string;
  password: string;
  confirmPassword?: string;
}

/**
 * Landing screen (login + signup tabs).
 * Maps to: flutter_app/test/bdd/features/authentication.feature
 */
export class LandingPage {
  constructor(private readonly page: Page) {}

  async goto(): Promise<void> {
    await waitForFlutter(this.page);
  }

  async openSignupTab(): Promise<void> {
    await this.page.getByRole('tab', { name: 'Create Account' }).click();
    await this.page.getByRole('button', { name: 'Create Account', exact: true }).waitFor();
  }

  async signup(details: SignupDetails): Promise<void> {
    await this.openSignupTab();
    await fillLabelledField(this.page, 'First Name', details.firstName);
    await fillLabelledField(this.page, 'Last Name', details.lastName);

    await fillLabelledField(this.page, 'Email', details.email);
    const emailField = this.page.locator('input[aria-label="Email"]');
    if ((await emailField.inputValue()) !== details.email) {
      await emailField.click();
      await emailField.fill('');
      await emailField.pressSequentially(details.email, { delay: 30 });
    }

    const password = details.password;
    await fillLabelledField(this.page, 'Password', password);
    const passwordField = this.page.locator('input[aria-label="Password"]');
    if ((await passwordField.inputValue()) !== password) {
      await passwordField.click();
      await passwordField.fill('');
      await passwordField.pressSequentially(password, { delay: 30 });
    }

    const confirmPassword = details.confirmPassword ?? password;
    await fillLabelledField(this.page, 'Confirm Password', confirmPassword);
    const confirmField = this.page.locator('input[aria-label="Confirm Password"]');
    if ((await confirmField.inputValue()) !== confirmPassword) {
      await confirmField.click();
      await confirmField.fill('');
      await confirmField.pressSequentially(confirmPassword, { delay: 30 });
    }

    await this.page.getByRole('button', { name: 'Create Account', exact: true }).click();
    await refreshFlutterAccessibility(this.page);
    await this.page
      .getByRole('button', { name: 'To Do' })
      .or(this.page.getByRole('button', { name: 'Add Pet' }))
      .or(this.page.getByText('No pets yet'))
      .first()
      .waitFor({ timeout: 60_000 });
  }

  async submitSignupForm(): Promise<void> {
    await this.page.getByRole('button', { name: 'Create Account', exact: true }).click();
    await this.page.waitForTimeout(500);
  }

  async expectSignupValidation(message: string | RegExp): Promise<void> {
    await this.page.getByText(message).first().waitFor({ timeout: 15_000 });
  }

  async login(email: string, password: string): Promise<void> {
    const emailField = this.page.getByRole('textbox', { name: 'Email' });
    await emailField.waitFor({ state: 'visible', timeout: 30_000 });
    await emailField.click();
    await emailField.fill('');
    await emailField.pressSequentially(email, { delay: 25 });

    const passwordField = this.page.getByRole('textbox', { name: 'Password' });
    await passwordField.waitFor({ state: 'visible', timeout: 30_000 });
    await passwordField.click();
    await passwordField.fill('');
    await passwordField.pressSequentially(password, { delay: 25 });

    try {
      const typed = await passwordField.inputValue({ timeout: 2_000 });
      if (typed !== password) {
        await passwordField.fill('');
        await passwordField.pressSequentially(password, { delay: 40 });
      }
    } catch {
      // Flutter semantics inputs may not expose inputValue; pressSequentially above is enough.
    }

    await this.page.getByRole('button', { name: 'Sign In', exact: true }).click();
    await this.page.waitForTimeout(2000);
  }

  async expectLoginError(): Promise<void> {
    await this.page.getByText(/invalid|required|error/i).first().waitFor();
  }
}
