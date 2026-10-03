import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';

import { escapeRegExp, refreshFlutterAccessibility, semanticsByName } from '../support/flutter';

/**
 * Shared care agenda rows (dashboard, pet profile, All Actions).
 */
export class CareAgendaPage {
  constructor(private readonly page: Page) {}

  doneButton(entryId: string) {
    return this.page.locator(`[flt-semantics-identifier="pet_care_action_done_${entryId}"]`);
  }

  async expectRowVisible(entryName: string): Promise<void> {
    await expect(
      semanticsByName(this.page, new RegExp(escapeRegExp(entryName), 'i')).first(),
    ).toBeVisible({ timeout: 30_000 });
  }

  /** Tap the row body (opens the occurrence screen, or the care item for a stack). */
  async openRow(entryName: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const row = semanticsByName(
      this.page,
      new RegExp(`${escapeRegExp(entryName)}.*Opens (this date|the care item)`, 'i'),
    ).first();
    await expect(row).toBeVisible({ timeout: 30_000 });
    await row.click();
    await refreshFlutterAccessibility(this.page);
  }

  async markDone(entryId: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await this.doneButton(entryId).click();
    await refreshFlutterAccessibility(this.page);
  }

  async expectDoneSnackbar(entryName: string): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(
        this.page.locator('[flt-semantics-identifier="care_done_snackbar"]').or(
          this.page.getByText(new RegExp(`${escapeRegExp(entryName)}.*done`, 'i')),
        ),
      ).toBeVisible();
    }).toPass({ timeout: 45_000 });
  }

  async undoLastDone(): Promise<void> {
    const undo = this.page
      .locator('[flt-semantics-identifier="care_done_undo"]')
      .or(this.page.getByRole('button', { name: /^Undo$|^Annuler$/i }));
    await expect(undo.first()).toBeVisible({ timeout: 45_000 });
    await undo.first().click();
    await refreshFlutterAccessibility(this.page);
  }
}
