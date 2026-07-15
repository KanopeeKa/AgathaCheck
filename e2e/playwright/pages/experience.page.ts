import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  refreshFlutterAccessibility,
} from '../support/flutter';

/**
 * Experience chooser and shell navigation.
 * Maps to: flutter_app/test/bdd/features/experience_navigation.feature
 */
export class ExperiencePage {
  constructor(private readonly page: Page) {}

  async expectChooserVisible(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await refreshFlutterAccessibility(this.page);
    await this.page
      .getByText(/How will you use Agatha Track/i)
      .waitFor({ timeout: 30_000 });
  }

  async selectGuardianCard(): Promise<void> {
    await this.page.getByText('Individual Pet Guardian').click();
  }

  async chooseGuardian(remember = false): Promise<void> {
    await this.selectGuardianCard();
    if (remember) {
      await this.page.getByRole('checkbox').click();
    }
    await this.page.getByRole('button', { name: 'Continue' }).click();
    await this.page.waitForURL(/\/g\/home/, { timeout: 30_000 });
  }

  async expectGuardianShell(): Promise<void> {
    await expect(this.page.getByRole('button', { name: 'Home' })).toBeVisible();
    await expect(this.page.getByRole('button', { name: 'Events' })).toBeVisible();
  }

  async openDrawerOrgView(): Promise<void> {
    await this.page.getByRole('button', { name: 'Settings' }).click();
    await this.page.getByText('Organisation view').click();
    await this.page.waitForURL(/\/o\/home/, { timeout: 30_000 });
  }

  async gotoChooser(): Promise<void> {
    await this.page.goto('/app/choose');
    await refreshFlutterAccessibility(this.page);
  }
}
