import type { Locator, Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dashboardSectionGroup,
  escapeRegExp,
  flutterGotoUrl,
  petCardByName,
  petCardHiddenLocator,
  refreshFlutterAccessibility,
  semanticsByName,
  skipOrgOnboardingIfPresent,
  waitForFlutterRoutePattern,
} from '../support/flutter';

/**
 * Focused vocabulary for the Pet Care operations desk.
 * The page object deliberately uses accessible names and public routes only.
 */
export class GuardianDashboardPage {
  constructor(private readonly page: Page) {}

  private section(name: RegExp): Locator {
    return dashboardSectionGroup(this.page, name);
  }

  async open(): Promise<void> {
    await this.page.goto(flutterGotoUrl('/pc/home'));
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/pc\/home(?:\?|$)/, 60_000);
    await this.section(/My Pets|Mes animaux/i).waitFor({ state: 'visible', timeout: 60_000 });
  }

  async expectTodayCareRegions(): Promise<void> {
    await expect(this.section(/My Pets|Mes animaux/i)).toBeVisible();
    await expect(this.section(/CARE ACTIONS|SOINS/i)).toBeVisible();
    await expect(this.section(/Care team|CARE TEAM|Équipe de soins|ÉQUIPE DE SOINS/i)).toBeVisible();
    await expect(this.section(/Fostering Sessions|Sessions d'accueil/i)).toBeVisible();
  }

  careRegion(): Locator {
    return this.section(/CARE ACTIONS|SOINS/i);
  }

  async expectNoPendingDashboardBanner(): Promise<void> {
    await expect(
      this.page.getByText(/pending[- ](?:foster|placement|share)|pending foster placements/i),
    ).not.toBeVisible();
  }

  async expectPetPreview(names: string[], omittedName: string): Promise<void> {
    for (const name of names) {
      await expect(petCardByName(this.page, name)).toBeVisible();
    }
    await expect(petCardHiddenLocator(this.page, omittedName)).toHaveCount(0);
  }

  async expectCarePriorityOrder(names: string[]): Promise<void> {
    const positions = await Promise.all(
      names.map(async (name) => {
        const card = semanticsByName(this.page, new RegExp(name, 'i')).first();
        await expect(card).toBeVisible();
        const box = await card.boundingBox();
        if (box == null) throw new Error(`Care priority "${name}" has no visible bounds`);
        return box.y;
      }),
    );
    expect(positions).toEqual([...positions].sort((a, b) => a - b));
  }

  async expectAllPetsDestination(): Promise<void> {
    // All pets is a section header action, not inside the pet rail.
    await expect(
      this.page
        .getByRole('button', { name: /^All pets$|^Tous les animaux$/i })
        .or(this.page.getByText(/^All pets$|^Tous les animaux$/i))
        .first(),
    ).toBeVisible();
  }

  async openAllPets(): Promise<void> {
    await this.page
      .getByRole('button', { name: /^All pets$|^Tous les animaux$/i })
      .or(this.page.getByText(/^All pets$|^Tous les animaux$/i))
      .first()
      .click();
    await waitForFlutterRoutePattern(this.page, /\/pc\/pets(?:\?|$)/, 30_000);
  }

  async openEvents(): Promise<void> {
    const actionsBottomNav = this.page
      .getByRole('button', {
        name: /^Actions(?:\s+Tab\s+\d+\s+of\s+\d+)?$|^Soins(?:\s+Tab\s+\d+\s+of\s+\d+)?$/i,
      })
      .or(this.page.getByRole('tab', { name: /^Actions$|^Soins$/i }))
      .first();
    if (await actionsBottomNav.isVisible().catch(() => false)) {
      await actionsBottomNav.click();
    } else {
      await this.careRegion()
        .getByRole('button', { name: /All Actions|Tous les soins|View all|Voir tout/i })
        .or(this.careRegion().getByText(/All Actions|Tous les soins|View all|Voir tout/i))
        .first()
        .click();
    }
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/pc\/events(?:\?|$)/, 30_000);
  }

  async expectCareVisible(name: string): Promise<void> {
    await expect(semanticsByName(this.page, new RegExp(name, 'i')).first()).toBeVisible();
  }

  async expectVetVisible(name: string): Promise<void> {
    await expect(
      this.section(/Care team|CARE TEAM|Équipe de soins|ÉQUIPE DE SOINS/i)
        .getByRole('button', { name: new RegExp(name, 'i') })
        .or(semanticsByName(this.page, new RegExp(name, 'i')))
        .first(),
    ).toBeVisible();
  }

  async openVet(name: string): Promise<void> {
    const vet = this.section(/My Vets|Mes vétérinaires/i)
      .getByRole('button', { name: new RegExp(name, 'i') })
      .or(semanticsByName(this.page, new RegExp(name, 'i')))
      .first();
    await vet.click();
    await waitForFlutterRoutePattern(this.page, /\/pc\/vets\/[^/]+$/, 30_000);
  }

  async expectNoHorizontalOverflow(): Promise<void> {
    const overflow = await this.page.evaluate(
      () => document.documentElement.scrollWidth > window.innerWidth,
    );
    expect(overflow).toBe(false);
  }

  async goBackToDashboard(): Promise<void> {
    await this.page.goBack();
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/pc\/home(?:\?|$)/, 30_000);
  }

  async openNotifications(): Promise<void> {
    await this.page.getByRole('button', { name: /open notifications/i }).click();
    await refreshFlutterAccessibility(this.page);
  }

  /** Compact Pet Care bottom bar tab (Dashboard, Pets, Actions, Fostering, Account). */
  async openBottomNavTab(label: string): Promise<void> {
    const pattern = this.bottomNavTabPattern(label);
    const tab = this.page
      .getByRole('button', { name: pattern })
      .or(this.page.getByRole('tab', { name: pattern }))
      .first();
    await tab.click();
    await refreshFlutterAccessibility(this.page);
  }

  private destinationNamePattern(label: string): RegExp {
    return label === 'Actions' || label === 'Care'
      ? /^Actions$|^Soins$/i
      : label === 'Pets'
        ? /^Pets$|^Animaux$/i
        : label === 'Dashboard'
          ? /^Dashboard$|^Tableau de bord$/i
          : label === 'Fostering'
            ? /^Fostering$|^Accueil$/i
            : label === 'Account'
              ? /^Account$|^Compte$/i
              : new RegExp(`^${escapeRegExp(label)}$`, 'i');
  }

  private bottomNavTabPattern(label: string): RegExp {
    const normalized = label === 'Care' ? 'Actions' : label;
    return new RegExp(
      `^${escapeRegExp(normalized)}(?:\\s+Tab\\s+\\d+\\s+of\\s+\\d+)?$`,
      'i',
    );
  }

  /**
   * Flutter 3.44 web may expose rail/sidebar items as button, tab, or group —
   * mirror semanticsByName and bottom-nav tab suffix handling.
   */
  private leadingNavItem(container: Locator, label: string): Locator {
    const namePattern = this.destinationNamePattern(label);
    const withTabSuffix = new RegExp(
      `${namePattern.source.slice(1, -1)}(?:\\s+Tab\\s+\\d+\\s+of\\s+\\d+)?`,
      namePattern.flags,
    );
    return container
      .getByRole('button', { name: withTabSuffix })
      .or(container.getByRole('tab', { name: namePattern }))
      .or(container.getByRole('group', { name: namePattern }))
      .first();
  }

  private destinationSemanticsId(label: string): string {
    switch (label) {
      case 'Dashboard':
        return 'guardian_nav_dashboard';
      case 'Pets':
        return 'guardian_nav_pets';
      case 'Actions':
      case 'Care':
        return 'guardian_nav_care';
      case 'Fostering':
        return 'guardian_nav_fostering';
      case 'Account':
        return 'guardian_nav_account';
      default:
        return `guardian_nav_${label.toLowerCase()}`;
    }
  }

  private async clickLeadingNavItem(container: Locator, label: string): Promise<void> {
    const semanticsId = this.destinationSemanticsId(label);
    const byIdentifier = container.locator(
      `[flt-semantics-identifier="${semanticsId}"]`,
    );
    if ((await byIdentifier.count()) > 0) {
      await byIdentifier.first().click();
      return;
    }
    await this.leadingNavItem(container, label).click();
  }

  /**
   * Leading nav destination — rail (600–839px) or sidebar (≥840px).
   * Falls back to bottom nav on compact widths.
   */
  async openLeadingNavDestination(label: string): Promise<void> {
    const sidebar = this.page.locator(
      '[flt-semantics-identifier="pet_care_navigation_sidebar"]',
    );
    const rail = this.page.locator('[flt-semantics-identifier="pet_care_navigation_rail"]');
    const bottomNav = this.page.locator(
      '[flt-semantics-identifier="pet_care_bottom_navigation"]',
    );

    if (await sidebar.isVisible().catch(() => false)) {
      await this.clickLeadingNavItem(sidebar, label);
    } else if (await rail.isVisible().catch(() => false)) {
      await this.clickLeadingNavItem(rail, label);
    } else if (await bottomNav.isVisible().catch(() => false)) {
      await this.openBottomNavTab(label);
      return;
    } else {
      await this.clickLeadingNavItem(this.page.locator('body'), label);
    }
    await refreshFlutterAccessibility(this.page);
  }

  leadingNavRail(): Locator {
    return this.page.locator('[flt-semantics-identifier="pet_care_navigation_rail"]');
  }

  leadingNavSidebar(): Locator {
    return this.page.locator('[flt-semantics-identifier="pet_care_navigation_sidebar"]');
  }

  async expectLeadingNavRailVisible(): Promise<void> {
    await expect(this.leadingNavRail()).toBeVisible();
  }

  async expectLeadingNavSidebarVisible(): Promise<void> {
    await expect(this.leadingNavSidebar()).toBeVisible();
  }

  bottomNavigation(): Locator {
    return this.page
      .locator('[flt-semantics-identifier="pet_care_bottom_navigation"]')
      .or(this.page.getByRole('button', { name: /Dashboard(?:\s+Tab\s+1\s+of\s+5)?/i }))
      .first();
  }

  railBrand(): Locator {
    return this.page
      .locator('[flt-semantics-identifier="pet_care_navigation_rail_brand"]')
      .or(this.page.getByRole('img', { name: /AgathaTrack logo/i }))
      .first();
  }

  notificationBell(): Locator {
    return this.page
      .locator('[flt-semantics-identifier="experience_notification_bell"]')
      .or(this.page.getByRole('button', { name: /open notifications/i }))
      .first();
  }

  /** Sidebar/rail product identity group (Flutter web exposes brand as group name). */
  brandGroups(): Locator {
    return this.page.getByRole('group', { name: /^AgathaTrack$/ });
  }

  /** Mobile app bar brand banner when leading nav is hidden. */
  mobileAppBarBrand(): Locator {
    return this.page.getByRole('banner', { name: /AgathaTrack/i });
  }

  async expectMobileShellHierarchy(): Promise<void> {
    await expect(this.bottomNavigation()).toBeVisible();
    await expect(this.leadingNavRail()).not.toBeVisible();
    await expect(this.leadingNavSidebar()).not.toBeVisible();
    await expect(this.mobileAppBarBrand()).toBeVisible();
    await expect(this.brandGroups()).toHaveCount(0);
  }

  async expectTabletShellHierarchy(): Promise<void> {
    await this.expectLeadingNavRailVisible();
    await expect(this.leadingNavSidebar()).not.toBeVisible();
    await expect(this.railBrand()).toBeVisible();
    await expect(this.brandGroups()).toHaveCount(1);
    await expect(this.mobileAppBarBrand()).not.toBeVisible();
    await this.expectNotificationBellOutsideLeadingNav();
  }

  async expectDesktopShellHierarchy(): Promise<void> {
    await this.expectLeadingNavSidebarVisible();
    await expect(this.leadingNavRail()).not.toBeVisible();
    await expect(this.brandGroups()).toHaveCount(1);
    await expect(this.mobileAppBarBrand()).not.toBeVisible();
    await this.expectNotificationBellOutsideLeadingNav();
  }

  /** D-shell-1/6: global actions live in content chrome, not leading nav. */
  async expectNotificationBellOutsideLeadingNav(): Promise<void> {
    const bell = this.notificationBell();
    await expect(bell).toBeVisible();
    const leading = (await this.leadingNavSidebar().isVisible().catch(() => false))
      ? this.leadingNavSidebar()
      : this.leadingNavRail();
    await expect(leading).toBeVisible();
    const bellBox = await bell.boundingBox();
    const leadingBox = await leading.boundingBox();
    expect(bellBox).not.toBeNull();
    expect(leadingBox).not.toBeNull();
    if (bellBox != null && leadingBox != null) {
      expect(bellBox.x).toBeGreaterThanOrEqual(leadingBox.x + leadingBox.width - 2);
    }
  }

  async openFosteringViaBottomNav(): Promise<void> {
    await this.openBottomNavTab('Fostering');
    await waitForFlutterRoutePattern(this.page, /\/pc\/fostering(?:\?|$)/, 30_000);
    await expect(
      this.page.getByText(/Fostering Sessions|Sessions d'accueil/i).first(),
    ).toBeVisible();
  }

  workspaceToggle(): Locator {
    return this.page
      .getByRole('button', {
        name: /Choose your workspace|Choisir votre espace de travail/i,
      })
      .or(this.page.getByRole('button', { name: /^Pet Care$|^Suivi$/i }))
      .or(this.page.getByRole('button', { name: /^Shelter$|^Refuge$/i }))
      .first();
  }

  async expectWorkspaceToggleVisible(): Promise<void> {
    await expect(this.workspaceToggle()).toBeVisible();
  }

  async openWorkspaceMenu(): Promise<void> {
    await this.workspaceToggle().click();
    await refreshFlutterAccessibility(this.page);
  }

  async selectWorkspaceMenuItem(label: RegExp): Promise<void> {
    const item = this.page
      .getByRole('menuitem', { name: label })
      .or(this.page.getByRole('button', { name: label }))
      .first();
    await item.click();
    await refreshFlutterAccessibility(this.page);
  }

  async switchToShelterWorkspace(): Promise<void> {
    await this.openWorkspaceMenu();
    await this.selectWorkspaceMenuItem(/^Shelter$|^Refuge$/i);
    await waitForFlutterRoutePattern(
      this.page,
      /\/o\/(?:orgs|onboarding)(?:\?|$)/,
      30_000,
    );
    await skipOrgOnboardingIfPresent(this.page);
    await waitForFlutterRoutePattern(this.page, /\/o\/orgs(?:\?|$)/, 30_000);
  }
}
