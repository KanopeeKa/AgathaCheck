import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  enableFlutterAccessibility,
  escapeRegExp,
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
      await expect(
        this.page
          .getByRole('checkbox', { name: 'New' })
          .or(this.page.getByRole('button', { name: 'New', exact: true }))
          .first(),
      ).toBeVisible();
      await expect(
        this.page
          .getByRole('checkbox', { name: 'Fostering' })
          .or(this.page.getByRole('button', { name: 'Fostering', exact: true }))
          .first(),
      ).toBeVisible();
    }).toPass({ timeout: 30_000 });
  }

  async selectTab(label: 'New' | 'Fostering' | 'Recently fostered' | 'Inactive' | 'All'): Promise<void> {
    await enableFlutterAccessibility(this.page);
    const tab = this.page
      .getByRole('checkbox', { name: label, exact: true })
      .or(this.page.getByRole('button', { name: label, exact: true }));
    await tab.first().click();
    await this.page.waitForTimeout(300);
    await refreshFlutterAccessibility(this.page);
  }

  async expectFosterVisible(name: string): Promise<void> {
    const pattern = new RegExp(escapeRegExp(name), 'i');
    await expect(
      this.page
        .getByRole('group', { name: pattern })
        .or(this.page.getByRole('button', { name: pattern }))
        .or(this.page.getByText(name, { exact: false }))
        .first(),
    ).toBeVisible();
  }

  async openOverflowMenu(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    const menu = this.page
      .locator('[flt-semantics-identifier="manage_fosters_menu"]')
      .or(this.page.getByRole('button', { name: 'Show menu' }));
    await menu.first().click();
    await refreshFlutterAccessibility(this.page);
  }

  async addManualFoster(name: string, email: string): Promise<void> {
    await this.openOverflowMenu();
    await this.page.getByRole('menuitem', { name: 'Add foster manually' }).click();
    await fillTextbox(this.page, 'Display name', name);
    await fillTextbox(this.page, 'Email', email);
    const terms = this.page.getByRole('checkbox', {
      name: /I confirm I have a lawful basis/i,
    });
    await terms.scrollIntoViewIfNeeded();
    await terms.focus();
    await this.page.keyboard.press('Space');
    await refreshFlutterAccessibility(this.page);
    await this.page.getByRole('button', { name: 'Add foster parent' }).click();
    await expect(
      this.page.getByText(/External foster added|privacy notice sent/i).first(),
    ).toBeVisible({ timeout: 30_000 });
    await refreshFlutterAccessibility(this.page);
  }
}
