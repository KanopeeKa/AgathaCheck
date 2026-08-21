import { expect, type Page } from '@playwright/test';
import { fillLabelledField, reachAuthenticatedHome, refreshFlutterAccessibility, waitForFlutter, flutterRoutePath, dismissConsentBannerIfPresent } from '../support/flutter';
import { isLiveHostingTarget } from '../support/hosting';

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

    // Dismiss consent banner before submitting — on live UAT the banner can
    // appear over the button and intercept the click.
    await dismissConsentBannerIfPresent(this.page);
    await this.page.getByRole('button', { name: 'Create Account', exact: true }).click();
    await refreshFlutterAccessibility(this.page);
  }

  /** Fill and submit signup, then wait until the home pet list is shown. */
  async signupAndReachHome(details: SignupDetails): Promise<void> {
    await this.signup(details);
    await reachAuthenticatedHome(this.page);
  }

  async submitSignupForm(): Promise<void> {
    await this.page.getByRole('button', { name: 'Create Account', exact: true }).click();
    await this.page.waitForTimeout(500);
  }

  async expectSignupValidation(message: string | RegExp): Promise<void> {
    await this.page.getByText(message).first().waitFor({ timeout: 15_000 });
  }

  async login(email: string, password: string): Promise<void> {
    const attempts = isLiveHostingTarget() ? 2 : 1;
    for (let attempt = 1; attempt <= attempts; attempt++) {
      await this.fillLoginForm(email, password);
      await this.submitLoginForm();

      if (attempt >= attempts) return;

      const leftLanding = await this.page
        .waitForFunction(
          () => {
            const hash = window.location.hash.replace(/^#/, '') || window.location.pathname;
            return hash !== '/landing' && hash !== '/';
          },
          undefined,
          { timeout: 8_000 },
        )
        .then(() => true)
        .catch(() => false);

      if (leftLanding) return;

      if (flutterRoutePath(this.page.url()) !== '/landing') return;
      await this.page.waitForTimeout(1_500);
    }
  }

  private async fillLoginForm(email: string, password: string): Promise<void> {
    const nativeEmail = this.page.locator('#anl-email');
    const nativeVisible = await nativeEmail
      .waitFor({ state: 'visible', timeout: 5_000 })
      .then(() => true)
      .catch(() => false);
    if (nativeVisible) {
      await nativeEmail.fill(email);
      await this.page.locator('#anl-password').fill(password);
      return;
    }

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
  }

  async expectLoginError(): Promise<void> {
    await this.page.getByText(/invalid|required|error/i).first().waitFor();
  }

  async submitLoginForm(): Promise<void> {
    const nativeSubmit = this.page.locator('#anl-submit');
    if (
      await nativeSubmit
        .waitFor({ state: 'visible', timeout: 2_000 })
        .then(() => true)
        .catch(() => false)
    ) {
      await nativeSubmit.click();
      await this.page.waitForTimeout(300);
      return;
    }
    await this.page.getByRole('button', { name: 'Sign In', exact: true }).click();
    await refreshFlutterAccessibility(this.page);
  }

  async expectLoginValidation(message: string | RegExp): Promise<void> {
    const nativeError = this.page.locator('#anl-error');
    if (
      await nativeError
        .waitFor({ state: 'visible', timeout: 2_000 })
        .then(() => true)
        .catch(() => false)
    ) {
      if (message instanceof RegExp) {
        await expect(nativeError).toHaveText(message);
      } else {
        await expect(nativeError).toHaveText(message);
      }
      return;
    }
    await this.page.getByText(message).first().waitFor({ timeout: 15_000 });
  }

  async openCreateAccountTab(): Promise<void> {
    await this.page.getByRole('tab', { name: 'Create Account' }).click();
    await this.page.getByRole('button', { name: 'Create Account', exact: true }).waitFor();
  }

  async openSignInTab(): Promise<void> {
    await this.page.getByRole('tab', { name: 'Sign In' }).click();
    await this.page.getByRole('button', { name: 'Sign In', exact: true }).waitFor();
  }

  async expectCreateAccountHeading(): Promise<void> {
    await expect(this.page.getByRole('tab', { name: 'Create Account' })).toHaveAttribute(
      'aria-selected',
      'true',
    );
    await this.page.getByRole('button', { name: 'Create Account', exact: true }).waitFor({
      timeout: 15_000,
    });
  }

  async expectSignInHeading(): Promise<void> {
    await expect(this.page.getByRole('tab', { name: 'Sign In' })).toHaveAttribute(
      'aria-selected',
      'true',
    );
    await this.page.getByRole('button', { name: 'Sign In', exact: true }).waitFor({
      timeout: 15_000,
    });
  }

  async toggleLoginPasswordVisibility(): Promise<void> {
    const nativeToggle = this.page.locator('#anl-password-toggle');
    if (
      await nativeToggle
        .waitFor({ state: 'visible', timeout: 2_000 })
        .then(() => true)
        .catch(() => false)
    ) {
      await nativeToggle.click();
      return;
    }
    await this.page.getByRole('button', { name: /Show password|Hide password/i }).click();
  }

  async expectLoginPasswordFieldType(type: 'password' | 'text'): Promise<void> {
    const nativePassword = this.page.locator('#anl-password');
    if (
      await nativePassword
        .waitFor({ state: 'visible', timeout: 2_000 })
        .then(() => true)
        .catch(() => false)
    ) {
      await expect(nativePassword).toHaveAttribute('type', type);
      return;
    }
    const passwordField = this.page.getByRole('textbox', { name: 'Password' });
    if (type === 'text') {
      await expect(passwordField).toHaveValue(/.+/);
    }
  }

  async fillLoginEmail(email: string): Promise<void> {
    const nativeEmail = this.page.locator('#anl-email');
    if (
      await nativeEmail
        .waitFor({ state: 'visible', timeout: 2_000 })
        .then(() => true)
        .catch(() => false)
    ) {
      await nativeEmail.fill(email);
      return;
    }
    await fillLabelledField(this.page, 'Email', email);
  }

  async fillLoginPassword(password: string): Promise<void> {
    const nativePassword = this.page.locator('#anl-password');
    if (
      await nativePassword
        .waitFor({ state: 'visible', timeout: 2_000 })
        .then(() => true)
        .catch(() => false)
    ) {
      await nativePassword.fill(password);
      return;
    }
    await fillLabelledField(this.page, 'Password', password);
  }
}
