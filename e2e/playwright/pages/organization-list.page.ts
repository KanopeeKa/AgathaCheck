import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import { dismissConsentBannerIfPresent } from '../support/flutter';

/**
 * Organization list screen (`/organizations`).
 * Maps to: flutter_app/test/bdd/features/organisation_management.feature
 */
export class OrganizationListPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.page.getByText('My Organizations').waitFor({ timeout: 30_000 });
  }

  async openCreateForm(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.page.getByRole('button', { name: 'Create' }).click();
    await this.page
      .getByRole('button', { name: 'Create Organization' })
      .waitFor({ timeout: 30_000 });
  }

  async expectOrgVisible(name: string): Promise<void> {
    await this.page
      .getByRole('button', { name: new RegExp(name, 'i') })
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async openOrg(name: string): Promise<void> {
    await this.expectOrgVisible(name);
    await this.page
      .getByRole('button', { name: new RegExp(name, 'i') })
      .first()
      .click();
    await this.page.waitForTimeout(750);
  }

  async acceptInviteForOrg(orgName: string): Promise<void> {
    await this.page.getByText(`You've been invited to join ${orgName}`).waitFor({
      timeout: 30_000,
    });
    await this.page.getByRole('button', { name: 'Accept' }).click();
    await this.page.getByText('Invitation accepted').waitFor({ timeout: 30_000 });
  }

  async declineInviteForOrg(orgName: string): Promise<void> {
    await this.page.getByText(`You've been invited to join ${orgName}`).waitFor({
      timeout: 30_000,
    });
    await this.page.getByRole('button', { name: 'Decline' }).click();
    await this.page.getByText('Invitation declined').waitFor({ timeout: 30_000 });
  }

  async expectNoPendingInvite(orgName: string): Promise<void> {
    await expect(
      this.page.getByText(`You've been invited to join ${orgName}`),
    ).toHaveCount(0);
  }
}
