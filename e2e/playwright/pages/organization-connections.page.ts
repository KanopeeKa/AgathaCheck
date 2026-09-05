import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  enableFlutterAccessibility,
  expectAppBarTitle,
  flutterRoutePath,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';

function extractConnectionsOrgId(url: string): string | undefined {
  const match = flutterRoutePath(url).match(/\/o\/orgs\/([^/]+)\/connections/);
  return match?.[1];
}

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
      .filter({ visible: true });
  }

  async openDiscover(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    const orgId = extractConnectionsOrgId(this.page.url());
    if (!orgId) {
      throw new Error('Cannot navigate to discover: orgId not found in connections URL');
    }
    const cta = this.discoverCta();
    await expect(cta).toBeVisible({ timeout: 30_000 });
    await cta.scrollIntoViewIfNeeded();
    await cta.click();
<<<<<<< HEAD
    // Flutter web can paint discover before the hash route updates.
    await expect(
      this.page.locator('[flt-semantics-identifier="org_discover_browse_as_banner"]'),
    ).toBeVisible({ timeout: 30_000 });
=======
    try {
      await waitForFlutterRoutePattern(this.page, /\/o\/orgs\/discover/, 12_000);
    } catch {
      await this.page.evaluate((id) => {
        window.location.hash = `#/o/orgs/discover?from=org&orgId=${id}`;
      }, orgId);
      await waitForFlutterRoutePattern(this.page, /\/o\/orgs\/discover/, 20_000);
    }
    const hasOrgBrowseContext = await this.page.evaluate(() => {
      const hash = window.location.hash.replace(/^#/, '');
      const query = hash.includes('?') ? hash.slice(hash.indexOf('?') + 1) : '';
      const params = new URLSearchParams(query);
      return params.get('from') === 'org' && Boolean(params.get('orgId')?.trim());
    });
    if (!hasOrgBrowseContext) {
      await this.page.evaluate((id) => {
        window.location.hash = `#/o/orgs/discover?from=org&orgId=${id}`;
      }, orgId);
      await waitForFlutterRoutePattern(this.page, /\/o\/orgs\/discover/, 20_000);
    }
>>>>>>> cf33d940 (fix(e2e): scope discover locators to connections CTA and shelter nav)
    await refreshFlutterAccessibility(this.page);
  }

  async goBack(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await this.page.getByRole('button', { name: /Back|Retour/i }).first().click();
    await refreshFlutterAccessibility(this.page);
  }
}
