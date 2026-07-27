import type { Locator, Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  enableFlutterAccessibility,
  escapeRegExp,
  expectAppBarTitle,
  fillTextbox,
  navigateWithShellFallback,
  refreshFlutterAccessibility,
  selectDropdownOption,
  waitForFlutterRoutePattern,
} from '../support/flutter';
import { OrganizationListPage } from './organization-list.page';

/**
 * Organisation dashboard hub (`/o/orgs/:id`) — replaces the legacy detail screen.
 */
export class OrganizationDetailPage {
  constructor(private readonly page: Page) {}

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
        this.page
          .getByText(/Organisation presentation|Organisation dashboard|Choose a section/i)
          .first(),
      ).toBeVisible();
    }).toPass({ timeout: 30_000 });
  }

  /**
   * Members live at `/o/orgs/:id/members` (popup menu only on the dashboard hub).
   * Flutter web often misses PopupMenuItem taps — hash-route fallback mirrors
   * `openPetsSection` (PR #453 / UAT shard 3/11).
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

  async openPresentation(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await this.page
      .getByText(/Organisation presentation|Présentation de l'organisation/i)
      .first()
      .click();
    await refreshFlutterAccessibility(this.page);
    await this.page
      .getByText(/Organisation presentation|Présentation de l'organisation/i)
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async expectBio(bio: string): Promise<void> {
    await this.openPresentation();
    await expect(this.page.getByText(bio)).toBeVisible();
  }

  /** EN "All" / FR "Tous" — inclusive org pets tab (default is Need attention). */
  private static readonly allPetsTabName = /^(All|Tous)$/i;

  private async selectOrgPetsTab(name: RegExp): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await refreshFlutterAccessibility(this.page);
    const tab = this.page.getByRole('button', { name }).filter({ visible: true }).first();
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
    await new OrganizationListPage(this.page).expectLoaded();
  }

  async openEdit(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await this.page
      .getByText(/Edit organisation|Edit Organization|Modifier l'organisation/i)
      .first()
      .click();
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

  async openAddOrgPet(): Promise<void> {
    await this.openPetsSection();
    const addButton = this.page.getByRole('button', { name: /Add Pet/i });
    await addButton.waitFor({ timeout: 30_000 });
    await addButton.click();
    await this.page.getByRole('button', { name: 'Save Pet' }).waitFor({ timeout: 30_000 });
  }

  async openManageFosters(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await this.page.getByText(/Manage fosters|Gérer les familles d'accueil/i).first().click();
    await refreshFlutterAccessibility(this.page);
    const orgId = this.orgIdFromUrl();
    if (orgId) {
      await waitForFlutterRoutePattern(
        this.page,
        new RegExp(`/o/orgs/${orgId}/fosters`),
        60_000,
      );
    }
  }
}
