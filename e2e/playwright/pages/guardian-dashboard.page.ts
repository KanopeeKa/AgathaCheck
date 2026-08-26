import type { Locator, Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
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

  private region(name: RegExp): Locator {
    return this.page.getByRole('region', { name }).first();
  }

  async open(): Promise<void> {
    await this.page.goto(flutterGotoUrl('/g/home'));
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/g\/home(?:\?|$)/, 60_000);
    await this.region(/My Pets|Mes animaux/i).waitFor({ state: 'visible', timeout: 60_000 });
  }

  async expectTodayCareRegions(): Promise<void> {
    await expect(this.region(/My Pets|Mes animaux/i)).toBeVisible();
    await expect(this.region(/CARE|SOINS/i)).toBeVisible();
    await expect(this.region(/My Vets|Mes vétérinaires/i)).toBeVisible();
    await expect(this.region(/Fostering Sessions|Sessions d'accueil/i)).toBeVisible();
  }

  careRegion(): Locator {
    return this.region(/CARE|SOINS/i);
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
    const careTab = this.page
      .getByRole('button', { name: /^Care$|^Soins$/i })
      .first();
    if (await careTab.isVisible().catch(() => false)) {
      await careTab.click();
    } else {
      await this.careRegion()
        .getByRole('button', { name: /Events|View all|Voir tout|See all/i })
        .or(this.careRegion().getByText(/Events|View all|Voir tout|See all/i))
        .first()
        .click();
    }
    await waitForFlutterRoutePattern(this.page, /\/g\/events(?:\?|$)/, 30_000);
  }

  async expectCareVisible(name: string): Promise<void> {
    await expect(semanticsByName(this.page, new RegExp(name, 'i')).first()).toBeVisible();
  }

  async expectVetVisible(name: string): Promise<void> {
    await expect(
      this.region(/My Vets|Mes vétérinaires/i)
        .getByRole('button', { name: new RegExp(name, 'i') })
        .or(semanticsByName(this.page, new RegExp(name, 'i')))
        .first(),
    ).toBeVisible();
  }

  async openVet(name: string): Promise<void> {
    const vet = this.region(/My Vets|Mes vétérinaires/i)
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
    const pattern = new RegExp(`^${escapeRegExp(label)}$`, 'i');
    const tab = this.page
      .getByRole('button', { name: pattern })
      .or(this.page.getByRole('tab', { name: pattern }))
      .first();
    await tab.click();
    await refreshFlutterAccessibility(this.page);
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