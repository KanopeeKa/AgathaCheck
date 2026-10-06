import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';

import {
  escapeRegExp,
  flutterRoutePath,
  refreshFlutterAccessibility,
  semanticsByName,
} from '../support/flutter';

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
    if (entryName) {
      await this.expectRowVisible(entryName);
    }
    const opensDate = /Opens this date|Ouvre cette date/i;
    const byId = this.page.locator(
      `[flt-semantics-identifier="care_agenda_row_${entryId}"]`,
    );
    const byRole =
      entryName != null
        ? this.page
            .getByRole('button', { name: opensDate })
            .filter({ hasText: new RegExp(escapeRegExp(entryName), 'i') })
        : null;

    const tapRow = async (): Promise<void> => {
      const target =
        byRole != null && (await byRole.count()) > 0 ? byRole.first() : byId;
      await expect(target).toBeVisible({ timeout: 30_000 });
      const box = await target.boundingBox();
      if (box == null) {
        await target.click({ position: { x: 12, y: 16 } });
        return;
      }
      // Pointer hit on the leading icon column — avoids the trailing Mark done control.
      await this.page.mouse.click(box.x + 20, box.y + box.height / 2);
    };

    const careDateHeading = this.page.getByRole('heading', {
      name: /Care date|Date de soin/i,
    });
    await expect(async () => {
      await tapRow();
      await refreshFlutterAccessibility(this.page);
      const path = flutterRoutePath(this.page.url());
      const onOccurrenceRoute = /\/occurrences\/[^/]+/.test(path);
      const onScreen = await careDateHeading.isVisible().catch(() => false);
      if (!onOccurrenceRoute && !onScreen && entryName) {
        await semanticsByName(
          this.page,
          new RegExp(`${escapeRegExp(entryName)}.*Opens this date|Ouvre cette date`, 'i'),
        )
          .first()
          .click({ position: { x: 12, y: 16 } });
        await refreshFlutterAccessibility(this.page);
      }
      const ready =
        /\/occurrences\/[^/]+/.test(flutterRoutePath(this.page.url())) ||
        (await careDateHeading.isVisible().catch(() => false));
      if (!ready) {
        throw new Error(`Occurrence screen not open (path=${flutterRoutePath(this.page.url())})`);
      }
    }).toPass({ timeout: 60_000 });
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

  async showUpcomingCare(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const hide = this.page.getByRole('button', {
      name: /Hide upcoming care|Masquer les soins à venir/i,
    });
    if (await hide.isVisible({ timeout: 2_000 }).catch(() => false)) {
      return;
    }
    const show = this.page.getByRole('button', {
      name: /Show upcoming care|Afficher les soins à venir|Upcoming \(\d+\)|À venir \(\d+\)/i,
    });
    if (await show.isVisible({ timeout: 5_000 }).catch(() => false)) {
      await show.click();
      await refreshFlutterAccessibility(this.page);
    }
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
