import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import { dismissConsentBannerIfPresent, enableFlutterAccessibility, escapeRegExp } from '../support/flutter';

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
    const shareLink = this.page.getByRole('button', { name: 'Share Link' });
    if (await shareLink.isVisible().catch(() => false)) {
      return;
    }
    await sharing.click();
    await shareLink.waitFor({ timeout: 15_000 });
  }

  async createShareLink(): Promise<void> {
    await this.openSharingSection();
    const copyLinkPattern = /Copy link|Copier le lien/i;
    const shareButtonPattern = /Share Link|Partager le lien|Lien de partage/i;
    const copyLinkLocator = this.page
      .getByRole('button', { name: copyLinkPattern })
      .or(this.page.getByRole('checkbox', { name: copyLinkPattern }));
    const copyLinksBefore = await copyLinkLocator.count();

    const shareButton = this.page.getByRole('button', { name: shareButtonPattern }).first();
    await shareButton.scrollIntoViewIfNeeded();
    await shareButton.click();

    // Link creation is async. Wait for a new Copy link tile (count-based) so pre-existing
    // pending links cannot satisfy the assertion. Click once — retries only poll the UI.
    const newCopyLink = copyLinkLocator.nth(copyLinksBefore);
    await expect(async () => {
      await newCopyLink.waitFor({ timeout: 5_000 });

      // Dismiss optional share-link AlertDialog without closing the sharing sheet.
      const shareDialog = this.page.getByRole('dialog', { name: shareButtonPattern });
      if (await shareDialog.isVisible().catch(() => false)) {
        await this.page.keyboard.press('Escape');
        await shareDialog.waitFor({ state: 'hidden', timeout: 5_000 }).catch(() => {});
      }
    }).toPass({ timeout: 30_000 });
  }

  async expectShareLinkDialog(): Promise<void> {
    const copyLinkPattern = /Copy link|Copier le lien/i;
    await this.page
      .getByRole('button', { name: copyLinkPattern })
      .or(this.page.getByRole('checkbox', { name: copyLinkPattern }))
      .first()
      .waitFor();
  }

  async expectAgeDisplay(pattern: RegExp): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await this.page
      .getByRole('group', { name: pattern })
      .or(this.page.getByRole('button', { name: pattern }))
      .or(this.page.getByText(pattern))
      .first()
      .waitFor({ timeout: 15_000 });
  }

  async expectIdentificationReminder(petName: string): Promise<void> {
    await enableFlutterAccessibility(this.page);
    const pattern = new RegExp(`${petName} has no identification`, 'i');
    await this.page.getByRole('group', { name: pattern }).first().waitFor({ timeout: 15_000 });
  }

  async expectNoIdentificationReminder(petName: string): Promise<void> {
    await expect(
      this.page.getByText(new RegExp(`${petName} has no identification`, 'i')),
    ).toHaveCount(0);
  }

  async expectPetPhotoVisible(petName: string): Promise<void> {
    await this.page
      .getByRole('img', { name: new RegExp(`Photo of ${petName}`, 'i') })
      .or(this.page.getByLabel(new RegExp(`Photo of ${petName}`, 'i')))
      .first()
      .waitFor({ timeout: 15_000 });
  }

  async expectLinkedVet(vetName: string): Promise<void> {
    await this.page.getByText(new RegExp(vetName, 'i')).first().waitFor({ timeout: 15_000 });
  }

  async downloadProfileReport(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    const exportBtn = this.page
      .locator('[flt-semantics-identifier="pet_detail_export_report_action"]')
      .or(this.page.getByRole('button', { name: /Download Pet Report|Download Report/i }));
    await exportBtn.first().click();
    await this.page.getByText(/^Download Pet Report$/i).first().waitFor({ timeout: 15_000 });
    await this.page.getByRole('button', { name: /Download Pet Report|Download Report/i }).last().click();
  }
}
