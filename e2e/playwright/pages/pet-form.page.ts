import type { Locator, Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  enableFlutterAccessibility,
  fillLabelledField,
  postPetMutationShellLocator,
  refreshFlutterAccessibility,
  selectDropdownOption,
  semanticsByName,
  waitForHomeAfterMutation,
} from '../support/flutter';

const PRIMARY_SPECIES = ['Dog', 'Cat'] as const;

/**
 * Add / edit pet form (`/add`, `/edit/:id`).
 * Maps to: flutter_app/test/bdd/features/pet_profiles.feature
 */
export class PetFormPage {
  constructor(private readonly page: Page) {}

  private saveButtonLocator() {
    return this.page.getByRole('button', {
      name: /Save Pet|Save changes|Enregistrer l'animal|Enregistrer les modifications/i,
    });
  }

  private cancelButtonLocator() {
    return this.page.getByRole('button', { name: /^Cancel$|^Annuler$/i });
  }

  /** Pet form textboxes are unlabeled in semantics; order is stable within the form body. */
  private textboxAt(index: number): Locator {
    return this.page.getByRole('textbox').nth(index);
  }

  private async typeIntoTextbox(index: number, value: string): Promise<void> {
    const field = this.textboxAt(index);
    await field.waitFor({ state: 'visible' });
    await field.click();
    await this.page.waitForTimeout(150);
    await field.press('Control+a');
    await this.page.keyboard.press('Backspace');
    await this.page.keyboard.type(value, { delay: 45 });
    await field.press('Tab');
    await this.page.waitForTimeout(150);
  }

  async expectLoaded(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await dismissConsentBannerIfPresent(this.page);
    await this.saveButtonLocator().first().waitFor({ timeout: 30_000 });
    await this.cancelButtonLocator().first().waitFor({ timeout: 15_000 });
  }

  async fillName(name: string): Promise<void> {
    await this.typeIntoTextbox(0, name);
  }

  async fillBreed(breed: string): Promise<void> {
    await this.typeIntoTextbox(1, breed);
  }

  async selectSpecies(species: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    if (PRIMARY_SPECIES.includes(species as (typeof PRIMARY_SPECIES)[number])) {
      const chip = semanticsByName(this.page, species);
      if (await chip.isVisible().catch(() => false)) {
        await chip.click();
      } else {
        await expect(this.page.getByText(species, { exact: true }).first()).toBeVisible();
      }
    } else {
      await this.page.getByRole('checkbox', { name: /More species/i }).click();
      await this.page.getByRole('button', { name: species, exact: true }).click();
    }
    await refreshFlutterAccessibility(this.page);
  }

  async selectSex(sex: 'Female' | 'Male' | 'Unknown'): Promise<void> {
    await this.page.getByRole('button', { name: sex, exact: true }).click();
    await refreshFlutterAccessibility(this.page);
  }

  async uploadPhoto(filePath: string): Promise<void> {
    const fileChooserPromise = this.page.waitForEvent('filechooser');
    await this.page.getByRole('button', { name: /Change photo|Changer la photo/i }).click();
    const fileChooser = await fileChooserPromise;
    await fileChooser.setFiles(filePath);
    await this.page.waitForTimeout(500);
    await refreshFlutterAccessibility(this.page);
  }

  async expectSaveDisabled(): Promise<void> {
    await expect(this.saveButtonLocator().first()).toBeDisabled();
  }

  async expectEditPrefill(expected: {
    name: string;
    breed?: string;
    species?: string;
    sex?: 'Female' | 'Male' | 'Unknown';
  }): Promise<void> {
    await expect(
      this.page.getByRole('banner', { name: new RegExp(`Edit ${expected.name}`, 'i') }),
    ).toBeVisible();
    if (expected.species && expected.sex) {
      await expect(
        this.page.getByText(`${expected.name} ${expected.species} ${expected.sex}`).first(),
      ).toBeVisible();
    }
    if (expected.breed) {
      await expect(this.page.getByText(expected.breed, { exact: true }).first()).toBeVisible();
    } else if (expected.species) {
      await expect(this.page.getByText(expected.species, { exact: true }).first()).toBeVisible();
    }
    if (expected.sex) {
      await expect(this.page.getByRole('button', { name: expected.sex, exact: true })).toBeVisible();
    }
    await this.expectSaveDisabled();
  }

  async save(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const saveButton = this.saveButtonLocator().first();
    await expect(saveButton).toBeEnabled({ timeout: 15_000 });
    await saveButton.click();
    await this.saveButtonLocator().first().waitFor({ state: 'hidden', timeout: 30_000 });
    await postPetMutationShellLocator(this.page).waitFor({ timeout: 30_000 });
  }

  async cancel(): Promise<void> {
    // Prefer AppBar back — sticky Cancel collides with dialog Cancel in the a11y tree.
    const back = this.page
      .getByRole('banner')
      .getByRole('button', { name: /Back|Retour/i });
    if (await back.first().isVisible().catch(() => false)) {
      await back.first().click();
    } else {
      await this.cancelButtonLocator().first().click();
    }
  }

  async confirmDiscardUnsaved(): Promise<void> {
    await this.page.getByRole('button', { name: /^Discard$|^Abandonner$/i }).click();
  }

  async dismissDiscardUnsaved(): Promise<void> {
    await this.page
      .getByRole('button', { name: /^Cancel$|^Annuler$/i })
      .last()
      .click();
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
    await deleteBtn.first().scrollIntoViewIfNeeded();
    await deleteBtn.first().click();
    await refreshFlutterAccessibility(this.page);
    await this.page.getByRole('button', { name: 'Delete', exact: true }).waitFor({ timeout: 15_000 });
  }

  /** Confirm the delete dialog. */
  async confirmDelete(): Promise<void> {
    await this.page.getByRole('button', { name: 'Delete', exact: true }).click();
    await waitForHomeAfterMutation(this.page);
    await refreshFlutterAccessibility(this.page);
  }

  /** Cancel the delete dialog. */
  async cancelDelete(): Promise<void> {
    // Dialog Cancel is last in the a11y tree — form Cancel matches first (shard 6 flake).
    await this.cancelButtonLocator().last().click();
    await this.page
      .getByRole('button', { name: 'Delete', exact: true })
      .waitFor({ state: 'hidden', timeout: 15_000 });
    await this.saveButtonLocator().first().waitFor({ timeout: 15_000 });
  }

  /** Click the "Passed Away" button to open the confirmation dialog. */
  async clickPassedAway(): Promise<void> {
    const btn = this.page.getByRole('button', { name: 'Passed Away', exact: false });
    await btn.first().scrollIntoViewIfNeeded();
    await btn.first().click();
    await refreshFlutterAccessibility(this.page);
    await this.page.getByRole('button', { name: 'OK', exact: true }).waitFor({ timeout: 15_000 });
  }

  /** Confirm the passed-away dialog. */
  async confirmPassedAway(): Promise<void> {
    await this.page.getByRole('button', { name: 'OK', exact: true }).click();
    await waitForHomeAfterMutation(this.page);
  }

  /** Cancel the passed-away dialog. */
  async cancelPassedAway(): Promise<void> {
    await this.cancelButtonLocator().last().click();
    await this.page
      .getByRole('button', { name: 'OK', exact: true })
      .waitFor({ state: 'hidden', timeout: 15_000 });
    await this.saveButtonLocator().first().waitFor({ timeout: 15_000 });
  }

  async fillChipId(chipId: string): Promise<void> {
    await fillLabelledField(this.page, 'ID / Microchip', chipId);
  }

  async selectVeterinarian(vetName: string): Promise<void> {
    await selectDropdownOption(this.page, 'Veterinarians', vetName);
    await refreshFlutterAccessibility(this.page);
  }
}
