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
      .getByText(/Welcome to Agatha Track|Bienvenue sur Agatha Track/i)
      .waitFor({ timeout: 30_000 });
  }

  async selectGuardianCard(): Promise<void> {
    await this.page
      .getByRole('button', { name: /Track my pets|Suivre mes animaux/i })
      .or(this.page.locator('[flt-semantics-identifier="ftue_action_track_pets"]'))
      .first()
      .click();
  }

  async chooseGuardian(_remember = false): Promise<void> {
    await this.selectGuardianCard();
    await waitForFlutterRoutePattern(this.page, /\/g\/(home|onboarding)/, 30_000);
  }

  /** @deprecated FTUE actions navigate directly — no pre-selected continue step. */
  async continuePreselectedGuardian(_remember = false): Promise<void> {
    await this.chooseGuardian();
  }

  async selectOrganizationCard(): Promise<void> {
    await this.page
      .getByRole('button', { name: /Run a shelter|Gérer un refuge/i })
      .or(this.page.locator('[flt-semantics-identifier="ftue_action_run_shelter"]'))
      .first()
      .click();
  }

  async chooseOrganization(_remember = false): Promise<void> {
    await this.selectOrganizationCard();
    await waitForFlutterRoutePattern(this.page, /\/o\/(home|onboarding)/, 30_000);
  }

  /** After navigation reversal: no Home button; hamburger on root, bell always present. */
  async expectGuardianShell(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await refreshFlutterAccessibility(this.page);
    // Bell (notifications) is always present; Home button is removed.
    await expect(
      this.page.getByRole('button', { name: /open notifications/i }),
    ).toBeVisible({ timeout: 15_000 });
    await expect(
      this.page.getByRole('button', { name: /^Home$/i }),
    ).not.toBeVisible();
  }

  /** After navigation reversal: org shell has bell + hamburger on /o/orgs, no Home. */
  async expectOrgShell(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await refreshFlutterAccessibility(this.page);
    await expect(
      this.page.getByRole('button', { name: /open notifications/i }),
    ).toBeVisible({ timeout: 15_000 });
    await expect(
      this.page.getByRole('button', { name: /^Home$/i }),
    ).not.toBeVisible();
  }

  /** Open the drawer and navigate to the Organisation section via the unified drawer. */
  async openDrawerOrgView(): Promise<void> {
    await openExperienceDrawer(this.page);
    await this.page
      .getByRole('button', { name: /^Shelters\b/i })
      .or(this.page.locator('[flt-semantics-identifier="drawer_organisation"]'))
      .first()
      .click();
    await waitForFlutterRoutePattern(this.page, /\/(?:o\/orgs|organizations)(?:\?|$)/, 30_000);
  }

  async gotoChooser(): Promise<void> {
    await this.page.goto(flutterGotoUrl('/app/choose'));
    await refreshFlutterAccessibility(this.page);
  }

  /** Navigate to /account via the Account drawer item. */
  async gotoAccountFromDrawer(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await openExperienceDrawer(this.page);
    await this.page
      .getByRole('button', { name: /^Account\b/i })
      .or(this.page.locator('[flt-semantics-identifier="drawer_account"]'))
      .first()
      .click();
    await waitForFlutterRoutePattern(this.page, /\/account(?:\?|$)/, 30_000);
  }

  async gotoGuardianSettings(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await waitForFlutterRoute(this.page, '/account');
    await this.expectShowOrganisationSectionVisible();
  }

  async openGuardianSettingsFromDrawer(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.gotoAccountFromDrawer();
    await this.expectShowOrganisationSectionVisible();
  }

  async expectShowOrganisationSectionVisible(): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const toggle = this.page
        .locator('[flt-semantics-identifier="show_organisation_section_toggle"]')
        .or(this.page.getByText('Show shelters section', { exact: true }));
      await expect(toggle.first()).toBeVisible();
    }).toPass({ timeout: 45_000 });
  }

  async enableShowOrganisationSection(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const toggle = this.page
      .locator('[flt-semantics-identifier="show_organisation_section_toggle"]')
      .or(this.page.getByRole('switch', { name: /Show shelters section/i }));
    await toggle.first().click();
    await refreshFlutterAccessibility(this.page);
    await this.page.waitForTimeout(400);
  }

  async expectShowOrganisationToggleLockedOn(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(
      this.page.getByText(
        'Shelters stays visible because you belong to at least one shelter.',
      ),
    ).toBeVisible({ timeout: 15_000 });
    const toggle = this.page.getByRole('switch', { name: /Show shelters section/i });
    await expect(toggle).toBeVisible();
    await expect(toggle).toBeChecked();
    await expect(toggle).toBeDisabled();
  }

  /** @deprecated Default-experience radios removed — use last-section routing instead. */
  async expectDefaultExperienceSectionVisible(): Promise<void> {
    await this.expectShowOrganisationSectionVisible();
  }

  /** @deprecated Default-experience radios removed — use drawer section switch + relogin. */
  async setDefaultExperience(_choice: 'guardian' | 'organization'): Promise<void> {
    // no-op — retained for legacy spec imports
  }

  async expectDrawerWithoutOrganisation(): Promise<void> {
    await openExperienceDrawer(this.page);
    await refreshFlutterAccessibility(this.page);
    await expect(this.page.getByRole('button', { name: /^My Pets\b/i })).toBeVisible();
    await expect(this.page.getByRole('button', { name: /^Shelters\b/i })).not.toBeVisible();
    await expect(this.page.getByRole('button', { name: /^Account\b/i })).toBeVisible();
  }

  /** Assert the drawer contains exactly the three section-switcher items. */
  async expectUnifiedDrawerItems(): Promise<void> {
    await openExperienceDrawer(this.page);
    await refreshFlutterAccessibility(this.page);
    // Flutter web exposes drawer rows as buttons (label may repeat in accessible name).
    await expect(this.page.getByRole('button', { name: /^My Pets\b/i })).toBeVisible();
    await expect(this.page.getByRole('button', { name: /^Shelters\b/i })).toBeVisible();
    await expect(this.page.getByRole('button', { name: /^Account\b/i })).toBeVisible();
    // Deprecated items must not appear
    await expect(this.page.getByText('Events', { exact: true })).not.toBeVisible();
    await expect(this.page.getByText('My vets', { exact: true })).not.toBeVisible();
    await expect(this.page.getByText('Notifications', { exact: true })).not.toBeVisible();
    await expect(this.page.getByText('Settings', { exact: true })).not.toBeVisible();
  }

  /** Assert bell badge shows the expected count. */
  async expectBellBadge(count: number): Promise<void> {
    const label = count > 99 ? '99+' : String(count);
    const bell = this.page.getByRole('button', { name: /open notifications/i });
    await expect(bell).toBeVisible({ timeout: 10_000 });
    const digitPattern = new RegExp(`^${label.replace('+', '\\+')}$`);
    const badgeDigit = bell
      .getByText(digitPattern)
      .or(bell.locator('xpath=..').getByText(digitPattern));
    if (count > 0) {
      await expect(badgeDigit.first()).toBeVisible({ timeout: 15_000 });
    } else {
      await expect(badgeDigit).toHaveCount(0, { timeout: 15_000 });
    }
  }
}
