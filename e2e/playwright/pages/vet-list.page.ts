/**
 * Veterinarian list screen (`/g/vets`, `/o/vets`).
 * Maps to: flutter_app/test/bdd/features/veterinarian_management.feature
 */
import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  escapeRegExp,
  expectAppBarTitle,
  refreshFlutterAccessibility,
  semanticsByName,
} from '../support/flutter';

export class VetListPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.page.getByText(/^Veterinarians$/i).first().waitFor({ timeout: 30_000 });
  }

  async expectEmptyState(): Promise<void> {
    await this.page.getByText(/no veterinarians yet/i).waitFor({ timeout: 30_000 });
  }

  async openAddForm(): Promise<void> {
    await this.page.getByRole('button', { name: 'Add Vet' }).click();
    await this.page.getByRole('textbox', { name: 'Name *' }).waitFor({ timeout: 30_000 });
  }

  async expectVetVisible(name: string): Promise<void> {
    await semanticsByName(
      this.page,
      new RegExp(`Veterinarian:\\s*${escapeRegExp(name)}`, 'i'),
    ).waitFor({ timeout: 30_000 });
  }

  async expectVetNotVisible(name: string): Promise<void> {
    await expect(
      this.page
        .getByRole('button', { name: new RegExp(`Veterinarian:\\s*${escapeRegExp(name)}`, 'i') })
        .or(
          this.page.getByRole('group', {
            name: new RegExp(`Veterinarian:\\s*${escapeRegExp(name)}`, 'i'),
          }),
        ),
    ).toHaveCount(0);
  }

  async expectVetCount(n: number): Promise<void> {
    await expect(
      this.page
        .getByRole('button', { name: /Veterinarian:/i })
        .or(this.page.getByRole('group', { name: /Veterinarian:/i })),
    ).toHaveCount(n, { timeout: 30_000 });
  }

  async clickEditVet(name: string): Promise<void> {
    const card = semanticsByName(
      this.page,
      new RegExp(`Veterinarian:\\s*${escapeRegExp(name)}`, 'i'),
    );
    await card.waitFor({ timeout: 30_000 });
    await card.getByRole('button', { name: /^Edit$/i }).click();
    await this.page.getByRole('textbox', { name: 'Name *' }).waitFor({ timeout: 30_000 });
  }

  async clickDeleteVet(name: string): Promise<void> {
    await this.clickEditVet(name);
    await this.page.getByRole('button', { name: /Delete Vet/i }).click();
    await refreshFlutterAccessibility(this.page);
  }

  async confirmDeletion(): Promise<void> {
    await this.page.getByRole('button', { name: 'Delete' }).last().click();
    await this.page.waitForTimeout(1_000);
  }

  async cancelDeletion(): Promise<void> {
    await this.page.getByRole('button', { name: 'Cancel' }).click();
    await this.page.waitForTimeout(500);
    await refreshFlutterAccessibility(this.page);
  }

  /** Vet delete cancel leaves the edit form open — return to the list before assertions. */
  async backToListFromEdit(): Promise<void> {
    await this.page.getByRole('button', { name: /back to veterinarians/i }).click();
    await refreshFlutterAccessibility(this.page);
    await this.expectLoaded();
  }

  async goBack(): Promise<void> {
    const home = this.page.getByRole('button', { name: /^Home$/i });
    if (await home.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await home.click();
    } else {
      await this.page.getByRole('button', { name: /go back/i }).click();
    }
    await this.page.waitForTimeout(500);
  }

  async expectPhoneVisible(phone: string, vetName?: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const pattern = vetName
      ? new RegExp(
          `Veterinarian:\\s*${escapeRegExp(vetName)}[\\s\\S]*${escapeRegExp(phone)}`,
          'i',
        )
      : new RegExp(escapeRegExp(phone), 'i');
    await semanticsByName(this.page, pattern).waitFor({
      timeout: 15_000,
    });
  }
}
