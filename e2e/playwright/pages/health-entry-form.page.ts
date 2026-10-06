import { expect, type Page } from '@playwright/test';
import { fillLabelledField } from '../support/flutter';

/**
 * Care entry form (`/care/add`, `/pet/:petId/care/add`, or `/health/edit/:id`).
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
    const checkbox = this.page.getByRole('checkbox', {
      name: new RegExp(petName, 'i'),
    });
    if (await checkbox.count()) {
      await checkbox.first().click();
      return;
    }
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
      .or(this.page.getByRole('button', { name: /Save changes|Save/i }))
      .first()
      .click();
    await this.page.getByRole('button', { name: 'Add Health Event' }).waitFor({ timeout: 30_000 });
  }

  async saveEdit(): Promise<void> {
    await this.page.getByRole('button', { name: /Save changes|Save/i }).click();
    await this.page.getByRole('button', { name: 'Add Health Event' }).waitFor({ timeout: 30_000 });
  }

  async selectCareFamily(label: string): Promise<void> {
    const picker = this.page.locator(
      'flt-semantics[flt-semantics-identifier="care_family_picker"]',
    );
    if ((await picker.count()) === 0) {
      await this.page.getByRole('button', { name: /Care category/i }).click();
    } else {
      await picker.click();
    }
    await this.page
      .getByRole('menuitem', { name: label, exact: true })
      .click();
  }

  async setFrequency(label: string): Promise<void> {
    await this.page.getByRole('button', { name: /^Frequency /i }).click();
    await this.page
      .getByRole('menuitem', { name: label, exact: true })
      .click();
  }

  async expandAdvancedSettings(): Promise<void> {
    const tile = this.page
      .getByRole('button', { name: /^Advanced settings/i })
      .or(
        this.page.locator(
          'flt-semantics[flt-semantics-identifier="health_entry_advanced_settings"]',
        ),
      );
    await tile.first().scrollIntoViewIfNeeded();
    await tile.first().click({ force: true });
  }

  async selectScheduleType(label: string): Promise<void> {
    await this.page.getByText(label, { exact: true }).click();
  }

  async expectScheduleTypeSelected(label: string): Promise<void> {
    await expect(this.page.getByText(label, { exact: true }).first()).toBeVisible();
  }

  async openCareProviderDropdown(): Promise<void> {
    await this.expandAdvancedSettings();
    const dropdown = this.page.locator(
      '[flt-semantics-identifier="care_provider_dropdown"]',
    );
    await dropdown.scrollIntoViewIfNeeded();
    await dropdown.click();
  }

  async selectCareProviderContact(name: string): Promise<void> {
    await this.openCareProviderDropdown();
    await this.page.getByRole('menuitem', { name, exact: true }).click();
  }

  async setCareProviderTypedName(name: string): Promise<void> {
    await this.expandAdvancedSettings();
    await this.page
      .getByRole('switch', { name: /Use a typed name|Utiliser un nom saisi/i })
      .check();
    await fillLabelledField(this.page, 'Typed name', name);
  }

  async expectCareProviderFieldShows(name: string): Promise<void> {
    await expect(this.page.getByText(name, { exact: true }).first()).toBeVisible({
      timeout: 15_000,
    });
  }
}
