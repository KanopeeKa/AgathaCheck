import type { Page } from '@playwright/test';
import { dismissConsentBannerIfPresent } from '../support/flutter';

/**
 * Pet detail screen (`/pet/:petId`).
 * Maps to: flutter_app/test/bdd/features/pet_profiles.feature
 */
export class PetDetailPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(petName: string): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.page
      .getByRole('banner', { name: new RegExp(petName, 'i') })
      .or(this.page.getByRole('button', { name: new RegExp(`Edit Pet.*${petName}`, 'i') }))
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async expectSpecies(species: string): Promise<void> {
    await this.page
      .getByRole('button', { name: new RegExp(species, 'i') })
      .first()
      .waitFor();
  }

  async openEdit(): Promise<void> {
    await this.page.getByRole('button', { name: 'Edit Pet', exact: true }).click();
    await this.page.getByRole('button', { name: 'Update Pet' }).waitFor({ timeout: 30_000 });
  }
}
