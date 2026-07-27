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

  async openMembers(): Promise<void> {
    await this.openMenu();
    await this.page.getByRole('menuitem', { name: /Members/i }).click();
    await refreshFlutterAccessibility(this.page);
    await this.page.getByText(/Members|People/i).first().waitFor({ timeout: 30_000 });
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

  async expectPetVisible(name: string): Promise<void> {
    await this.openPetsSection();
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
    if (orgId) {
      await this.page.goto(`/o/orgs/${orgId}/archived`);
      await refreshFlutterAccessibility(this.page);
    }
    await this.page
      .getByText(/Archived on/i)
      .or(this.page.getByText('No archived pets'))
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

  /**
   * OrgSectionCard exposes title via Semantics(button) + MergeSemantics — use role=button,
   * not getByText (see PR #434 UAT remedial).
   */
  private async activateSectionCard(name: RegExp): Promise<void> {
    await enableFlutterAccessibility(this.page);
    const card = this.page.getByRole('button', { name }).filter({ visible: true }).first();
    await card.scrollIntoViewIfNeeded();
    const box = await card.boundingBox();
    if (box) {
      await this.page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    } else {
      await card.click({ force: true });
    }
  }

  async openPetsSection(): Promise<void> {
    const orgId = this.orgIdFromUrl();
    const petsRoute = /\/o\/orgs\/[^/]+\/pets/;

    await this.activateSectionCard(/^Pets$/i);
    try {
      await waitForFlutterRoutePattern(this.page, petsRoute, 8_000);
    } catch {
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
