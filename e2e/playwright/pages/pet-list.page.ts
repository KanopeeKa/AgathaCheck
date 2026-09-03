import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import { HealthDashboardPage } from './health-dashboard.page';
import { OrganizationDetailPage } from './organization-detail.page';
import { OrganizationListPage } from './organization-list.page';
import {
  dashboardSectionGroup,
  dismissConsentBannerIfPresent,
  escapeRegExp,
  expectHomeShellVisible,
  flutterGotoUrl,
  homeShellLocator,
  isExperienceShellVisible,
  petCardByName,
  petCardHiddenLocator,
  petListCardLocator,
  activePetListCardLocator,
  postPetMutationShellLocator,
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
    // Pet Care /pc/events is the due-events inbox (D17).
    const dashboardPath = useOrgHome ? '/o/events' : '/pc/events';
    const dashboardRoutePattern = useOrgHome
      ? /\/o\/events(?:\?|$)/
      : /^\/pc\/events(?:\?|$)/;
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
    const homePath = useOrgHome ? '/o/orgs' : '/pc/home';

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

  /** Pet Care `/pc/home` care section — empty when nothing is due today. */
  async expectNoDueEventsOnHome(): Promise<void> {
    await this.expectLoaded();
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const dueSection = dashboardSectionGroup(this.page, 'dueAndOverdue');
      await expect(dueSection).toBeVisible();
      await expect(
        dueSection
          .getByText(/You're all caught up|Tout est à jour|All caught up/i)
          .or(
            dueSection.getByText(
              /No events are overdue or due today|Aucun événement en retard ou prévu aujourd'hui/i,
            ),
          )
          .or(
            dueSection.getByText(
              /Start their care routine|Commencez leur routine de soins|Nothing needs care today|Aucun soin à faire aujourd'hui/i,
            ),
          )
          .or(dueSection.getByRole('button', { name: /Add an event|Ajouter un événement/i }))
          .first(),
      ).toBeVisible();
    }).toPass({ timeout: 30_000 });
  }

  /** Assert a due/overdue entry appears on guardian home care preview. */
  async expectDueEntryOnHome(entryName: string): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(
        semanticsByName(
          this.page,
          new RegExp(escapeRegExp(entryName), 'i'),
        ).first(),
      ).toBeVisible();
    }).toPass({ timeout: 45_000 });
  }

  async expectEmptyState(): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const myPetsSection = dashboardSectionGroup(this.page, 'myPets');
      await expect(myPetsSection).toBeVisible();
      // Illustrated empty state merges title+body into a semantics group label — not plain text.
      await expect(
        semanticsByName(
          this.page,
          /Who are we caring for\?|No pets yet|De qui prenons-nous soin/i,
        )
          .or(this.page.getByRole('button', { name: /^Add Pet$|^Ajouter un animal$/i }))
          .first(),
      ).toBeVisible();
    }).toPass({ timeout: 30_000 });
    await homeShellLocator(this.page).first().waitFor();
  }

  /** Pet Care dashboard (`/pc/home`) no longer shows Add Pet — FAB lives on `/pc/pets`. */
  /** Pet Care `/pc/pets` shell — route plus sticky Add Pet action (title is not always plain text). */
  async expectManagePetsLoaded(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /^\/pc\/pets(?:\?|$)/, 30_000);
    await expect(
      this.page
        .getByRole('button', { name: /^Add Pet$|^Ajouter un animal$/i })
        .filter({ visible: true })
        .first(),
    ).toBeVisible({ timeout: 30_000 });
  }

  async openManagePets(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    const route = flutterRoutePath(this.page.url());
    if (!route.startsWith('/pc/pets')) {
      await this.page.goto(flutterGotoUrl('/pc/pets'));
      await refreshFlutterAccessibility(this.page);
      try {
        await waitForFlutterRoutePattern(this.page, /^\/pc\/pets(?:\?|$)/, 12_000);
      } catch {
        await this.page.evaluate(() => {
          window.location.hash = '#/pc/pets';
        });
        await waitForFlutterRoutePattern(this.page, /^\/pc\/pets(?:\?|$)/, 20_000);
      }
    }
  }

  async openAddPet(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    const resolveAddButton = () =>
      this.page
        .getByRole('button', { name: 'Add Pet', exact: true })
        .filter({ visible: true })
        .first();
    if (!(await resolveAddButton().isVisible({ timeout: 2_000 }).catch(() => false))) {
      await this.openManagePets();
    }
    const addPetBtn = resolveAddButton();
    await addPetBtn.waitFor({ timeout: 30_000 });
    await addPetBtn.click();
    await this.page.getByRole('button', { name: 'Save Pet' }).waitFor({ timeout: 30_000 });
  }

  async expectPetVisible(name: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await petCardByName(this.page, name).waitFor({ timeout: 30_000 });
  }

  async expectPetCount(n: number): Promise<void> {
    let route = flutterRoutePath(this.page.url());
    if (route === '/pc/home' || route === '/') {
      await this.openManagePets();
      route = flutterRoutePath(this.page.url());
    }
    const cards = route.startsWith('/pc/pets')
        ? activePetListCardLocator(this.page)
        : petListCardLocator(this.page);
    await expect(cards).toHaveCount(n, { timeout: 30_000 });
  }

  async openPet(name: string, petId?: string): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    if (petId) {
      const route = flutterRoutePath(this.page.url());
      const returnTo =
        route && route !== '/' && route !== '/landing'
          ? `?returnTo=${encodeURIComponent(route)}`
          : '';
      await this.page.goto(flutterGotoUrl(`/pet/${petId}${returnTo}`));
      await waitForFlutterRoutePattern(this.page, /\/pet\/[^/?]+/, 30_000);
      await refreshFlutterAccessibility(this.page);
      return;
    }

    await this.expectPetVisible(name);
    let route = flutterRoutePath(this.page.url());
    if (route === '/pc/home' || route === '/g/home' || route === '/') {
      await this.openManagePets();
    }
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const card = petCardByName(this.page, name).first();
      await card.scrollIntoViewIfNeeded();
      await card.click();
      const current = flutterRoutePath(this.page.url());
      if (!/^\/pet\/[^/?]+/.test(current)) {
        throw new Error(`Still on ${current} after opening pet ${name}`);
      }
    }).toPass({ timeout: 45_000 });
    await refreshFlutterAccessibility(this.page);
  }

  async openOrganizations(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    const route = flutterRoutePath(this.page.url());
    if (route === '/o/onboarding') {
      await skipOrgOnboardingIfPresent(this.page);
    }
    if (route === '/o/orgs' || route === '/organizations') {
      await new OrganizationListPage(this.page).expectLoaded();
      return;
    }

    const orgNav = this.page.getByRole('button', { name: /Organisations|Organizations/i });
    if (await orgNav.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await orgNav.click();
    } else if (await isExperienceShellVisible(this.page)) {
      await this.page.goto(flutterGotoUrl('/o/orgs'));
      await refreshFlutterAccessibility(this.page);
    } else {
      await waitForFlutterRoute(this.page, '/organizations');
    }
    // Org onboarding guard may redirect super-admins before the hub loads.
    await waitForFlutterRoutePattern(
      this.page,
      /\/o\/(?:orgs|onboarding)(?:\?|$)|\/organizations/,
      30_000,
    );
    await skipOrgOnboardingIfPresent(this.page);
    await waitForFlutterRoutePattern(
      this.page,
      /\/o\/orgs(?:\?|$)|\/organizations/,
      30_000,
    );
    await new OrganizationListPage(this.page).expectLoaded();
  }

  async openVets(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    const vetsNav = this.page.getByRole('button', { name: 'Veterinarians' });
    if (await vetsNav.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await vetsNav.click();
    } else if (await isExperienceShellVisible(this.page)) {
      await this.page.goto(flutterGotoUrl('/pc/vets'));
      await refreshFlutterAccessibility(this.page);
      await waitForFlutterRoutePattern(this.page, /\/pc\/vets$/, 30_000);
    } else {
      await waitForFlutterRoute(this.page, '/pc/vets');
    }
    await this.page.getByText(/^Veterinarians$/i).first().waitFor({ timeout: 30_000 });
  }

  /**
   * Simulate a left swipe on a shared-pet card to trigger the hide-pet
   * Dismissible action (DismissDirection.endToStart).
   *
   * Shared pets on `/pc/home` use [GuardianShellSharedPetCard] (compact, swipe-friendly).
   * On `/pc/pets`, full-list cards are constrained to tile strips where mouse-swipe is
   * unreliable on Flutter web — prefer swiping on the dashboard when already there.
   */
  async swipeLeftPetCard(name: string): Promise<void> {
    await this.expectPetVisible(name);

    const route = flutterRoutePath(this.page.url());
    if (route !== '/pc/home' && route !== '/') {
      if (!route.startsWith('/pc/pets')) {
        await this.openManagePets();
      }
      await this.expectPetVisible(name);
    }

    const hideAffordance = this.page
      .getByText(new RegExp(`Hide\\s+${escapeRegExp(name)}`, 'i'))
      .or(this.page.getByText(/Hide Pet|Masquer l'animal/i))
      .or(this.page.getByRole('dialog', { name: /Hide Pet|Masquer l'animal/i }))
      .or(
        this.page.getByText(
          new RegExp(`Hide ${escapeRegExp(name)}\\?|Masquer ${escapeRegExp(name)}`, 'i'),
        ),
      );

    const card = petCardByName(this.page, name);
    await card.scrollIntoViewIfNeeded();
    await refreshFlutterAccessibility(this.page);

    await expect(async () => {
      const box = await card.boundingBox();
      if (!box) throw new Error(`Pet card "${name}" not found`);
      const startX = box.x + box.width * 0.92;
      const endX = box.x + box.width * 0.02;
      const midY = box.y + box.height / 2;
      await this.page.mouse.move(startX, midY);
      await this.page.mouse.down();
      for (let i = 1; i <= 32; i++) {
        await this.page.mouse.move(startX + (endX - startX) * (i / 32), midY);
        await this.page.waitForTimeout(12);
      }
      await this.page.waitForTimeout(400);
      await this.page.mouse.up();
      await refreshFlutterAccessibility(this.page);
      await hideAffordance.first().waitFor({ timeout: 2_000 });
    }).toPass({ timeout: 30_000 });
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
      await expect(petCardHiddenLocator(this.page, name)).toHaveCount(0);
    }).toPass({ timeout: 20_000 });
  }

  async expectRainbowBridgeSection(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    // Passed-away section may sit below the fold on `/pc/pets`.
    await this.page.mouse.wheel(0, 800);
    await this.page.waitForTimeout(300);
    await refreshFlutterAccessibility(this.page);
    // Pet Care `/pc/pets` uses PetListSectionHeader "Passed away"; legacy list uses collapsible "Rainbow Bridge".
    const sectionLabel = this.page
      .getByText(/^(?:Passed away|Rainbow Bridge|Décédé\(e\))/i)
      .or(this.page.getByText(/(?:Passed away|Rainbow Bridge|Décédé\(e\))\s+\d+/i));
    await sectionLabel.first().waitFor({ timeout: 15_000 });
  }

  async expandRainbowBridgeSection(): Promise<void> {
    await this.expectRainbowBridgeSection();
    const legacyTile = this.page.getByText('Rainbow Bridge').first();
    if (await legacyTile.isVisible({ timeout: 1_000 }).catch(() => false)) {
      await legacyTile.click();
      await this.page.waitForTimeout(500);
      await refreshFlutterAccessibility(this.page);
    }
    // Guardian shell: GuardianPassedAwaySection is always expanded — no-op.
  }

  async expectPassedAwayPetVisible(name: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const pattern = new RegExp(
      `^${escapeRegExp(name)},\\s*[^,]+,\\s*(?:Passed away|Décédé\\(e\\))$`,
      'i',
    );
    await semanticsByName(this.page, pattern).waitFor({ timeout: 30_000 });
  }

  async expectNoPendingSharesSection(): Promise<void> {
    await expect(this.page.getByText(/^Pending Shares$/i)).toHaveCount(0);
  }

  async expectSectionHeader(title: string): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const route = flutterRoutePath(this.page.url());
      if (route === '/o/home' || route === '/o/orgs') {
        // Org shell home is a workspace switcher — membership cards, not pet sections.
        await new OrganizationListPage(this.page).expectOrgVisible(title);
        return;
      }
      // Group role only on guardian desk — getByText fallback matches pet cards whose aria-label
      // includes the org name (e.g. "Pet: Bella, Happy Paws Clinic, dog").
      await expect(dashboardSectionGroup(this.page, title)).toBeVisible();
    }).toPass({ timeout: 30_000 });
  }

  /**
   * Org inventory lives on `/o/orgs/:id/pets` — the `/o/home` hub is a workspace switcher.
   */
  async expectPetUnderOrganization(
    petName: string,
    orgName: string,
    orgId?: string,
  ): Promise<void> {
    const detail = new OrganizationDetailPage(this.page);
    if (orgId) {
      const petsPath = `/o/orgs/${orgId}/pets`;
      const petsRoute = new RegExp(`^${escapeRegExp(petsPath)}(?:\\?|$)`);
      if (!petsRoute.test(flutterRoutePath(this.page.url()))) {
        await dismissConsentBannerIfPresent(this.page);
        await this.page.goto(flutterGotoUrl(petsPath));
        await refreshFlutterAccessibility(this.page);
        await waitForFlutterRoutePattern(this.page, petsRoute, 30_000);
      }
      await detail.expectPetVisibleOnPetsScreen(petName);
      return;
    }

    await this.openOrganizations();
    const orgList = new OrganizationListPage(this.page);
    await orgList.openOrg(orgName);
    await detail.expectLoaded(orgName);
    await detail.expectPetVisible(petName);
  }

  async goHome(options: { experience?: 'guardian' | 'organization' } = {}): Promise<void> {
    const route = flutterRoutePath(this.page.url());
    const useOrgHome =
      options.experience === 'organization' ||
      (options.experience !== 'guardian' &&
        (route.startsWith('/o/') || route.startsWith('/organizations')));
    const home = useOrgHome ? '/o/orgs' : '/pc/home';
    // Match only the home route — not other /o/* or /pc/* shells (e.g. /o/orgs/:id/pets).
    const onHome = route === home;

    await dismissConsentBannerIfPresent(this.page);
    if (!onHome) {
      const switchingExperience =
        options.experience === 'organization'
          ? !route.startsWith('/o/')
          : options.experience === 'guardian'
            ? !route.startsWith('/pc/')
            : false;
      if (switchingExperience) {
        await this.page.goto(flutterGotoUrl(home));
        await refreshFlutterAccessibility(this.page);
        if (useOrgHome) {
          await waitForFlutterRoutePattern(
            this.page,
            /\/o\/(?:orgs|onboarding)(?:\?|$)/,
            30_000,
          );
        } else {
          await waitForFlutterRoutePattern(
            this.page,
            new RegExp(`^${escapeRegExp(home)}(?:\\?|$)`),
            30_000,
          );
        }
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
