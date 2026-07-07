import type { Page } from '@playwright/test';
import { dismissConsentBannerIfPresent, enableFlutterAccessibility } from '../support/flutter';

/**
 * Public shared-pet preview (`/#/shared/:code`).
 * Maps to: flutter_app/test/bdd/features/sharing.feature
 */
export class SharedPetPage {
  constructor(private readonly page: Page) {}

  async goto(shareCode: string): Promise<void> {
    await this.page.goto(`/#/shared/${shareCode}`);
    await this.page.waitForSelector('flutter-view, flt-glass-pane', {
      state: 'attached',
      timeout: 60_000,
    });
    await enableFlutterAccessibility(this.page);
    await dismissConsentBannerIfPresent(this.page);
    await this.page.waitForTimeout(750);
  }

  async expectLoaded(petName: string): Promise<void> {
    await this.page
      .getByRole('banner', { name: new RegExp(petName, 'i') })
      .waitFor({ timeout: 30_000 });
  }

  async expectViewOnlyBadge(): Promise<void> {
    await this.page.getByText('View Only', { exact: true }).waitFor();
  }

  async expectSpecies(species: string): Promise<void> {
    await this.page.getByText(new RegExp(`\\b${species}\\b`, 'i')).first().waitFor();
  }

  async expectOwnerName(name: string): Promise<void> {
    await this.page.getByText('Shared by').waitFor();
    await this.page.getByText(name).waitFor();
  }

  async expectHealthEntry(name: string): Promise<void> {
    await this.page.getByText(name).waitFor();
  }

  async expectVet(name: string): Promise<void> {
    await this.page.getByText('Veterinarians').waitFor();
    const escaped = name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    await this.page.getByText(new RegExp(escaped)).nth(1).waitFor();
  }

  async acceptShare(): Promise<void> {
    await this.page.getByRole('button', { name: 'Accept & Add to My Pets' }).click();
    await this.page.waitForTimeout(2000);
  }

  async expectInvalidLink(): Promise<void> {
    await this.page.getByText('Pet not found or share link expired').waitFor();
    await this.page.getByRole('button', { name: 'Go to My Pets' }).waitFor();
  }
}
