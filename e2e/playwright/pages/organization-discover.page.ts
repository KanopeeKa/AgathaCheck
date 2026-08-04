import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  escapeRegExp,
  expectAppBarTitle,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';

/**
 * Discover organisations screen (`/o/orgs/discover`).
 */
export class OrganizationDiscoverPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await waitForFlutterRoutePattern(this.page, /\/o\/orgs\/discover/, 30_000);
    await refreshFlutterAccessibility(this.page);
    await expectAppBarTitle(this.page, /Discover Organisations|Découvrir des organisations/i);
  }

  async expectOrgVisible(name: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(
      this.page.getByRole('button', { name: new RegExp(name, 'i') }).filter({ visible: true }),
    ).toBeVisible({ timeout: 30_000 });
  }

  async expectBrowseAsOrg(orgName: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const pattern = new RegExp(
      `You are browsing as ${escapeRegExp(orgName)}|Vous parcourez en tant que ${escapeRegExp(orgName)}`,
      'i',
    );
    await expect(this.page.getByText(pattern).first()).toBeVisible({ timeout: 30_000 });
  }
}
