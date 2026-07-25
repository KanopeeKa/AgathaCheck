import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  enableFlutterAccessibility,
  fillTextbox,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';

export class ManageFostersPage {
  constructor(private readonly page: Page) {}

  async goto(orgId: string): Promise<void> {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await this.page.goto(`${baseURL.replace(/\/$/, '')}/o/orgs/${orgId}/fosters`);
    await waitForFlutterRoutePattern(this.page, new RegExp(`/o/orgs/${orgId}/fosters`), 60_000);
    await enableFlutterAccessibility(this.page);
    await this.expectLoaded();
  }

  async expectLoaded(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(
        this.page
          .getByRole('banner', { name: /Manage fosters/i })
          .or(this.page.getByText('Manage fosters'))
          .first(),
      ).toBeVisible();
      await expect(this.page.getByText('New')).toBeVisible();
      await expect(this.page.getByText('Fostering')).toBeVisible();
    }).toPass({ timeout: 30_000 });
  }

  async selectTab(label: 'New' | 'Fostering' | 'Recently fostered' | 'Inactive' | 'All'): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await this.page.getByRole('button', { name: label, exact: true }).click();
    await this.page.waitForTimeout(300);
    await refreshFlutterAccessibility(this.page);
  }

  async expectFosterVisible(name: string): Promise<void> {
    await expect(this.page.getByText(name, { exact: false })).toBeVisible();
  }

  async addManualFoster(name: string, email: string): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await this.page.getByRole('button', { name: 'Add foster manually' }).click();
    await fillTextbox(this.page, 'Display name', name);
    await fillTextbox(this.page, 'Email', email);
    await this.page.getByRole('checkbox').check();
    await this.page.getByRole('button', { name: 'Add foster parent' }).click();
    await this.page.waitForTimeout(500);
    await refreshFlutterAccessibility(this.page);
  }
}
