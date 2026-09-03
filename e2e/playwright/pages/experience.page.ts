import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  flutterGotoUrl,
  guardianAccountTabLocator,
  isGuardianBottomNavVisible,
  openAccountFromShell,
  openExperienceDrawer,
  refreshFlutterAccessibility,
  welcomeAgathaTrackText,
  waitForFlutterRoute,
  waitForFlutterRoutePattern,
  workspaceToggleLocator,
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
    await this.page.getByText(welcomeAgathaTrackText).waitFor({ timeout: 30_000 });
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
    await waitForFlutterRoutePattern(this.page, /\/pc\/(home|onboarding)/, 30_000);
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
    await waitForFlutterRoutePattern(this.page, /\/o\/(orgs|onboarding)/, 30_000);
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

  /** Open the organisation section via workspace toggle (preferred) or legacy drawer. */
  async openDrawerOrgView(): Promise<void> {
    await this.switchToShelterWorkspace();
    await waitForFlutterRoutePattern(this.page, /\/(?:o\/orgs|organizations)(?:\?|$)/, 30_000);
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(
        this.page
          .getByText(
            /Shelters dashboard|Tableau de bord des refuges|My Organisations|Mes organisations/i,
          )
          .first(),
      ).toBeVisible({ timeout: 3_000 });
    }).toPass({ timeout: 30_000 });
  }

  /** Switch workspace to Shelter without asserting the org list hub loaded. */
  async switchToShelterWorkspace(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await refreshFlutterAccessibility(this.page);

    const toggle = workspaceToggleLocator(this.page);
    if (await toggle.isVisible({ timeout: 3_000 }).catch(() => false)) {
      await toggle.click();
      await refreshFlutterAccessibility(this.page);
      const shelterItem = this.page
        .getByRole('menuitem', { name: /^Shelter$|^Refuge$|^Shelters$/i })
        .or(this.page.getByRole('button', { name: /^Shelter$|^Refuge$|^Shelters$/i }))
        .first();
      await shelterItem.click({ timeout: 10_000 });
      return;
    }

    await openExperienceDrawer(this.page);
    await this.page
      .getByRole('button', { name: /^Shelters\b/i })
      .or(this.page.locator('[flt-semantics-identifier="drawer_organisation"]'))
      .first()
      .click();
  }

  async gotoChooser(): Promise<void> {
    await this.page.goto(flutterGotoUrl('/app/choose'));
    await refreshFlutterAccessibility(this.page);
  }

  /** Navigate to /account via bottom nav (compact) or drawer item (transitional). */
  async gotoAccountFromDrawer(): Promise<void> {
    await openAccountFromShell(this.page);
  }

  async gotoGuardianSettings(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await waitForFlutterRoute(this.page, '/account');
    await this.expectAccountPreferencesVisible();
  }

  async openGuardianSettingsFromDrawer(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.gotoAccountFromDrawer();
    await this.expectAccountPreferencesVisible();
  }

  async expectAccountPreferencesVisible(): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(
        this.page.getByText(/Preferences|Préférences/i).first(),
      ).toBeVisible();
    }).toPass({ timeout: 45_000 });
  }

  /** @deprecated D-v5-WORKSPACE-1 — shelter section is always visible; toggle removed. */
  async expectShowOrganisationSectionVisible(): Promise<void> {
    await this.expectAccountPreferencesVisible();
  }

  /** @deprecated D-v5-WORKSPACE-1 — no Account toggle. */
  async enableShowOrganisationSection(): Promise<void> {
    // no-op: shelter workspace is always available
  }

  /** @deprecated D-v5-WORKSPACE-1 — toggle removed. */
  async expectShowOrganisationToggleLockedOn(): Promise<void> {
    await this.expectAccountPreferencesVisible();
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
    await this.expectUnifiedDrawerItems();
  }

  /** Assert workspace switcher (or legacy drawer) exposes the expected section entries. */
  async expectUnifiedDrawerItems(): Promise<void> {
    const toggle = workspaceToggleLocator(this.page);
    if (await toggle.isVisible({ timeout: 3_000 }).catch(() => false)) {
      await toggle.click();
      await refreshFlutterAccessibility(this.page);
      await expect(
        this.page.getByRole('menuitem', { name: /^Pet Care$|^Suivi$/i }),
      ).toBeVisible();
      await expect(
        this.page.getByRole('menuitem', { name: /^Shelter$|^Refuge$/i }),
      ).toBeVisible();
      await this.page.keyboard.press('Escape');
      if (await isGuardianBottomNavVisible(this.page)) {
        await expect(guardianAccountTabLocator(this.page)).toBeVisible();
      }
      return;
    }

    await openExperienceDrawer(this.page);
    await refreshFlutterAccessibility(this.page);
    // Flutter web exposes drawer rows as buttons (label may repeat in accessible name).
    await expect(this.page.getByRole('button', { name: /^Pet Care\b/i })).toBeVisible();
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
