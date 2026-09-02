import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  enableFlutterAccessibility,
  escapeRegExp,
  expectAppBarTitle,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';

/**
 * Pet detail screen (`/pet/:petId`).
 * Maps to: flutter_app/test/bdd/features/pet_profiles.feature
 */
export class PetDetailPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(petName: string): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await waitForFlutterRoutePattern(this.page, /\/pet\/[^/?]+/, 30_000);
    await refreshFlutterAccessibility(this.page);
    // Pet detail UX (pet-detail-ux-c2ce): name is in AppBar title or profile-card
    // heading — use shared banner → heading → text fallbacks.
    await expectAppBarTitle(this.page, petName);
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

  async openOverflowMenu(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    const menu = this.page
      .locator('[flt-semantics-identifier="pet_detail_overflow_menu"]')
      .or(this.page.getByRole('button', { name: /More actions|Plus d'actions/i }));
    await menu.first().click();
  }

  async goBack(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await this.page
      .locator('[flt-semantics-identifier="experience_back_button"]')
      .or(this.page.getByRole('button', { name: /Back|Retour/i }))
      .first()
      .click();
  }

  async openEdit(): Promise<void> {
    await this.page.getByRole('button', { name: /edit pet/i }).first().click();
    await this.page.getByRole('button', { name: 'Update Pet' }).waitFor({ timeout: 30_000 });
  }

  async openSharingSection(): Promise<void> {
    await this.openOverflowMenu();
    const sharingItem = this.page
      .locator('[flt-semantics-identifier="pet_detail_sharing_menu_item"]')
      .or(this.page.getByRole('menuitem', { name: /^(?:Sharing\b|Partage)/i }));
    await sharingItem.first().click();
    await this.page.getByRole('button', { name: 'Share Link' }).waitFor({ timeout: 15_000 });
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
    await this.openOverflowMenu();
    const exportItem = this.page
      .locator('[flt-semantics-identifier="pet_detail_export_report_menu_item"]')
      .or(this.page.getByRole('menuitem', { name: /Download Pet Report|Télécharger le rapport/i }));
    await exportItem.first().click();
    await this.page.getByText(/^Download Pet Report$/i).first().waitFor({ timeout: 15_000 });
    await this.page.getByRole('button', { name: /Download Pet Report|Download Report/i }).last().click();
  }
}
