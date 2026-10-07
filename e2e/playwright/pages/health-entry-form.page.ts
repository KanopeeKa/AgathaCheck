import { expect, type Page } from '@playwright/test';
import { fillLabelledField, refreshFlutterAccessibility } from '../support/flutter';

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
    await expect(dropdown).toBeVisible({ timeout: 60_000 });
    await dropdown.scrollIntoViewIfNeeded();
    await dropdown.click({ force: true });
  }

  async selectCareProviderContact(name: string): Promise<void> {
    await this.openCareProviderDropdown();
    const option = this.page.getByRole('menuitem', { name, exact: true });
    await expect(option).toBeVisible({ timeout: 60_000 });
    await option.click();
  }

  async setCareProviderTypedName(name: string): Promise<void> {
    await this.expandAdvancedSettings();
    const toggle = this.page.locator(
      '[flt-semantics-identifier="care_provider_use_typed_name"]',
    );
    await toggle.click();
    const field = this.page.locator(
      '[flt-semantics-identifier="care_provider_typed_name_field"] input',
    );
    await expect(field).toBeVisible({ timeout: 30_000 });
    await field.click();
    await field.fill('');
    await field.pressSequentially(name, { delay: 25 });
    await refreshFlutterAccessibility(this.page);
  }

  async expectCareProviderDropdownShows(name: string): Promise<void> {
    await this.expandAdvancedSettings();
    const dropdown = this.page.locator(
      '[flt-semantics-identifier="care_provider_dropdown"]',
    );
    await expect(dropdown).toContainText(name, { timeout: 15_000 });
  }

  async expectCareProviderTypedNameShows(name: string): Promise<void> {
    await this.expandAdvancedSettings();
    const field = this.page.locator(
      '[flt-semantics-identifier="care_provider_typed_name_field"] input',
    );
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(field).toHaveValue(name);
    }).toPass({ timeout: 30_000 });
  }
}
