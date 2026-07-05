import type { Page } from '@playwright/test';
import { fillLabelledField, waitForFlutter } from '../support/flutter';

/**
 * Landing screen (login + signup tabs).
 * Maps to: flutter_app/test/bdd/features/authentication.feature
 */
export class LandingPage {
  constructor(private readonly page: Page) {}

  async goto(): Promise<void> {
    await waitForFlutter(this.page);
  }

  async login(email: string, password: string): Promise<void> {
    await fillLabelledField(this.page, 'Email', email);
    await this.page.waitForTimeout(200);
    await fillLabelledField(this.page, 'Password', password);

    const passwordField = this.page.locator('input[aria-label="Password"]');
    if ((await passwordField.inputValue()) !== password) {
      await passwordField.click();
      await passwordField.fill('');
      await passwordField.pressSequentially(password, { delay: 20 });
    }

    await this.page.getByRole('button', { name: 'Sign In', exact: true }).click();
    await this.page.waitForTimeout(2000);
  }

  async expectLoginError(): Promise<void> {
    await this.page.getByText(/invalid|required|error/i).first().waitFor();
  }
}
