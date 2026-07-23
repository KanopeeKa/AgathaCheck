import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  flutterGotoUrl,
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
    // Events moved to drawer only — see docs/design/navigation-v2.md
    await expect(
      this.page.getByRole('button', { name: 'Events' }),
    ).not.toBeVisible();
  }

  async expectOrgShell(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await refreshFlutterAccessibility(this.page);
    await expect(this.page.getByRole('button', { name: 'Home' })).toBeVisible();
    // Org shell hides Events from top nav (drawer only) — see experience_shell_scaffold.dart
    await expect(
      this.page.getByRole('button', { name: 'Events' }),
    ).not.toBeVisible();
  }

  async openDrawerOrgView(): Promise<void> {
    await openExperienceDrawer(this.page);
    await this.page.getByText('Organisation view').click();
    await waitForFlutterRoutePattern(this.page, /\/organizations/, 30_000);
  }

  async gotoChooser(): Promise<void> {
    await this.page.goto(flutterGotoUrl('/app/choose'));
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
    await this.page.getByText('Settings', { exact: true }).click();
    await this.expectDefaultExperienceSectionVisible();
  }

  async expectDefaultExperienceSectionVisible(): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const marker = this.page
        .getByRole('radio', { name: 'Individual Pet Guardian' })
        .or(this.page.getByRole('radio', { name: 'Shelter / Organisation' }))
        .or(this.page.getByText('Default experience', { exact: true }))
        .first();
      await expect(marker).toBeVisible();
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
