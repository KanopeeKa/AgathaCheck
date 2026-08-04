import type { Locator, Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  enableFlutterAccessibility,
  escapeRegExp,
  expectAppBarTitle,
  fillTextbox,
  flutterGotoUrl,
  navigateWithShellFallback,
  refreshFlutterAccessibility,
  selectDropdownOption,
  waitForFlutterRoutePattern,
} from '../support/flutter';
import { OrganizationListPage } from './organization-list.page';

/**
 * Organisation profile composer (`/o/orgs/:id`) — v2 hub replacing the legacy dashboard.
 */
export class OrganizationDetailPage {
  constructor(private readonly page: Page) {}

  /** Visible on v2 profile (public blocks and/or gated member nav rows). */
  private static readonly profileLoadedMarker =
    /Contact|Legal information|Admin contacts|Foster parents|Fostering sessions|^Pets$|^Animaux$|Connected organisations|Organisation Administration|Professional|Charity|Professionnel|Association|Organisation presentation|Organisation dashboard|Choose a section/i;

  private orgIdFromUrl(): string | null {
    const match = this.page.url().match(/\/o\/orgs\/([^/?#]+)/);
    return match?.[1] ?? null;
  }

  async expectLoaded(orgName: string): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await waitForFlutterRoutePattern(this.page, /\/o\/orgs\/[^/?#]+/, 30_000);
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expectAppBarTitle(this.page, orgName);
      await expect(
        this.page.getByText(OrganizationDetailPage.profileLoadedMarker).first(),
      ).toBeVisible();
    }).toPass({ timeout: 30_000 });
  }

  async expectProfileNavRow(name: RegExp | string): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await refreshFlutterAccessibility(this.page);
    const pattern = typeof name === 'string' ? new RegExp(escapeRegExp(name), 'i') : name;
    await expect(
      this.page.getByRole('button', { name: pattern }).filter({ visible: true }).first(),
    ).toBeVisible({ timeout: 30_000 });
  }

  async expectProfileNavRowHidden(name: RegExp | string): Promise<void> {
    await enableFlutterAccessibility(this.page);
    const pattern = typeof name === 'string' ? new RegExp(escapeRegExp(name), 'i') : name;
    await expect(this.page.getByRole('button', { name: pattern })).toHaveCount(0);
  }

  /**
   * Members live at `/o/orgs/:id/members` (popup menu only on the dashboard hub).
   * Flutter web often misses PopupMenuItem taps — hash-route fallback mirrors
   * `openPetsSection` (UAT shard 3/11).
   */
  async openMembers(): Promise<void> {
    const orgId = this.orgIdFromUrl();
    const membersRoute = /\/o\/orgs\/[^/]+\/members(?:\/|$|\?)/;

    let navigated = false;
    try {
      await enableFlutterAccessibility(this.page);
      await this.openMenu();
      const menuItem = this.page.getByRole('menuitem', { name: /Members|Membres/i });
      if (await menuItem.isVisible({ timeout: 5_000 }).catch(() => false)) {
        await menuItem.click();
        await refreshFlutterAccessibility(this.page);
        navigated = await waitForFlutterRoutePattern(this.page, membersRoute, 8_000)
          .then(() => true)
          .catch(() => false);
      } else {
        await this.page.keyboard.press('Escape');
      }
    } catch {
      await this.page.keyboard.press('Escape').catch(() => {});
    }

    if (!navigated) {
      if (!orgId) {
        await waitForFlutterRoutePattern(this.page, membersRoute, 60_000);
      } else {
        await navigateWithShellFallback(
          this.page,
          membersRoute,
          `/o/orgs/${orgId}/members`,
          async () => {
            await refreshFlutterAccessibility(this.page);
          },
          { helper: 'OrganizationDetailPage.openMembers', testTitle: null },
        );
      }
    }

    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, membersRoute, 60_000);
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expectAppBarTitle(this.page, /Members|Membres/i);
    }).toPass({ timeout: 30_000 });
  }

  async expectMemberVisible(name: string): Promise<void> {
    await this.openMembers();
    const pattern = new RegExp(escapeRegExp(name), 'i');
    await this.page
      .getByRole('group', { name: pattern })
      .or(this.page.getByText(pattern))
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async expectMemberCount(count: number): Promise<void> {
    await this.openMembers();
    const cards = this.page.locator('flt-semantics').filter({ hasText: /@|member|admin/i });
    await expect(cards).toHaveCount(count, { timeout: 30_000 });
  }

  /** EN presentation section — OrgSectionCard semantics label. */
  private static readonly presentationSectionName =
    /Organisation presentation|Présentation de l'organisation/i;

  async openPresentation(): Promise<void> {
    const orgId = this.orgIdFromUrl();
    const profileRoute = /\/o\/orgs\/[^/?#]+(?:\/|$|\?)/;

    if (!orgId) {
      await waitForFlutterRoutePattern(this.page, profileRoute, 60_000);
    } else {
      await navigateWithShellFallback(
        this.page,
        profileRoute,
        `/o/orgs/${orgId}/presentation`,
        async () => {
          await refreshFlutterAccessibility(this.page);
        },
        { helper: 'OrganizationDetailPage.openPresentation', testTitle: null },
      );
    }

    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, profileRoute, 60_000);
  }

  async expectBio(bio: string): Promise<void> {
    const pattern = new RegExp(escapeRegExp(bio), 'i');
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(
        this.page.locator('flt-semantics').filter({ hasText: pattern }).first(),
      ).toBeVisible();
    }).toPass({ timeout: 30_000 });
  }

  /** EN "All" / FR "Tous" — inclusive org pets tab (default is Need attention). */
  private static readonly allPetsTabName = /^(All|Tous)$/i;

  private async selectOrgPetsTab(name: RegExp): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await refreshFlutterAccessibility(this.page);
    const tab = this.page
      .getByRole('tab', { name })
      .or(this.page.getByRole('button', { name }))
      .or(this.page.getByRole('checkbox', { name }))
      .filter({ visible: true })
      .first();
    await tab.waitFor({ timeout: 15_000 });
    await tab.click();
    await refreshFlutterAccessibility(this.page);
  }

  async expectPetVisible(name: string): Promise<void> {
    await this.openPetsSection();
    // Fostered pets live on In foster / All — not the default Need attention tab.
    await this.selectOrgPetsTab(OrganizationDetailPage.allPetsTabName);
    const pattern = new RegExp(escapeRegExp(name), 'i');
    const pet = this.page
      .getByRole('button', { name: pattern })
      .or(this.page.getByRole('group', { name: pattern }))
      .or(this.page.getByText(name, { exact: true }))
      .first();
    await pet.scrollIntoViewIfNeeded();
    await expect(pet).toBeVisible();
  }

  async openMenu(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await this.page.getByRole('button', { name: 'Show menu' }).click();
    await refreshFlutterAccessibility(this.page);
  }

  async inviteMember(email: string, roleLabel: string): Promise<void> {
    await this.openMenu();
    await this.page.getByRole('menuitem', { name: 'Invite Member' }).click();
    await fillTextbox(this.page, 'Email', email);
    await selectDropdownOption(this.page, 'Select Role', roleLabel);
    await this.page.getByRole('button', { name: 'Send Invite' }).click();
    await this.page.getByText('Invitation sent successfully').first().waitFor({ timeout: 30_000 });
  }

  async expectInviteMenuHidden(): Promise<void> {
    await this.openMenu();
    await expect(this.page.getByRole('menuitem', { name: 'Invite Member' })).toHaveCount(0);
    await this.page.keyboard.press('Escape');
  }

  async leaveOrganization(): Promise<void> {
    await this.openMenu();
    await this.page.getByRole('menuitem', { name: 'Leave Organization' }).click();
    await this.page.getByRole('button', { name: 'Leave Organization' }).last().click();
    // Leave removes membership in-app, but the hash URL Playwright reads often
    // stays on the org profile (same class of drift as acceptInviteForOrg).
    // Prefer shell back when visible; always re-enter My Orgs via goto for asserts.
    await refreshFlutterAccessibility(this.page);
    const back = this.page
      .locator('[flt-semantics-identifier="experience_back_button"]')
      .or(this.page.getByRole('button', { name: /go back|retour|^back$/i }))
      .first();
    if (await back.isVisible({ timeout: 8_000 }).catch(() => false)) {
      await back.click();
    }
    await this.page.goto(flutterGotoUrl('/o/orgs'));
    await waitForFlutterRoutePattern(this.page, /\/o\/orgs(?:\?|$)/, 30_000);
    await new OrganizationListPage(this.page).expectLoaded();
    await refreshFlutterAccessibility(this.page);
  }

  async openEdit(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    const edit = this.page.getByRole('button', {
      name: /Edit organisation|Modifier l'organisation/i,
    });
    if (await edit.isVisible({ timeout: 5_000 }).catch(() => false)) {
      await edit.click();
    } else {
      await this.page
        .getByText(/Edit organisation|Edit Organization|Modifier l'organisation/i)
        .first()
        .click();
    }
    await this.page
      .getByRole('button', { name: /Edit Organization|Edit organisation/i })
      .last()
      .waitFor({ timeout: 30_000 });
  }

  async openArchivedPets(): Promise<void> {
    const orgId = this.orgIdFromUrl();
    const archivedRoute = /\/o\/orgs\/[^/]+\/archived(?:\/|$|\?)/;

    if (orgId) {
      await navigateWithShellFallback(
        this.page,
        archivedRoute,
        `/o/orgs/${orgId}/archived`,
        async () => {
          await refreshFlutterAccessibility(this.page);
        },
        { helper: 'OrganizationDetailPage.openArchivedPets', testTitle: null },
      );
    } else {
      await waitForFlutterRoutePattern(this.page, archivedRoute, 30_000);
    }

    await refreshFlutterAccessibility(this.page);
    await this.page
      .getByText(/Archived on|Archivé le/i)
      .or(this.page.getByText(/No archived pets|Aucun animal archivé/i))
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async expectFrozenShadowVisible(petName: string): Promise<void> {
    await this.page.locator('flt-semantics').filter({ hasText: 'Frozen shadow' }).first().waitFor({
      timeout: 30_000,
    });
    await expect(this.page.locator('flt-semantics').filter({ hasText: petName }).first()).toBeVisible();
  }

  async expectHomeHiddenSectionVisible(): Promise<void> {
    throw new Error(
      'Hidden-from-home section moved off the org dashboard hub — use org pets or a dedicated route.',
    );
  }

  async expandHomeHiddenSection(): Promise<void> {
    throw new Error(
      'Hidden-from-home section moved off the org dashboard hub — use org pets or a dedicated route.',
    );
  }

  /** EN "Pets" / FR "Animaux" — OrgSectionCard semantics label. */
  private static readonly petsSectionName = /^Pets$|^Animaux$/i;

  /**
   * OrgSectionCard exposes title via Semantics(button) + MergeSemantics — use role=button,
   * not getByText (see PR #434 UAT remedial). Returns false when the card is not in the tree
   * within `findTimeout` (Flutter web after hash-route fallback often needs direct navigation).
   */
  private async tryActivateSectionCard(
    name: RegExp,
    findTimeout = 10_000,
  ): Promise<boolean> {
    await enableFlutterAccessibility(this.page);
    await refreshFlutterAccessibility(this.page);
    const card = this.page.getByRole('button', { name }).filter({ visible: true }).first();
    if (!(await card.isVisible({ timeout: findTimeout }).catch(() => false))) {
      return false;
    }
    await card.scrollIntoViewIfNeeded();
    const box = await card.boundingBox();
    if (box) {
      await this.page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    } else {
      await card.click({ force: true });
    }
    return true;
  }

  async openPetsSection(): Promise<void> {
    const orgId = this.orgIdFromUrl();
    const petsRoute = /\/o\/orgs\/[^/]+\/pets/;

    let navigated = false;
    if (await this.tryActivateSectionCard(OrganizationDetailPage.petsSectionName)) {
      navigated = await waitForFlutterRoutePattern(this.page, petsRoute, 8_000)
        .then(() => true)
        .catch(() => false);
    }

    if (!navigated) {
      if (!orgId) {
        await waitForFlutterRoutePattern(this.page, petsRoute, 60_000);
        return;
      }
      await navigateWithShellFallback(
        this.page,
        petsRoute,
        `/o/orgs/${orgId}/pets`,
        async () => {
          await refreshFlutterAccessibility(this.page);
        },
        { helper: 'OrganizationDetailPage.openPetsSection' },
      );
    }
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, petsRoute, 60_000);
  }

  /** EN "Connected organisations" profile nav row. */
  async openConnectionsSection(): Promise<void> {
    const orgId = this.orgIdFromUrl();
    const connectionsRoute = /\/o\/orgs\/[^/]+\/connections/;

    let navigated = false;
    await enableFlutterAccessibility(this.page);
    await refreshFlutterAccessibility(this.page);
    const row = this.page
      .getByRole('button', {
        name: /Connected organisations|Organisations connectées/i,
      })
      .filter({ visible: true })
      .first();
    if (await row.isVisible({ timeout: 5_000 }).catch(() => false)) {
      await row.scrollIntoViewIfNeeded();
      await row.click();
      await refreshFlutterAccessibility(this.page);
      navigated = await waitForFlutterRoutePattern(this.page, connectionsRoute, 8_000)
        .then(() => true)
        .catch(() => false);
    }

    if (!navigated) {
      if (!orgId) {
        await waitForFlutterRoutePattern(this.page, connectionsRoute, 60_000);
        return;
      }
      await navigateWithShellFallback(
        this.page,
        connectionsRoute,
        `/o/orgs/${orgId}/connections`,
        async () => {
          await refreshFlutterAccessibility(this.page);
        },
        { helper: 'OrganizationDetailPage.openConnectionsSection', testTitle: null },
      );
    }
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, connectionsRoute, 60_000);
  }

  async openAddOrgPet(): Promise<void> {
    await this.openPetsSection();
    // App bar add — guardian manage-pets parity (no FAB).
    const addButton = this.page
      .getByRole('button', { name: 'Add Pet', exact: true })
      .filter({ visible: true })
      .first();
    await addButton.waitFor({ timeout: 30_000 });
    await addButton.click();
    await this.page.getByRole('button', { name: 'Save Pet' }).waitFor({ timeout: 30_000 });
  }

  async openManageFosters(): Promise<void> {
    const orgId = this.orgIdFromUrl();
    const fostersRoute = /\/o\/orgs\/[^/]+\/fosters/;

    let navigated = false;
    if (
      await this.tryActivateSectionCard(
        /^Manage fosters$|^Gérer les familles d'accueil$/i,
      )
    ) {
      navigated = await waitForFlutterRoutePattern(this.page, fostersRoute, 8_000)
        .then(() => true)
        .catch(() => false);
    }

    if (!navigated) {
      await enableFlutterAccessibility(this.page);
      const link = this.page
        .getByRole('button', { name: /Manage fosters|Gérer les familles d'accueil/i })
        .or(this.page.getByText(/Manage fosters|Gérer les familles d'accueil/i))
        .first();
      if (await link.isVisible({ timeout: 5_000 }).catch(() => false)) {
        await link.click();
        await refreshFlutterAccessibility(this.page);
        navigated = await waitForFlutterRoutePattern(this.page, fostersRoute, 8_000)
          .then(() => true)
          .catch(() => false);
      }
    }

    if (!navigated) {
      const bannerVisible = await this.page
        .getByRole('banner', { name: /Manage fosters|Gérer les familles d'accueil/i })
        .isVisible({ timeout: 3_000 })
        .catch(() => false);
      if (bannerVisible) {
        await refreshFlutterAccessibility(this.page);
        return;
      }
      if (!orgId) {
        await waitForFlutterRoutePattern(this.page, fostersRoute, 60_000);
        return;
      }
      await navigateWithShellFallback(
        this.page,
        fostersRoute,
        `/o/orgs/${orgId}/fosters`,
        async () => {
          await refreshFlutterAccessibility(this.page);
        },
        { helper: 'OrganizationDetailPage.openManageFosters', testTitle: 'Manage fosters' },
      );
    }
    await refreshFlutterAccessibility(this.page);
  }
}
