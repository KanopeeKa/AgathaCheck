import type { Page } from '@playwright/test';
import { dismissConsentBannerIfPresent, escapeRegExp } from '../support/flutter';

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
      .or(this.page.getByText(new RegExp(petName, 'i')))
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

  async expectBreed(breed: string): Promise<void> {
    const pattern = new RegExp(escapeRegExp(breed), 'i');
    await this.page
      .getByRole('group', { name: pattern })
      .or(this.page.getByRole('button', { name: pattern }))
      .or(this.page.getByText(pattern))
      .first()
      .waitFor({ timeout: 15_000 });
  }

  async openEdit(): Promise<void> {
    await this.page.getByRole('button', { name: /edit pet/i }).first().click();
    await this.page.getByRole('button', { name: 'Update Pet' }).waitFor({ timeout: 30_000 });
  }

  async openSharingSection(): Promise<void> {
    const sharing = this.page.getByRole('button', { name: /^Sharing\b/i });
    await sharing.scrollIntoViewIfNeeded();
    const expanded = await sharing.getAttribute('aria-expanded');
    if (expanded !== 'true') {
      await sharing.click();
      await this.page.waitForTimeout(500);
    }
  }

  async createShareLink(): Promise<void> {
    await this.openSharingSection();
    const copyLinkPattern = /Copy link|Copier le lien/i;
    const copyLinksBefore = await this.page
      .getByRole('button', { name: copyLinkPattern })
      .or(this.page.getByRole('checkbox', { name: copyLinkPattern }))
      .count();
    const shareButton = this.page
      .getByRole('button', { name: /Share Link|Partager le lien/i })
      .first();
    await shareButton.scrollIntoViewIfNeeded();
    await shareButton.click();
    await this.page.keyboard.press('Escape');
    await this.page
      .getByRole('button', { name: copyLinkPattern })
      .or(this.page.getByRole('checkbox', { name: copyLinkPattern }))
      .nth(copyLinksBefore)
      .waitFor({ timeout: 15_000 });
  }

  async expectShareLinkDialog(): Promise<void> {
    const copyLinkPattern = /Copy link|Copier le lien/i;
    await this.page
      .getByRole('button', { name: copyLinkPattern })
      .or(this.page.getByRole('checkbox', { name: copyLinkPattern }))
      .first()
      .waitFor();
  }
}
