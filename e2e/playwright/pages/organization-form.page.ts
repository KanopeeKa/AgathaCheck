import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  enableFlutterAccessibility,
  fillTextbox,
  selectDropdownOption,
  waitForFlutterRoutePattern,
} from '../support/flutter';
import { OrganizationListPage } from './organization-list.page';

/**
 * Create / edit organization form (`/organizations/new`, `/organizations/:id/edit`).
 */
export class OrganizationFormPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await dismissConsentBannerIfPresent(this.page);
    await this.page
      .getByRole('button', { name: /Create Organisation|Edit Organisation/ })
      .waitFor({ timeout: 30_000 });
  }

  async fillName(name: string): Promise<void> {
    await fillTextbox(this.page, 'Organisation Name *', name);
  }

  async selectType(type: 'Professional' | 'Charity'): Promise<void> {
    await selectDropdownOption(this.page, 'Type', type);
  }

  async fillBio(bio: string): Promise<void> {
    await fillTextbox(this.page, 'Bio', bio);
  }

  async save(): Promise<void> {
    await this.page.getByRole('button', { name: /Create Organisation|Edit Organisation/ }).click();
  }

  async createOrganization(
    name: string,
    type: 'Professional' | 'Charity' = 'Professional',
  ): Promise<void> {
    await this.expectLoaded();
    await this.selectType(type);
    await this.fillName(name);
    await this.save();
    await this.page
      .getByText('Organisation created')
      .first()
      .or(this.page.getByRole('button', { name: 'Edit Organisation' }))
      .first()
      .waitFor({ timeout: 30_000 });
    try {
      await waitForFlutterRoutePattern(this.page, /\/o\/orgs\/[^/?#]+/, 8_000);
    } catch {
      // Flutter web sometimes stays on /o/orgs after create; list card + hash fallback.
      const list = new OrganizationListPage(this.page);
      await list.openOrg(name);
    }
  }

  async attemptSaveWithoutName(): Promise<void> {
    await this.expectLoaded();
    await this.page.getByRole('textbox', { name: 'Organisation Name *' }).fill('');
    await this.save();
  }

  async expectNameRequiredError(): Promise<void> {
    await expect(this.page.getByText('Organisation name is required').first()).toBeVisible();
  }

  async updateBio(bio: string): Promise<void> {
    await this.expectLoaded();
    await this.fillBio(bio);
    await this.save();
    await this.page.getByText('Organisation updated').first().waitFor({ timeout: 30_000 });
  }
}
