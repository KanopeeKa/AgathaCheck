import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';

import {
  enableFlutterAccessibility,
  flutterGotoUrl,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';

/**
 * Occurrence screen — one date of care (§18.6.4).
 */
export class OccurrencePage {
  constructor(private readonly page: Page) {}

  async open(petId: string, entryId: string, occurrenceId: string): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await this.page.goto(
      flutterGotoUrl(
        `/pet/${petId}/events/${entryId}/occurrences/${occurrenceId}`,
      ),
    );
    await waitForFlutterRoutePattern(
      this.page,
      new RegExp(`/occurrences/${occurrenceId}`),
      60_000,
    );
    await refreshFlutterAccessibility(this.page);
    await expect(this.page.getByRole('button', { name: /go back/i })).toBeVisible({
      timeout: 60_000,
    });
  }

  async expectLoaded(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const screen = this.page.locator('[flt-semantics-identifier="occurrence_screen"]');
    const about = this.page.locator('[flt-semantics-identifier="occurrence_about_item"]');
    const back = this.page.getByRole('button', { name: /^Back$|^Go back$|^Retour$/i });
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const onRoute = /\/occurrences\/[^/?#]+/.test(
        new URL(this.page.url()).hash.replace(/^#/, ''),
      );
      if (onRoute) {
        await expect(screen.or(about).or(back)).toBeVisible();
        return;
      }
      await expect(about.or(screen)).toBeVisible();
    }).toPass({ timeout: 60_000 });
  }

  async markDone(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const done = this.page
      .locator('[flt-semantics-identifier="occurrence_done"]')
      .or(this.page.getByRole('button', { name: /^Done$|^Fait$/i }));
    await done.first().click();
    await refreshFlutterAccessibility(this.page);
  }

  async expectWeightRequiredBeforeDone(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(this.page.getByLabel(/Weight/i).first()).toBeVisible({ timeout: 15_000 });
    const done = this.page.getByRole('button', { name: /^Done$|^Fait$/i });
    await expect(done).toBeDisabled();
  }

  async fillWeight(value: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const field = this.page.getByLabel(/Weight/i).first();
    await field.fill(value);
    await refreshFlutterAccessibility(this.page);
  }

  async expectDoneEnabled(): Promise<void> {
    const done = this.page.getByRole('button', { name: /^Done$|^Fait$/i });
    await expect(done).toBeEnabled({ timeout: 10_000 });
  }

  async expectRecordAsDoneVisible(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(
      this.page
        .locator('[flt-semantics-identifier="occurrence_record"]')
        .or(this.page.getByRole('button', { name: /Record as done|Enregistrer comme fait/i })),
    ).toBeVisible({ timeout: 15_000 });
  }

  async openCompletedOnEditor(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await this.page.getByText(/Completed on|Complété le/i).first().click();
    await refreshFlutterAccessibility(this.page);
  }

  async pickCalendarDay(day: number): Promise<void> {
    const dialog = this.page.getByRole('dialog');
    await expect(dialog).toBeVisible({ timeout: 15_000 });
    await dialog.getByText(new RegExp(`^${day},\\s`)).first().click({ force: true });
    await dialog.getByRole('button', { name: /^OK$|^Save$|Enregistrer/i }).first().click();
    await refreshFlutterAccessibility(this.page);
  }
}
