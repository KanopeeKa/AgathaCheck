import type { Locator, Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  enableFlutterAccessibility,
  expectAppBarTitle,
  fillTextbox,
  refreshFlutterAccessibility,
  selectDropdownOption,
} from '../support/flutter';

/**
 * Organization detail screen (`/organizations/:id`).
 */
export class OrganizationDetailPage {
  constructor(private readonly page: Page) {}

  private async scrollUntilVisible(locator: Locator): Promise<void> {
    for (let i = 0; i < 12; i++) {
      if ((await locator.count()) > 0 && (await locator.first().isVisible().catch(() => false))) {
        return;
      }
      await this.page.mouse.wheel(0, 900);
      await this.page.waitForTimeout(250);
    }
  }

  async expectLoaded(orgName: string): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.page
      .getByText(orgName, { exact: true })
      .or(this.page.getByRole('button', { name: 'Edit Organization' }))
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async expectMemberVisible(name: string): Promise<void> {
    await this.page.getByText(name).first().waitFor({ timeout: 30_000 });
  }

  async expectMemberCount(count: number): Promise<void> {
    const label = `${count} registered members`;
    await this.page.getByText(label).waitFor({ timeout: 30_000 });
  }

  async expectBio(bio: string): Promise<void> {
    await expect(this.page.getByText(bio)).toBeVisible();
  }

  async expectPetVisible(name: string): Promise<void> {
    const pet = this.page.getByText(name, { exact: true }).last();
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
    await selectDropdownOption(this.page, 'Select role', roleLabel);
    await this.page.getByRole('button', { name: 'Send Invite' }).click();
    await this.page.getByText('Invitation sent successfully').waitFor({ timeout: 30_000 });
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
    await expectAppBarTitle(this.page, 'My Organizations');
  }

  async openEdit(): Promise<void> {
    await this.page.getByRole('button', { name: 'Edit Organization' }).click();
    await this.page
      .getByRole('button', { name: 'Edit Organization' })
      .last()
      .waitFor({ timeout: 30_000 });
  }

  async openArchivedPets(): Promise<void> {
    const archived = this.page.getByText('Archived Pets').last();
    await this.scrollUntilVisible(archived);
    await archived.click();
    await refreshFlutterAccessibility(this.page);
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
    const hidden = this.page.getByText('Hidden from home list').last();
    await hidden.scrollIntoViewIfNeeded();
    await hidden.waitFor({ timeout: 30_000 });
  }

  async expandHomeHiddenSection(): Promise<void> {
    await this.expectHomeHiddenSectionVisible();
    const hidden = this.page.getByText('Hidden from home list').last();
    await hidden.click();
    await this.page.getByRole('button', { name: 'Unhide' }).first().waitFor({ timeout: 30_000 });
  }

  async openAddOrgPet(): Promise<void> {
    const addButton = this.page
      .getByRole('button', { name: 'Add Pet' })
      .or(this.page.locator('[flt-semantics-identifier="org_add_pet_button"]'))
      .or(this.page.locator('[flt-semantics-identifier="org_add_pet_empty"]'));
    await addButton.first().click();
    await this.page.getByRole('button', { name: 'Save Pet' }).waitFor({ timeout: 30_000 });
  }
}
