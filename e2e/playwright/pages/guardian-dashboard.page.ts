import type { Locator, Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dashboardSectionGroup,
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

  private section(name: 'myPets' | 'dueAndOverdue' | 'myVets'): Locator {
    return dashboardSectionGroup(this.page, name);
  }

  async open(): Promise<void> {
    await this.page.goto(flutterGotoUrl('/g/home'));
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/g\/home(?:\?|$)/, 60_000);
    await this.section('myPets').waitFor({ state: 'visible', timeout: 60_000 });
  }

  async expectExactlyThreeManagementSections(): Promise<void> {
    await expect(this.section('myPets')).toBeVisible();
    await expect(this.section('dueAndOverdue')).toBeVisible();
    await expect(this.section('myVets')).toBeVisible();
    // Today is an orientation layer above the three management domains — not a fourth section.
    await this.expectTodayOrientation();
  }

  today(): Locator {
    return this.page
      .getByRole('region', { name: /Today|Aujourd'hui/i })
      .or(this.page.getByText(/^Today$|^Aujourd'hui$/i))
      .first();
  }

  async expectTodayOrientation(): Promise<void> {
    await expect(
      this.page
        .getByRole('heading', { name: /Today|Aujourd'hui/i })
        .or(this.today())
        .first(),
    ).toBeVisible();
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
    await expect(
      this.section('myPets')
        .getByRole('button', { name: /All Pets|Tous les animaux/i })
        .or(this.section('myPets').getByText(/All Pets|Tous les animaux/i))
        .first(),
    ).toBeVisible();
  }

  async openAllPets(): Promise<void> {
    await this.section('myPets')
      .getByRole('button', { name: /All Pets|Tous les animaux/i })
      .or(this.section('myPets').getByText(/All Pets|Tous les animaux/i))
      .first()
      .click();
    await waitForFlutterRoutePattern(this.page, /\/g\/pets(?:\?|$)/, 30_000);
  }

  async openEvents(): Promise<void> {
    await this.section('dueAndOverdue')
      .getByRole('button', { name: /Events|View all|See all/i })
      .or(this.section('dueAndOverdue').getByText(/Events|View all|See all/i))
      .first()
      .click();
    await waitForFlutterRoutePattern(this.page, /\/g\/events(?:\?|$)/, 30_000);
  }

  async expectCareVisible(name: string): Promise<void> {
    await expect(semanticsByName(this.page, new RegExp(name, 'i')).first()).toBeVisible();
  }

  async expectVetVisible(name: string): Promise<void> {
    await expect(
      this.section('myVets')
        .getByRole('button', { name: new RegExp(name, 'i') })
        .or(semanticsByName(this.page, new RegExp(name, 'i')))
        .first(),
    ).toBeVisible();
  }

  async openVet(name: string): Promise<void> {
    const vet = this.section('myVets')
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
}