import type { Page } from '@playwright/test';
import { dismissConsentBannerIfPresent, fillLabelledField, refreshFlutterAccessibility } from '../support/flutter';

/**
 * My Details screen (`/my-details`).
 * Maps to: flutter_app/test/bdd/features/authentication.feature
 */
export class MyDetailsPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.page
      .getByRole('heading', { name: 'My Details', exact: false })
      .or(this.page.getByText('My Details').first())
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async expectDisplayName(name: string): Promise<void> {
    await this.page.getByText(name, { exact: false }).first().waitFor({ timeout: 15_000 });
  }

  async expectEmail(email: string): Promise<void> {
    await this.page.getByText(email, { exact: false }).first().waitFor({ timeout: 15_000 });
  }

  async expectBio(bio: string): Promise<void> {
    await this.page.getByText(bio, { exact: false }).first().waitFor({ timeout: 15_000 });
  }

  async openEditSheet(): Promise<void> {
    const editButton = this.page
      .getByRole('button', { name: /edit.profile/i })
      .or(this.page.getByRole('button', { name: 'Edit profile', exact: false }))
      .first();
    await editButton.waitFor({ timeout: 15_000 });
    await editButton.click();
    // Wait for the sheet to appear (Save button becomes visible)
    await this.page.getByRole('button', { name: 'Save', exact: true }).waitFor({ timeout: 15_000 });
    await refreshFlutterAccessibility(this.page);
  }

  async fillFirstName(firstName: string): Promise<void> {
    await fillLabelledField(this.page, 'First Name', firstName);
  }

  async fillBio(bio: string): Promise<void> {
    await fillLabelledField(this.page, 'Bio', bio);
  }

  async saveProfileEdits(): Promise<void> {
    await this.page.getByRole('button', { name: 'Save', exact: true }).click();
    await this.page.waitForTimeout(2000);
  }

  async expectProfileUpdated(): Promise<void> {
    await this.page
      .getByText(/Profile updated/i)
      .first()
      .waitFor({ timeout: 15_000 });
  }
}
