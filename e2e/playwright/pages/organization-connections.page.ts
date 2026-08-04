import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  enableFlutterAccessibility,
  expectAppBarTitle,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';

/**
 * Connected organisations screen (`/o/orgs/:id/connections`).
 */
export class OrganizationConnectionsPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await waitForFlutterRoutePattern(this.page, /\/o\/orgs\/[^/]+\/connections/, 30_000);
    await refreshFlutterAccessibility(this.page);
    await expectAppBarTitle(
      this.page,
      /Connected organisations|Organisations connectées/i,
    );
  }

  async expectNoConnectButton(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await expect(this.page.getByRole('button', { name: /Connect to organisation/i })).toHaveCount(0);
    await expect(this.page.getByRole('button', { name: /Manage members/i })).toHaveCount(0);
  }

  discoverCta() {
    return this.page
      .locator('[flt-semantics-identifier="org_connections_discover_cta"]')
      .or(this.page.getByRole('button', { name: /Discover Organisations|Découvrir des organisations/i }))
      .filter({ visible: true })
      .first();
  }

  async openDiscover(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    const cta = this.discoverCta();
    await cta.scrollIntoViewIfNeeded();
    await cta.click();
    await waitForFlutterRoutePattern(this.page, /\/o\/orgs\/discover/, 30_000);
  }

  async goBack(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await this.page.getByRole('button', { name: /Back|Retour/i }).first().click();
    await refreshFlutterAccessibility(this.page);
  }
}
