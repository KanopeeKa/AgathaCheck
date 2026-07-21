import type { Page } from '@playwright/test';
import { dismissConsentBannerIfPresent, enableFlutterAccessibility } from '../support/flutter';
import { isLiveHostingTarget } from '../support/hosting';
import { passHostingWaf } from '../support/waf';

/**
 * Public shared-pet preview (`/#/shared/:code`).
 * Maps to: flutter_app/test/bdd/features/sharing.feature
 */
export class SharedPetPage {
  constructor(private readonly page: Page) {}

  async goto(shareCode: string): Promise<void> {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    if (isLiveHostingTarget(baseURL)) {
      await passHostingWaf(this.page, baseURL);
    }
    await this.page.goto(`/#/shared/${shareCode}`, {
      waitUntil: 'domcontentloaded',
      timeout: 60_000,
    });
    await this.page.waitForSelector('flutter-view, flt-glass-pane', {
      state: 'attached',
      timeout: isLiveHostingTarget(baseURL) ? 90_000 : 60_000,
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
    await this.page
      .getByText(/^(View Only|Lecture seule)$/i)
      .waitFor({ timeout: 30_000 });
  }

  async expectSpecies(species: string): Promise<void> {
    const localized: Record<string, string> = { Dog: 'Chien', Cat: 'Chat' };
    const fr = localized[species];
    const pattern = fr
      ? new RegExp(`\\b(${species}|${fr})\\b`, 'i')
      : new RegExp(`\\b${species}\\b`, 'i');
    await this.page.getByText(pattern).first().waitFor({ timeout: 30_000 });
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
