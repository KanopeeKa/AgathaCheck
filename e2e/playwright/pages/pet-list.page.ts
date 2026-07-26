import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import { HealthDashboardPage } from './health-dashboard.page';
import { OrganizationListPage } from './organization-list.page';
import {
  dismissConsentBannerIfPresent,
  escapeRegExp,
  expectHomeShellVisible,
  flutterGotoUrl,
  homeShellLocator,
  isExperienceShellVisible,
  refreshFlutterAccessibility,
  semanticsByName,
  skipGuardianOnboardingIfPresent,
  skipOrgOnboardingIfPresent,
  waitForFlutterRoute,
  waitForFlutterRoutePattern,
  flutterRoutePath,
} from '../support/flutter';
import { isLiveHostingTarget } from '../support/hosting';

/**
 * Home / pet list screen (`/`).
 * Maps to: flutter_app/test/bdd/features/pet_profiles.feature
 */
export class PetListPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
    await expectHomeShellVisible(
      this.page,
      isLiveHostingTarget() ? 60_000 : 30_000,
    );
  }

  async openHealthDashboard(
    options: { experience?: 'guardian' | 'organization' } = {},
  ): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    const route = flutterRoutePath(this.page.url());
    const useOrgHome =
      options.experience === 'organization' ||
      (options.experience !== 'guardian' &&
        (route.startsWith('/o/') || route.startsWith('/organizations')));
    // Guardian /g/events is the due-events inbox (D17); full tabbed dashboard is /health.
    const dashboardPath = useOrgHome ? '/o/events' : '/health';
    const dashboardRoutePattern = useOrgHome
      ? /\/o\/events(?:\?|$)/
      : /^\/health(?:\?|$)/;
    if (await isExperienceShellVisible(this.page)) {
      await this.page.goto(flutterGotoUrl(dashboardPath));
      await refreshFlutterAccessibility(this.page);
      await waitForFlutterRoutePattern(this.page, dashboardRoutePattern, 30_000);
    } else {
      if (useOrgHome) {
        const eventsNav = this.page.getByRole('button', { name: /^(Events|Événements|To Do)$/i });
        if (await eventsNav.isVisible({ timeout: 2_000 }).catch(() => false)) {
          await eventsNav.click();
        } else {
          await this.page.getByRole('button', { name: /^(To Do|À faire)$/i }).first().click();
        }
        await waitForFlutterRoutePattern(this.page, dashboardRoutePattern, 30_000);
      } else {
        await this.page.goto(flutterGotoUrl(dashboardPath));
        await refreshFlutterAccessibility(this.page);
        await waitForFlutterRoutePattern(this.page, dashboardRoutePattern, 30_000);
      }
    }
    await new HealthDashboardPage(this.page).expectLoaded();
  }

  /**
   * Force the home screen to remount after API-side mutations.
   * Navigates away to the health dashboard, then hash-navigates back to home.
   */
  async refreshByRemount(
    options: { experience?: 'guardian' | 'organization' } = {},
  ): Promise<void> {
    try {
      await this.openHealthDashboard(options);
    } catch (error) {
      const detail = error instanceof Error ? error.message : String(error);
      throw new Error(`health dashboard did not load during refreshByRemount: ${detail}`);
    }

    const route = flutterRoutePath(this.page.url());
    const useOrgHome =
      options.experience === 'organization' ||
      (options.experience !== 'guardian' &&
        (route.startsWith('/o/') || route.startsWith('/organizations')));
    const homePath = useOrgHome ? '/o/home' : '/g/home';

    try {
      await dismissConsentBannerIfPresent(this.page);
      await this.page.goto(flutterGotoUrl(homePath));
      await refreshFlutterAccessibility(this.page);
      await waitForFlutterRoutePattern(
        this.page,
        new RegExp(`^${escapeRegExp(homePath)}(?:\\?|$)`),
        30_000,
      );
      if (useOrgHome) {
        await skipOrgOnboardingIfPresent(this.page);
      } else {
        await skipGuardianOnboardingIfPresent(this.page);
      }
      await this.expectLoaded();
    } catch (error) {
      const detail = error instanceof Error ? error.message : String(error);
      throw new Error(`pet list did not reload after refreshByRemount: ${detail}`);
    }
  }

  /** Assert a due/overdue entry appears in the home DueEventsSection card. */
  async expectDueEntryOnHome(entryName: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(
      this.page
        .getByRole('group', { name: /Upcoming events|Événements à venir/i })
        .first(),
    ).toBeVisible({ timeout: 20_000 });
    await semanticsByName(
      this.page,
      new RegExp(escapeRegExp(entryName), 'i'),
    ).waitFor({ timeout: 20_000 });
  }

  async expectEmptyState(): Promise<void> {
    await this.page.getByText('No pets yet').waitFor();
    await homeShellLocator(this.page).first().waitFor();
  }

  async openAddPet(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.page.getByRole('button', { name: 'Add Pet' }).click();
    await this.page.getByRole('button', { name: 'Save Pet' }).waitFor({ timeout: 30_000 });
  }

  async expectPetVisible(name: string): Promise<void> {
    await semanticsByName(
      this.page,
      new RegExp(`Pet:\\s*${escapeRegExp(name)}`, 'i'),
    ).waitFor({ timeout: 30_000 });
  }

  async expectPetCount(n: number): Promise<void> {
    await expect(
      this.page
        .getByRole('button', { name: /Pet:/i })
        .or(this.page.getByRole('group', { name: /Pet:/i })),
    ).toHaveCount(n, { timeout: 30_000 });
  }

  async openPet(name: string): Promise<void> {
    await this.expectPetVisible(name);
    await semanticsByName(
      this.page,
      new RegExp(`Pet:\\s*${escapeRegExp(name)}`, 'i'),
    ).click();
    await this.page.waitForTimeout(1000);
  }

  async openOrganizations(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    const route = flutterRoutePath(this.page.url());
    if (route === '/o/orgs' || route === '/organizations') {
      await new OrganizationListPage(this.page).expectLoaded();
      return;
    }

    const orgNav = this.page.getByRole('button', { name: 'Organizations' });
    if (await orgNav.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await orgNav.click();
    } else if (await isExperienceShellVisible(this.page)) {
      await this.page.goto(flutterGotoUrl('/o/orgs'));
      await refreshFlutterAccessibility(this.page);
      await waitForFlutterRoutePattern(this.page, /\/o\/orgs(?:\?|$)/, 30_000);
    } else {
      await waitForFlutterRoute(this.page, '/organizations');
    }
    await new OrganizationListPage(this.page).expectLoaded();
  }

  async openVets(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    const vetsNav = this.page.getByRole('button', { name: 'Veterinarians' });
    if (await vetsNav.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await vetsNav.click();
    } else if (await isExperienceShellVisible(this.page)) {
      await this.page.goto(flutterGotoUrl('/g/vets'));
      await refreshFlutterAccessibility(this.page);
      await waitForFlutterRoutePattern(this.page, /\/g\/vets$/, 30_000);
    } else {
      await waitForFlutterRoute(this.page, '/g/vets');
    }
    await this.page.getByText(/^Veterinarians$/i).first().waitFor({ timeout: 30_000 });
  }

  /**
   * Simulate a left swipe on a shared-pet card to trigger the hide-pet
   * Dismissible action (DismissDirection.endToStart).
   */
  async swipeLeftPetCard(name: string): Promise<void> {
    const card = semanticsByName(
      this.page,
      new RegExp(`Pet:\\s*${escapeRegExp(name)}`, 'i'),
    );
    const box = await card.boundingBox();
    if (!box) throw new Error(`Pet card "${name}" not found`);
    const startX = box.x + box.width * 0.92;
    const endX = box.x + box.width * 0.02;
    const midY = box.y + box.height / 2;
    await this.page.mouse.move(startX, midY);
    await this.page.mouse.down();
    for (let i = 1; i <= 24; i++) {
      await this.page.mouse.move(startX + (endX - startX) * (i / 24), midY);
      await this.page.waitForTimeout(15);
    }
    await this.page.waitForTimeout(300);
    await this.page.mouse.up();
    await this.page.waitForTimeout(500);
    await refreshFlutterAccessibility(this.page);
    await this.page
      .getByText(new RegExp(`Hide\\s+${escapeRegExp(name)}`, 'i'))
      .or(this.page.getByText(/Hide Pet/i))
      .first()
      .waitFor({ timeout: 15_000 });
  }

  async confirmHidePet(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await this.page.getByRole('button', { name: 'Hide', exact: true }).last().click();
    await this.page
      .getByText(/pet hidden|animal masqué|hidden from your list/i)
      .first()
      .waitFor({ timeout: 15_000 })
      .catch(() => undefined);
    await this.page.waitForTimeout(1000);
    await refreshFlutterAccessibility(this.page);
  }

  async expectPetHidden(name: string): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(
        this.page
          .getByRole('button', { name: new RegExp(`Pet:\\s*${escapeRegExp(name)}`, 'i') })
          .or(this.page.getByRole('group', { name: new RegExp(`Pet:\\s*${escapeRegExp(name)}`, 'i') })),
      ).toHaveCount(0);
    }).toPass({ timeout: 20_000 });
  }

  async expectSectionHeader(title: string): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(this.page.getByText(title, { exact: false }).first()).toBeVisible();
    }).toPass({ timeout: 30_000 });
  }

  /** Org pets show aria-label "Pet: Name, OrgName, …" on the home list. */
  async expectPetUnderOrganization(petName: string, orgName: string): Promise<void> {
    await semanticsByName(
      this.page,
      new RegExp(`Pet:\\s*${escapeRegExp(petName)}.*${escapeRegExp(orgName)}`, 'i'),
    ).waitFor({ timeout: 30_000 });
  }

  async goHome(options: { experience?: 'guardian' | 'organization' } = {}): Promise<void> {
    const route = flutterRoutePath(this.page.url());
    const useOrgHome =
      options.experience === 'organization' ||
      (options.experience !== 'guardian' &&
        (route.startsWith('/o/') || route.startsWith('/organizations')));
    const home = useOrgHome ? '/o/home' : '/g/home';
    const onHome =
      route === home ||
      (useOrgHome && route.startsWith('/o/') && !route.includes('/onboarding')) ||
      (!useOrgHome && route.startsWith('/g/') && !route.includes('/onboarding'));

    await dismissConsentBannerIfPresent(this.page);
    if (!onHome) {
      const switchingExperience =
        options.experience === 'organization'
          ? !route.startsWith('/o/')
          : options.experience === 'guardian'
            ? !route.startsWith('/g/')
            : false;
      if (switchingExperience) {
        await this.page.goto(flutterGotoUrl(home));
        await refreshFlutterAccessibility(this.page);
        await waitForFlutterRoutePattern(
          this.page,
          new RegExp(`^${escapeRegExp(home)}(?:\\?|$)`),
          30_000,
        );
      } else {
        const homeNav = this.page.getByRole('button', { name: 'Home' });
        if (await homeNav.isVisible({ timeout: 2_000 }).catch(() => false)) {
          await homeNav.click({ force: true });
          await waitForFlutterRoutePattern(
            this.page,
            new RegExp(`^${escapeRegExp(home)}(?:\\?|$)`),
            30_000,
          );
        } else {
          await waitForFlutterRoute(this.page, home);
        }
      }
    }
    if (useOrgHome) {
      await skipOrgOnboardingIfPresent(this.page);
    } else {
      await skipGuardianOnboardingIfPresent(this.page);
    }
    await this.expectLoaded();
  }
}
