import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  openExperienceDrawer,
  refreshFlutterAccessibility,
  waitForFlutterRoute,
  waitForFlutterRoutePattern,
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
    await waitForFlutterRoutePattern(this.page, /\/g\/home/, 30_000);
  }

  async selectOrganizationCard(): Promise<void> {
    await this.page.getByText('Shelter / Organisation').click();
  }

  async chooseOrganization(remember = false): Promise<void> {
    await this.selectOrganizationCard();
    if (remember) {
      await this.page.getByRole('checkbox').click();
    }
    await this.page.getByRole('button', { name: 'Continue' }).click();
    await waitForFlutterRoutePattern(this.page, /\/o\/home/, 30_000);
  }

  async expectGuardianShell(): Promise<void> {
    await expect(this.page.getByRole('button', { name: 'Home' })).toBeVisible();
    await expect(this.page.getByRole('button', { name: 'Events' })).toBeVisible();
  }

  async expectOrgShell(): Promise<void> {
    await expect(this.page.getByRole('button', { name: 'Home' })).toBeVisible();
    await expect(this.page.getByRole('button', { name: 'Events' })).toBeVisible();
  }

  async openDrawerOrgView(): Promise<void> {
    await this.page.getByRole('button', { name: 'Settings' }).click();
    await this.page.getByText('Organisation view').click();
    await waitForFlutterRoutePattern(this.page, /\/o\/home/, 30_000);
  }

  async gotoChooser(): Promise<void> {
    await this.page.goto('/app/choose');
    await refreshFlutterAccessibility(this.page);
  }

  async gotoGuardianSettings(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await waitForFlutterRoute(this.page, '/g/settings');
    await this.expectDefaultExperienceSectionVisible();
  }

  async openGuardianSettingsFromDrawer(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await openExperienceDrawer(this.page);
    await this.page
      .getByRole('dialog', { name: /navigation menu/i })
      .getByRole('button', { name: 'Settings' })
      .click();
    await refreshFlutterAccessibility(this.page);
    await this.expectDefaultExperienceSectionVisible();
  }

  async expectDefaultExperienceSectionVisible(): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(
        this.page.getByText('Default experience', { exact: true }),
      ).toBeVisible();
    }).toPass({ timeout: 45_000 });
  }

  async setDefaultExperience(choice: 'guardian' | 'organization'): Promise<void> {
    const label =
      choice === 'guardian' ? 'Individual Pet Guardian' : 'Shelter / Organisation';
    const radio = this.page.getByRole('radio', { name: label });
    if (await radio.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await radio.click();
    } else {
      await this.page.getByText(label, { exact: true }).click();
    }
    await refreshFlutterAccessibility(this.page);
    await this.page.waitForTimeout(400);
  }
}
