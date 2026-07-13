import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  enableFlutterAccessibility,
  fillTextbox,
  selectDropdownOption,
} from '../support/flutter';

/**
 * Create / edit organization form (`/organizations/new`, `/organizations/:id/edit`).
 */
export class OrganizationFormPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await dismissConsentBannerIfPresent(this.page);
    await this.page
      .getByRole('button', { name: /Create Organization|Edit Organization/ })
      .waitFor({ timeout: 30_000 });
  }

  async fillName(name: string): Promise<void> {
    await fillTextbox(this.page, 'Organization Name *', name);
  }

  async selectType(type: 'Professional' | 'Charity'): Promise<void> {
    await selectDropdownOption(this.page, 'Type', type);
  }

  async fillBio(bio: string): Promise<void> {
    await fillTextbox(this.page, 'Bio', bio);
  }

  async save(): Promise<void> {
    await this.page.getByRole('button', { name: /Create Organization|Edit Organization/ }).click();
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
      .getByText('Organization created')
      .first()
      .or(this.page.getByRole('button', { name: 'Edit Organization' }))
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async attemptSaveWithoutName(): Promise<void> {
    await this.expectLoaded();
    await this.page.getByRole('textbox', { name: 'Organization Name *' }).fill('');
    await this.save();
  }

  async expectNameRequiredError(): Promise<void> {
    await expect(this.page.getByText('Organization name is required').first()).toBeVisible();
  }

  async updateBio(bio: string): Promise<void> {
    await this.expectLoaded();
    await this.fillBio(bio);
    await this.save();
    await this.page.getByText('Organization updated').first().waitFor({ timeout: 30_000 });
  }
}
