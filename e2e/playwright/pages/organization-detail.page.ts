import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  enableFlutterAccessibility,
  fillTextbox,
  refreshFlutterAccessibility,
  selectDropdownOption,
} from '../support/flutter';

/**
 * Organization detail screen (`/organizations/:id`).
 */
export class OrganizationDetailPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(orgName: string): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.page.getByText(orgName, { exact: true }).first().waitFor({ timeout: 30_000 });
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
    await this.page.getByText('My Organizations').waitFor({ timeout: 30_000 });
  }

  async openEdit(): Promise<void> {
    await this.page.getByRole('button', { name: 'Edit Organization' }).click();
    await this.page
      .getByRole('button', { name: 'Edit Organization' })
      .last()
      .waitFor({ timeout: 30_000 });
  }

  async openArchivedPets(): Promise<void> {
    await this.page.getByText('Archived Pets').click();
    await this.page.getByRole('button', { name: 'Archived Pets' }).waitFor({ timeout: 30_000 });
  }

  async expectFrozenShadowVisible(petName: string): Promise<void> {
    await this.page.getByText('Frozen shadow').first().waitFor({ timeout: 30_000 });
    await expect(this.page.getByText(petName).first()).toBeVisible();
  }
}
