import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  expectAppBarTitle,
  fillLabelledField,
  flutterGotoUrl,
  isExperienceShellVisible,
  openExperienceDrawer,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';

/**
 * My Details screen (`/my-details`).
 * Maps to: flutter_app/test/bdd/features/authentication.feature
 */
export class MyDetailsPage {
  constructor(private readonly page: Page) {}

  async openFromUserMenu(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    const legacyMenu = this.page.getByRole('button', {
      name: /user menu|menu utilisateur/i,
    });
    if (await legacyMenu.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await legacyMenu.click();
      await this.page.waitForTimeout(500);
      await this.page
        .getByRole('menuitem', { name: /my details|mon profil/i })
        .or(this.page.getByText('My Details', { exact: true }))
        .or(this.page.getByText('Mon profil', { exact: true }))
        .first()
        .click();
      await this.expectLoaded();
      return;
    }

    if (await isExperienceShellVisible(this.page)) {
      await openExperienceDrawer(this.page);
      await this.page.getByText('Settings', { exact: true }).first().click();
      await refreshFlutterAccessibility(this.page);
      await this.page
        .getByText('My Details', { exact: true })
        .or(this.page.getByText('Mon profil', { exact: true }))
        .first()
        .click();
      await waitForFlutterRoutePattern(this.page, /\/my-details$/, 30_000);
      await this.expectLoaded();
      return;
    }

    // Fallback: direct hash-route navigation (e.g. drawer unavailable).
    await this.page.goto(flutterGotoUrl('/my-details'));
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/my-details$/, 30_000);
    await this.expectLoaded();

    throw new Error('Could not open My Details: unknown navigation shell');
  }

  async expectLoaded(title: string | RegExp = /My Details|Mon profil/i): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await refreshFlutterAccessibility(this.page);
    await expectAppBarTitle(this.page, title);
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
    await this.typeIntoProfileField(/^First Name/, firstName);
  }

  async fillBio(bio: string): Promise<void> {
    await this.typeIntoProfileField(/^Bio/, bio);
  }

  private async typeIntoProfileField(name: RegExp, value: string): Promise<void> {
    const field = this.page.getByRole('textbox', { name });
    await field.waitFor({ state: 'visible' });
    await field.click();
    await this.page.waitForTimeout(150);
    await field.press('Control+a');
    await this.page.keyboard.press('Backspace');
    await this.page.keyboard.type(value, { delay: 45 });
    await field.press('Tab');
    await this.page.waitForTimeout(150);
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

  async setLanguage(code: 'en' | 'fr'): Promise<void> {
    const optionLabel = code === 'fr' ? 'Français' : 'English';
    const languageHeading = this.page
      .getByText('Language', { exact: false })
      .or(this.page.getByText('Langue', { exact: false }));
    await languageHeading.first().scrollIntoViewIfNeeded();
    const dropdown = this.page
      .getByRole('button', { name: /English|Français/i })
      .or(this.page.getByRole('combobox'))
      .first();
    await dropdown.click();
    await this.page
      .getByRole('menuitem', { name: optionLabel, exact: true })
      .or(this.page.getByText(optionLabel, { exact: true }))
      .first()
      .click();
    await refreshFlutterAccessibility(this.page);
    await this.page.waitForTimeout(500);
  }

  async goBack(): Promise<void> {
    await this.page.getByRole('button', { name: /^(Back|Retour)$/i }).click();
    await this.page.waitForTimeout(500);
    await refreshFlutterAccessibility(this.page);
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
