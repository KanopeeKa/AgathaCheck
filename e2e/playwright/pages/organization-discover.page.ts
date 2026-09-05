import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  escapeRegExp,
  expectAppBarTitle,
  flutterRoutePath,
  refreshFlutterAccessibility,
} from '../support/flutter';

/**
 * Discover organisations screen (`/o/orgs/discover`).
 */
export class OrganizationDiscoverPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const path = flutterRoutePath(this.page.url());
      const onDiscoverRoute = /\/o\/orgs\/discover/.test(path);
      const banner = this.page.locator(
        '[flt-semantics-identifier="org_discover_browse_as_banner"]',
      );
      const titleVisible = await this.page
        .getByText(/^Discover Organisations|Découvrir des organisations$/i)
        .first()
        .isVisible()
        .catch(() => false);
      if (!onDiscoverRoute && !titleVisible) {
        throw new Error(`Discover screen not ready (path=${path})`);
      }
      if (!(await banner.isVisible().catch(() => false)) && !titleVisible) {
        throw new Error('Discover browse-as banner not visible');
      }
    }).toPass({ timeout: 30_000 });
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
    const banner = this.page
      .locator('[flt-semantics-identifier="org_discover_browse_as_banner"]')
      .or(this.page.getByText(pattern))
      .first();
    await expect(banner).toBeVisible({ timeout: 30_000 });
    await expect(banner).toContainText(pattern);
  }

  async searchByName(query: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const field = this.page
      .getByRole('textbox', { name: /Search by name|Rechercher par nom/i })
      .filter({ visible: true })
      .last();
    await field.fill(query);
    await refreshFlutterAccessibility(this.page);
  }
}
