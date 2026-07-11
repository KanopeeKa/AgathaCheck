import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  escapeRegExp,
  expectAppBarTitle,
  refreshFlutterAccessibility,
  semanticsByName,
} from '../support/flutter';

/**
 * Veterinarian list screen (`/vets`).
 * Maps to: flutter_app/test/bdd/features/veterinarian_management.feature
 */
export class VetListPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await expectAppBarTitle(this.page, 'Veterinarians');
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

  /** Open the three-dot options menu for the vet card matching `name`. */
  async openVetMenu(name: string): Promise<void> {
    await this.expectVetVisible(name);
    const escaped = escapeRegExp(name);
    const namePattern = new RegExp(`Veterinarian:\\s*${escaped}(?:,|$)`);
    const vetCards = this.page
      .getByRole('button', { name: /Veterinarian:/i })
      .or(this.page.getByRole('group', { name: /Veterinarian:/i }));
    const cardCount = await vetCards.count();
    for (let i = 0; i < cardCount; i++) {
      const card = vetCards.nth(i);
      const accessibleName =
        (await card.getAttribute('aria-label')) ?? (await card.innerText());
      if (namePattern.test(accessibleName)) {
        await this.page.getByRole('button', { name: 'Vet options' }).nth(i).click();
        await refreshFlutterAccessibility(this.page);
        return;
      }
    }
    throw new Error(`Could not find vet options menu for "${name}"`);
  }

  async clickEditVet(name: string): Promise<void> {
    await this.openVetMenu(name);
    await this.page.getByRole('menuitem', { name: 'Edit' }).click();
    await this.page.getByRole('textbox', { name: 'Name *' }).waitFor({ timeout: 30_000 });
  }

  async clickDeleteVet(name: string): Promise<void> {
    await this.openVetMenu(name);
    await this.page.getByRole('menuitem', { name: 'Delete' }).click();
    await refreshFlutterAccessibility(this.page);
  }

  async confirmDeletion(): Promise<void> {
    await this.page.getByRole('button', { name: 'Delete' }).last().click();
    await this.page.waitForTimeout(1_000);
  }

  async cancelDeletion(): Promise<void> {
    await this.page.getByRole('button', { name: 'Cancel' }).click();
    await this.page.waitForTimeout(500);
  }

  async goBack(): Promise<void> {
    await this.page.getByRole('button', { name: /go back/i }).click();
    await this.page.waitForTimeout(500);
  }

  async expectPhoneVisible(phone: string): Promise<void> {
    await semanticsByName(this.page, new RegExp(escapeRegExp(phone), 'i')).waitFor({
      timeout: 15_000,
    });
  }
}
