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

  async expectPetVisible(name: string): Promise<void> {
    const petCard = this.page.locator('flt-semantics').filter({ hasText: name });
    const count = await petCard.count();
    for (let i = 0; i < count; i++) {
      if (await petCard.nth(i).isVisible()) {
        return;
      }
    }
    throw new Error(`Pet not visible on home screen: ${name}`);
  }
}
