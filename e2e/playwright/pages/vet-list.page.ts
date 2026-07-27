/**
 * Veterinarian list screen (`/g/vets`, `/o/vets`).
 * Maps to: flutter_app/test/bdd/features/veterinarian_management.feature
 */
import type { Locator, Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  escapeRegExp,
  refreshFlutterAccessibility,
  semanticsByName,
  waitForFlutterRoutePattern,
} from '../support/flutter';

export class VetListPage {
  constructor(private readonly page: Page) {}

  /** Org list cards (`Veterinarian: …`) or guardian compact rows (`Name · town`). */
  private vetRowLocator(name: string): Locator {
    const escaped = escapeRegExp(name);
    const cardPattern = new RegExp(`Veterinarian:\\s*${escaped}`, 'i');
    const rowPattern = new RegExp(escaped, 'i');
    return semanticsByName(this.page, cardPattern)
      .or(this.page.getByRole('button', { name: rowPattern }))
      .or(this.page.getByRole('group', { name: rowPattern }))
      .or(this.page.getByText(rowPattern))
      .first();
  }

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
    await refreshFlutterAccessibility(this.page);
    await this.vetRowLocator(name).waitFor({ timeout: 30_000 });
  }

  async expectVetNotVisible(name: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const escaped = escapeRegExp(name);
    await expect(
      semanticsByName(this.page, new RegExp(`Veterinarian:\\s*${escaped}`, 'i'))
        .or(this.page.getByRole('button', { name: new RegExp(escaped, 'i') }))
        .or(this.page.getByRole('group', { name: new RegExp(escaped, 'i') }))
        .or(this.page.getByText(new RegExp(escaped, 'i'))),
    ).toHaveCount(0);
  }

  async expectVetCount(n: number): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const legacyCards = this.page
      .getByRole('button', { name: /Veterinarian:/i })
      .or(this.page.getByRole('group', { name: /Veterinarian:/i }));
    if ((await legacyCards.count()) > 0) {
      await expect(legacyCards).toHaveCount(n, { timeout: 30_000 });
      return;
    }
    await expect(this.page.getByText(/\b\d+ pets?\b/i)).toHaveCount(n, { timeout: 30_000 });
  }

  async clickEditVet(name: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const card = semanticsByName(
      this.page,
      new RegExp(`Veterinarian:\\s*${escapeRegExp(name)}`, 'i'),
    );
    const inlineEdit = card.getByRole('button', { name: /^Edit$/i });
    if (await inlineEdit.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await inlineEdit.click();
    } else {
      await this.vetRowLocator(name).click();
      await waitForFlutterRoutePattern(this.page, /\/(g|o)\/vets\/[^/]+$/, 30_000);
      await refreshFlutterAccessibility(this.page);
      await this.page.getByRole('button', { name: /^Edit$/i }).click();
    }
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
    // Dialog dismissed — should still be on the edit form
    await this.page.getByRole('button', { name: /Delete Vet/i }).waitFor({ timeout: 15_000 });
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
    const phoneLocator = this.page.getByText(new RegExp(escapeRegExp(phone), 'i'));

    if (vetName) {
      const cardPattern = new RegExp(
        `Veterinarian:\\s*${escapeRegExp(vetName)}[\\s\\S]*${escapeRegExp(phone)}`,
        'i',
      );
      if (await semanticsByName(this.page, cardPattern).isVisible({ timeout: 2_000 }).catch(() => false)) {
        return;
      }
    }

    if (await phoneLocator.first().isVisible({ timeout: 2_000 }).catch(() => false)) {
      return;
    }

    if (!vetName) {
      throw new Error('expectPhoneVisible: vetName required for guardian compact-row list');
    }

    await this.vetRowLocator(vetName).click();
    await waitForFlutterRoutePattern(this.page, /\/(g|o)\/vets\/[^/]+$/, 30_000);
    await refreshFlutterAccessibility(this.page);
    await phoneLocator.first().waitFor({ timeout: 15_000 });
  }
}
