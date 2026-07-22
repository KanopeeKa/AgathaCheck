import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import { dismissConsentBannerIfPresent, expectAppBarTitle, escapeRegExp, refreshFlutterAccessibility, semanticsByName } from '../support/flutter';

/**
 * Organization list screen (`/organizations`).
 * Maps to: flutter_app/test/bdd/features/organisation_management.feature
 */
export class OrganizationListPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expectAppBarTitle(this.page, 'My Organizations');
    }).toPass({ timeout: 30_000 });
  }

  async openCreateForm(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.page.getByRole('button', { name: 'Create' }).click();
    await this.page
      .getByRole('button', { name: 'Create Organization' })
      .waitFor({ timeout: 30_000 });
  }

  async expectOrgVisible(name: string): Promise<void> {
    await semanticsByName(this.page, new RegExp(name, 'i')).waitFor({ timeout: 30_000 });
  }

  async openOrg(name: string): Promise<void> {
    await this.expectOrgVisible(name);
    await semanticsByName(this.page, new RegExp(name, 'i')).click();
    await this.page.waitForTimeout(750);
  }

  async acceptInviteForOrg(orgName: string): Promise<void> {
    await this.page
      .getByText(new RegExp(escapeRegExp(orgName), 'i'))
      .or(this.page.getByRole('group', { name: new RegExp(escapeRegExp(orgName), 'i') }))
      .first()
      .waitFor({ timeout: 30_000 })
      .catch(() => undefined);
    await this.page.getByRole('button', { name: /^Accept$/i }).first().click();
    await this.page.getByText(/Invitation accepted/i).first().waitFor({ timeout: 30_000 });
    await refreshFlutterAccessibility(this.page);
    // Accept navigates to org detail; return to the list for card assertions.
    const back = this.page.getByRole('button', { name: /^Back$/i });
    if (await back.count()) {
      await back.first().click();
      await this.expectLoaded();
      await refreshFlutterAccessibility(this.page);
    }
  }

  async declineInviteForOrg(orgName: string): Promise<void> {
    await this.page
      .getByText(new RegExp(escapeRegExp(orgName), 'i'))
      .or(this.page.getByRole('group', { name: new RegExp(escapeRegExp(orgName), 'i') }))
      .first()
      .waitFor({ timeout: 30_000 })
      .catch(() => undefined);
    await this.page.getByRole('button', { name: /^Decline$/i }).first().click();
    await this.page.getByText(/Invitation declined/i).first().waitFor({ timeout: 30_000 });
    await refreshFlutterAccessibility(this.page);
  }

  async expectNoPendingInvite(orgName: string): Promise<void> {
    await expect(this.page.getByRole('button', { name: /^Accept$/i })).toHaveCount(0);
    await expect(
      this.page.getByText(new RegExp(`invited to join.*${escapeRegExp(orgName)}`, 'i')),
    ).toHaveCount(0);
  }
}
