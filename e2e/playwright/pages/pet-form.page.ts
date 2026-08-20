import type { Page } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  enableFlutterAccessibility,
  fillLabelledField,
  homeShellLocator,
  refreshFlutterAccessibility,
  selectDropdownOption,
  waitForHomeAfterMutation,
} from '../support/flutter';

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
    await this.typeIntoPetField(/^Name/, name);
  }

  async fillBreed(breed: string): Promise<void> {
    await this.typeIntoPetField(/^Breed/, breed);
  }

  /** Type into a Flutter web pet form textbox; fill() alone does not fire onChanged. */
  private async typeIntoPetField(name: string | RegExp, value: string): Promise<void> {
    const field = this.page.getByRole('textbox', { name });
    await field.waitFor({ state: 'visible' });
    await field.click();
    await this.page.waitForTimeout(200);
    await field.press('Control+a');
    await this.page.keyboard.press('Backspace');
    await this.page.keyboard.type(value, { delay: 45 });
    await field.press('Tab');
    await this.page.waitForTimeout(200);
  }

  async selectSpecies(species: string): Promise<void> {
    await selectDropdownOption(this.page, 'Species *', species);
    await refreshFlutterAccessibility(this.page);
  }

  async save(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const saveButton = this.page.getByRole('button', { name: /Save Pet|Update Pet/ });
    await saveButton.click();
    await this.page
      .getByRole('button', { name: /Save Pet|Update Pet/ })
      .waitFor({ state: 'hidden', timeout: 30_000 });
    await homeShellLocator(this.page)
      .or(this.page.getByRole('button', { name: /Pet:/i }))
      .or(this.page.getByRole('group', { name: /Pet:/i }))
      .or(this.page.getByRole('button', { name: 'Edit Organisation' }))
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async createPet(name: string, species: string): Promise<void> {
    await this.expectLoaded();
    await this.fillName(name);
    await this.selectSpecies(species);
    await this.page.waitForTimeout(300);
    await this.save();
  }

  async createPetWithBreed(name: string, species: string, breed: string): Promise<void> {
    await this.expectLoaded();
    await this.fillName(name);
    await this.selectSpecies(species);
    await this.page.waitForTimeout(300);
    await this.fillBreed(breed);
    await this.save();
  }

  /** Click the "Delete Pet" button to open the confirmation dialog. */
  async clickDeletePet(): Promise<void> {
    const deleteBtn = this.page.getByRole('button', { name: 'Delete Pet', exact: false });
    await deleteBtn.scrollIntoViewIfNeeded();
    await deleteBtn.click();
    await refreshFlutterAccessibility(this.page);
    await this.page.getByRole('button', { name: 'Delete', exact: true }).waitFor({ timeout: 15_000 });
  }

  /** Confirm the delete dialog. */
  async confirmDelete(): Promise<void> {
    await this.page.getByRole('button', { name: 'Delete', exact: true }).click();
    await waitForHomeAfterMutation(this.page);
  }

  /** Cancel the delete dialog. */
  async cancelDelete(): Promise<void> {
    await this.page.getByRole('button', { name: 'Cancel', exact: true }).click();
    await this.page.waitForTimeout(500);
    // Should still be on the edit form
    await this.page.getByRole('button', { name: /Update Pet/ }).waitFor({ timeout: 15_000 });
  }

  /** Click the "Passed Away" button to open the confirmation dialog. */
  async clickPassedAway(): Promise<void> {
    const btn = this.page.getByRole('button', { name: 'Passed Away', exact: false });
    await btn.scrollIntoViewIfNeeded();
    await btn.click();
    await refreshFlutterAccessibility(this.page);
    // Dialog shows OK and Cancel
    await this.page.getByRole('button', { name: 'OK', exact: true }).waitFor({ timeout: 15_000 });
  }

  /** Confirm the passed-away dialog. */
  async confirmPassedAway(): Promise<void> {
    await this.page.getByRole('button', { name: 'OK', exact: true }).click();
    await waitForHomeAfterMutation(this.page);
  }

  /** Cancel the passed-away dialog. */
  async cancelPassedAway(): Promise<void> {
    await this.page.getByRole('button', { name: 'Cancel', exact: true }).click();
    await this.page.waitForTimeout(500);
    await this.page.getByRole('button', { name: /Update Pet/ }).waitFor({ timeout: 15_000 });
  }

  async fillChipId(chipId: string): Promise<void> {
    await fillLabelledField(this.page, 'ID / Microchip', chipId);
  }

  async selectVeterinarian(vetName: string): Promise<void> {
    await selectDropdownOption(this.page, 'Veterinarians', vetName);
    await refreshFlutterAccessibility(this.page);
  }
}
