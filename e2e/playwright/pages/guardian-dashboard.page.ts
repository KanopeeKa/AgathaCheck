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
  waitForFlutterRoutePattern,
} from '../support/flutter';

/**
 * Focused vocabulary for the Guardian operations desk.
 * The page object deliberately uses accessible names and public routes only.
 */
export class GuardianDashboardPage {
  constructor(private readonly page: Page) {}

  private section(name: RegExp): Locator {
    return dashboardSectionGroup(this.page, name);
  }

  async open(): Promise<void> {
    await this.page.goto(flutterGotoUrl('/g/home'));
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/g\/home(?:\?|$)/, 60_000);
    await this.section(/My Pets|Mes animaux/i).waitFor({ state: 'visible', timeout: 60_000 });
  }

  async expectTodayCareRegions(): Promise<void> {
    await expect(this.section(/My Pets|Mes animaux/i)).toBeVisible();
    await expect(this.section(/CARE|SOINS/i)).toBeVisible();
    await expect(this.section(/Care team|CARE TEAM|Équipe de soins|ÉQUIPE DE SOINS/i)).toBeVisible();
    await expect(this.section(/Fostering Sessions|Sessions d'accueil/i)).toBeVisible();
  }

  careRegion(): Locator {
    return this.section(/CARE|SOINS/i);
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
    // All Pets is a section footer link (sibling of the My Pets group), not inside the group.
    await expect(
      this.page
        .getByRole('button', { name: /^All Pets$|^Tous les animaux$/i })
        .or(this.page.getByText(/^All Pets$|^Tous les animaux$/i))
        .first(),
    ).toBeVisible();
  }

  async openAllPets(): Promise<void> {
    await this.page
      .getByRole('button', { name: /^All Pets$|^Tous les animaux$/i })
      .or(this.page.getByText(/^All Pets$|^Tous les animaux$/i))
      .first()
      .click();
    await waitForFlutterRoutePattern(this.page, /\/g\/pets(?:\?|$)/, 30_000);
  }

  async openEvents(): Promise<void> {
    const careBottomNav = this.page
      .getByRole('button', {
        name: /^Care(?:\s+Tab\s+\d+\s+of\s+\d+)?$|^Soins(?:\s+Tab\s+\d+\s+of\s+\d+)?$/i,
      })
      .or(this.page.getByRole('tab', { name: /^Care$|^Soins$/i }))
      .first();
    if (await careBottomNav.isVisible().catch(() => false)) {
      await careBottomNav.click();
    } else {
      await this.careRegion()
        .getByRole('button', { name: /Events|View all|Voir tout|See all/i })
        .or(this.careRegion().getByText(/Events|View all|Voir tout|See all/i))
        .first()
        .click();
    }
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/g\/events(?:\?|$)/, 30_000);
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
    await waitForFlutterRoutePattern(this.page, /\/g\/vets\/[^/]+$/, 30_000);
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
    await waitForFlutterRoutePattern(this.page, /\/g\/home(?:\?|$)/, 30_000);
  }

  async openNotifications(): Promise<void> {
    await this.page.getByRole('button', { name: /open notifications/i }).click();
    await refreshFlutterAccessibility(this.page);
  }

  /** Compact Guardian bottom bar tab (Today, Pets, Care, Fostering, Account). */
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
    return label === 'Care'
      ? /^Care$|^Soins$/i
      : label === 'Pets'
        ? /^Pets$|^Animaux$/i
        : label === 'Today'
          ? /^Today$|^Aujourd'hui$/i
          : label === 'Fostering'
            ? /^Fostering$|^Accueil$/i
            : label === 'Account'
              ? /^Account$|^Compte$/i
              : new RegExp(`^${escapeRegExp(label)}$`, 'i');
  }

  private bottomNavTabPattern(label: string): RegExp {
    return new RegExp(
      `^${escapeRegExp(label)}(?:\\s+Tab\\s+\\d+\\s+of\\s+\\d+)?$`,
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
      case 'Today':
        return 'guardian_nav_today';
      case 'Pets':
        return 'guardian_nav_pets';
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
      '[flt-semantics-identifier="guardian_navigation_sidebar"]',
    );
    const rail = this.page.locator('[flt-semantics-identifier="guardian_navigation_rail"]');
    const bottomNav = this.page.locator(
      '[flt-semantics-identifier="guardian_bottom_navigation"]',
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
    return this.page.locator('[flt-semantics-identifier="guardian_navigation_rail"]');
  }

  leadingNavSidebar(): Locator {
    return this.page.locator('[flt-semantics-identifier="guardian_navigation_sidebar"]');
  }

  async expectLeadingNavRailVisible(): Promise<void> {
    await expect(this.leadingNavRail()).toBeVisible();
  }

  async expectLeadingNavSidebarVisible(): Promise<void> {
    await expect(this.leadingNavSidebar()).toBeVisible();
  }

  async openFosteringViaBottomNav(): Promise<void> {
    await this.openBottomNavTab('Fostering');
    await waitForFlutterRoutePattern(this.page, /\/g\/fostering(?:\?|$)/, 30_000);
    await expect(
      this.page.getByText(/Fostering Sessions|Sessions d'accueil/i).first(),
    ).toBeVisible();
  }

  workspaceToggle(): Locator {
    return this.page
      .getByRole('button', {
        name: /Choose your workspace|Choisir votre espace de travail/i,
      })
      .or(this.page.getByRole('button', { name: /^My Pets$|^Mes animaux$/i }))
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
}