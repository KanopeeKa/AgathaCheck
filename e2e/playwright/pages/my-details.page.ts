import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  expectAppBarTitle,
  fillLabelledField,
  refreshFlutterAccessibility,
} from '../support/flutter';

/**
 * My Details screen (`/my-details`).
 * Maps to: flutter_app/test/bdd/features/authentication.feature
 */
export class MyDetailsPage {
  constructor(private readonly page: Page) {}

  async openFromUserMenu(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.page.getByRole('button', { name: /user.menu/i }).click();
    await this.page.waitForTimeout(500);
    await this.page
      .getByRole('menuitem', { name: /my.details/i })
      .or(this.page.getByText('My Details', { exact: true }))
      .first()
      .click();
    await this.expectLoaded();
  }

  async expectLoaded(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await refreshFlutterAccessibility(this.page);
    await expectAppBarTitle(this.page, 'My Details');
  }

  async expectDisplayName(name: string): Promise<void> {
    const pattern = new RegExp(name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(this.page.getByRole('button', { name: pattern }).first()).toBeVisible();
    }).toPass({ timeout: 20_000 });
  }

  async expectEmail(email: string): Promise<void> {
    const pattern = new RegExp(email.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
    await expect(this.page.getByRole('button', { name: pattern }).first()).toBeVisible({
      timeout: 15_000,
    });
  }

  async expectBio(bio: string): Promise<void> {
    const pattern = new RegExp(bio.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(
        this.page
          .getByRole('button', { name: pattern })
          .or(this.page.getByText(bio, { exact: false }))
          .first(),
      ).toBeVisible();
    }).toPass({ timeout: 20_000 });
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
    await this.expectProfileUpdated();
    await this.page.waitForTimeout(500);
    await refreshFlutterAccessibility(this.page);
  }

  async expectProfileUpdated(): Promise<void> {
    await this.page
      .getByText(/Profile updated/i)
      .first()
      .waitFor({ timeout: 15_000 });
  }

  async exportMyData(): Promise<void> {
    const exportButton = this.page.getByRole('button', { name: /Export My Data/i });
    await exportButton.scrollIntoViewIfNeeded();
    await exportButton.click();
    await this.page.getByText('Your data has been exported').first().waitFor({ timeout: 30_000 });
  }

  async deleteAccount(password: string): Promise<void> {
    const deleteButton = this.page.getByRole('button', { name: /Delete Account/i }).first();
    await deleteButton.scrollIntoViewIfNeeded();
    await deleteButton.click();
    await this.page.getByRole('dialog', { name: 'Alert' }).waitFor({ timeout: 15_000 });
    await fillLabelledField(this.page, 'Current Password', password);
    await this.page
      .getByRole('button', { name: 'Delete Account', exact: true })
      .last()
      .click();
    await this.page.waitForTimeout(2000);
  }
}
