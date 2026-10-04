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

  /** Tap the row body (opens the occurrence screen). */
  async openRow(entryId: string, entryName?: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const byId = this.page.locator(
      `[flt-semantics-identifier="care_agenda_row_${entryId}"]`,
    );
    if ((await byId.count()) > 0) {
      await byId.click();
    } else if (entryName) {
      const opensDate = /Opens this date|Ouvre cette date/i;
      await this.page
        .getByRole('button', { name: opensDate })
        .filter({ hasText: new RegExp(escapeRegExp(entryName), 'i') })
        .first()
        .click();
    } else {
      await byId.click();
    }
    await refreshFlutterAccessibility(this.page);
  }

  /** Stack row opens the care item view (DN-1). */
  async openStack(entryId: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await this.page
      .locator(`[flt-semantics-identifier="care_agenda_stack_${entryId}"]`)
      .click();
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
        ).first(),
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
