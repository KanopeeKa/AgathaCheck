import type { Page } from '@playwright/test';
import { dismissConsentBannerIfPresent, enableFlutterAccessibility, fillTextbox, selectDropdownOption } from '../support/flutter';

/**
 * Add / edit pet form (`/add`, `/edit/:id`).
 * Maps to: flutter_app/test/bdd/features/pet_profiles.feature
 */
export class PetFormPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await dismissConsentBannerIfPresent(this.page);
    await this.page
      .getByRole('button', { name: /Save Pet|Update Pet/ })
      .waitFor({ timeout: 30_000 });
  }

  async fillName(name: string): Promise<void> {
    await fillTextbox(this.page, 'Name *', name);
  }

  async selectSpecies(species: string): Promise<void> {
    await selectDropdownOption(this.page, 'Species *', species);
  }

  async save(): Promise<void> {
    const saveButton = this.page.getByRole('button', { name: /Save Pet|Update Pet/ });
    await saveButton.click();
    await this.page
      .getByRole('button', { name: 'To Do' })
      .or(this.page.getByRole('button', { name: 'Add Pet' }))
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async createPet(name: string, species: string): Promise<void> {
    await this.expectLoaded();
    await this.selectSpecies(species);
    await this.page.waitForTimeout(300);
    await this.fillName(name);
    await this.save();
  }
}
