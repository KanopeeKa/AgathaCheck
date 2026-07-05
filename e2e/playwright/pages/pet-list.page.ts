import type { Page } from '@playwright/test';
import { dismissConsentBannerIfPresent } from '../support/flutter';

/**
 * Home / pet list screen (`/`).
 * Maps to: flutter_app/test/bdd/features/pet_profiles.feature
 */
export class PetListPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.page
      .getByRole('button', { name: 'To Do' })
      .or(this.page.getByRole('button', { name: 'Add Pet' }))
      .or(this.page.getByText('No pets yet'))
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async openHealthDashboard(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.page.getByRole('button', { name: 'To Do' }).click();
    await this.page.getByRole('button', { name: 'Add Health Event' }).waitFor({ timeout: 30_000 });
  }

  async expectEmptyState(): Promise<void> {
    await this.page.getByText('No pets yet').waitFor();
    await this.page.getByRole('button', { name: 'Add Pet' }).waitFor();
  }

  async openAddPet(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.page.getByRole('button', { name: 'Add Pet' }).click();
    await this.page.getByRole('button', { name: 'Save Pet' }).waitFor({ timeout: 30_000 });
  }

  async expectPetVisible(name: string): Promise<void> {
    await this.page
      .getByRole('button', { name: new RegExp(`Pet:\\s*${name}`, 'i') })
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async openPet(name: string): Promise<void> {
    await this.expectPetVisible(name);
    await this.page
      .getByRole('button', { name: new RegExp(`Pet:\\s*${name}`, 'i') })
      .first()
      .click();
    await this.page.waitForTimeout(1000);
  }
}
