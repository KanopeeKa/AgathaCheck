import type { Page } from '@playwright/test';
import { fillLabelledField } from '../support/flutter';

/**
 * Health entry form (`/health/add` or `/health/edit/:id`).
 */
export class HealthEntryFormPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
    await this.page.locator('input[aria-label*="Entry Name"]').first().waitFor();
  }

  async expectEditLoaded(): Promise<void> {
    await this.page.locator('input[aria-label*="Entry Name"]').first().waitFor();
  }

  async selectPet(petName: string): Promise<void> {
    await this.page
      .locator('flt-semantics')
      .filter({ hasText: petName })
      .first()
      .click();
  }

  async fillEntryName(name: string): Promise<void> {
    await fillLabelledField(this.page, 'Entry Name', name);
  }

  async fillDosage(dosage: string): Promise<void> {
    await fillLabelledField(this.page, 'Dosage', dosage);
  }

  /** Set completed-on to today via the date picker (edit form). */
  async setCompletedToday(): Promise<void> {
    await this.page.getByRole('button', { name: /Completed on: Not set/i }).click();
    await this.page.getByRole('button', { name: 'OK' }).click();
  }

  async save(): Promise<void> {
    await this.page
      .getByRole('button', { name: /add health event/i })
      .or(this.page.getByRole('button', { name: 'Save' }))
      .first()
      .click();
    await this.page.getByRole('button', { name: 'Add Health Event' }).waitFor({ timeout: 30_000 });
  }

  async saveEdit(): Promise<void> {
    await this.page.getByRole('button', { name: 'Save' }).click();
    await this.page.getByRole('button', { name: 'Add Health Event' }).waitFor({ timeout: 30_000 });
  }
}
