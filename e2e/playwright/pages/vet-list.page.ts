/**
 * Veterinarian list screen (`/g/vets`, `/o/vets`).
 * Maps to: flutter_app/test/bdd/features/veterinarian_management.feature
 */
import type { Locator, Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  escapeRegExp,
  flutterGotoUrl,
  flutterRoutePath,
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

  private editVetButtonLocator(scope: Page | Locator = this.page) {
    return scope
      .getByRole('button', { name: /^Edit Vet$/i })
      .or(scope.getByRole('button', { name: /^Edit$/i }));
  }

  async clickEditVet(name: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const card = semanticsByName(
      this.page,
      new RegExp(`Veterinarian:\\s*${escapeRegExp(name)}`, 'i'),
    );
    const inlineEdit = this.editVetButtonLocator(card);
    if (await inlineEdit.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await inlineEdit.click();
    } else {
      await this.vetRowLocator(name).click();
      await waitForFlutterRoutePattern(this.page, /\/(g|o)\/vets\/[^/]+$/, 30_000);
      await refreshFlutterAccessibility(this.page);
      await this.editVetButtonLocator().click();
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

  async expectVetLinkedPetCount(vetName: string, count: number): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const countLabel = count === 1 ? '1 pet' : `${count} pets`;
    const row = this.vetRowLocator(vetName);
    await expect(row.getByText(new RegExp(countLabel, 'i'))).toBeVisible({ timeout: 15_000 });
  }

  async openVetDetail(vetName: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await this.vetRowLocator(vetName).click();
    await waitForFlutterRoutePattern(this.page, /\/(g|o)\/vets\/[^/]+$/, 30_000);
    await refreshFlutterAccessibility(this.page);
  }

  async expectLinkedPetNames(...names: string[]): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    for (const name of names) {
      await this.page
        .getByRole('button', { name: new RegExp(name, 'i') })
        .or(this.page.getByText(name, { exact: true }))
        .first()
        .waitFor({ timeout: 15_000 });
    }
  }

  async expectPhoneVisible(phone: string, vetName?: string): Promise<void> {
    if (!vetName) {
      throw new Error('expectPhoneVisible: vetName required for guardian compact-row list');
    }

    const phonePattern = new RegExp(escapeRegExp(phone), 'i');
    // Guardian detail merges fields into one group label; org list cards use Veterinarian: … Phone: …
    const phoneLocator = this.page.getByText(phonePattern).or(semanticsByName(this.page, phonePattern));
    const orgCardPattern = new RegExp(
      `Veterinarian:\\s*${escapeRegExp(vetName)}[\\s\\S]*${escapeRegExp(phone)}`,
      'i',
    );
    const detailGroupPattern = new RegExp(
      `${escapeRegExp(vetName)}[\\s\\S]*Phone[\\s\\S]*${escapeRegExp(phone)}`,
      'i',
    );

    // Guardian compact rows omit phone on the list; open detail (or match merged semantics) to assert phone.
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      if (await semanticsByName(this.page, orgCardPattern).isVisible().catch(() => false)) {
        return;
      }
      if (await semanticsByName(this.page, detailGroupPattern).isVisible().catch(() => false)) {
        return;
      }

      const route = flutterRoutePath(this.page.url());
      const onDetail = /\/(g|o)\/vets\/[^/]+$/.test(route);
      const onList = /\/(g|o)\/vets(?:\?|$)/.test(route);
      const phoneVisible = await phoneLocator.first().isVisible().catch(() => false);

      if (!onDetail || !phoneVisible) {
        if (!onList) {
          await this.page.goto(flutterGotoUrl('/g/vets'));
          await waitForFlutterRoutePattern(this.page, /\/g\/vets(?:\?|$)/, 30_000);
        }
        await this.expectLoaded();
        await this.expectVetVisible(vetName);
        await this.openVetDetail(vetName);
        await waitForFlutterRoutePattern(this.page, /\/(g|o)\/vets\/[^/]+$/, 30_000);
        await refreshFlutterAccessibility(this.page);
      }

      await expect(phoneLocator.first()).toBeVisible({ timeout: 15_000 });
    }).toPass({ timeout: 45_000 });
  }
}
