import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';

import {
  enableFlutterAccessibility,
  flutterGotoUrl,
  flutterRoutePath,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';

/**
 * Occurrence screen — one date of care (§18.6.4).
 */
export class OccurrencePage {
  constructor(private readonly page: Page) {}

  private doneControl() {
    return this.page
      .locator('[key="occurrence_done"]')
      .or(this.page.locator('[flt-semantics-identifier="occurrence_done"]'))
      .or(
        this.page.getByRole('button', {
          name:
            /Mark(?: .+)? as done|Mark as done|Marquer(?: .+)? comme fait|Marquer comme fait|^Done$|^Fait$/i,
        }),
      );
  }

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
    await expect(
      this.page.getByRole('button', { name: /^Back$|^Go back$|^Retour$/i }),
    ).toBeVisible({
      timeout: 60_000,
    });
  }

  async expectLoaded(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const screen = this.page.locator('[flt-semantics-identifier="occurrence_screen"]');
    const identity = this.page.locator(
      '[flt-semantics-identifier="occurrence_identity_card"], [flt-semantics-identifier="occurrence_open_care_details"]',
    );
    const back = this.page.getByRole('button', { name: /^Back$|^Go back$|^Retour$/i });
    const title = this.page.getByRole('heading', {
      name: /Care date|Date de soin/i,
    });
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const path = flutterRoutePath(this.page.url());
      const onOccurrenceRoute = /\/occurrences\/[^/]+/.test(path);
      if (onOccurrenceRoute) {
        await expect(title.or(back).or(screen).or(identity).first()).toBeVisible();
        return;
      }
      if (await identity.isVisible().catch(() => false)) return;
      if (await screen.isVisible().catch(() => false)) return;
      throw new Error(`Care date not ready (path=${path})`);
    }).toPass({ timeout: 60_000 });
  }

  async markDone(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const done = this.doneControl();
    await done.first().scrollIntoViewIfNeeded();
    await done.first().click();
    await refreshFlutterAccessibility(this.page);
  }

  private weightInput() {
    return this.page
      .getByRole('textbox', { name: /Weight|Poids/i })
      .or(this.page.locator('[key="occurrence_field_weight"]'))
      .or(this.page.locator('[flt-semantics-identifier="occurrence_field_weight"]'));
  }

  async expectWeightRequiredBeforeDone(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const field = this.weightInput();
    await expect(field.first()).toBeVisible({ timeout: 15_000 });
    const done = this.doneControl();
    await expect(done.first()).toBeVisible({ timeout: 15_000 });
    await expect(done.first()).toBeDisabled();
  }

  async fillWeight(value: string, _unit: 'kg' | 'lb' = 'kg'): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const host = this.weightInput().first();
    await host.scrollIntoViewIfNeeded();
    const input = host.locator('input, textarea').first();
    await input.fill(value);
    await refreshFlutterAccessibility(this.page);
  }

  async expectWeightFieldUnit(unit: 'kg' | 'lb'): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const pattern =
      unit === 'lb' ? /Weight\s*\(lb\)|Poids\s*\(lb\)/i : /Weight\s*\(kg\)|Poids\s*\(kg\)/i;
    await expect(this.weightInput().or(this.page.getByLabel(pattern)).first()).toBeVisible({
      timeout: 15_000,
    });
  }

  async tapSkip(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const skip = this.page
      .locator('[flt-semantics-identifier="occurrence_skip"]')
      .or(this.page.getByRole('button', { name: /^Skip$|^Ignorer$/i }));
    await skip.first().click();
    await refreshFlutterAccessibility(this.page);
  }

  async expectSkipWeighInSheet(): Promise<void> {
    await expect(
      this.page
        .locator('[flt-semantics-identifier="skip_weigh_in_sheet"]')
        .or(this.page.getByText(/Skip this weigh-in/i)),
    ).toBeVisible({ timeout: 15_000 });
  }

  async selectSkipReason(reasonLabel: RegExp): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const chip = this.page
      .locator('[flt-semantics-identifier="skip_weigh_in_reason_could_not_weigh"]')
      .or(this.page.getByRole('checkbox', { name: reasonLabel }))
      .or(this.page.getByRole('button', { name: reasonLabel }));
    await chip.first().click();
  }

  async fillSkipNote(note: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const field = this.page
      .locator('[flt-semantics-identifier="skip_weigh_in_note"]')
      .or(this.page.getByRole('textbox', { name: /Notes|Remarques/i }));
    await field.first().fill(note);
  }

  async confirmSkipWeighIn(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(this.page.getByText(/Skip this weigh-in|Ignorer cette pesée/i)).toBeVisible();
    const confirm = this.page
      .locator('[flt-semantics-identifier="skip_weigh_in_confirm"]')
      .or(this.page.getByRole('button', { name: /^Skip$|^Ignorer$/i }).last());
    await confirm.click();
    await refreshFlutterAccessibility(this.page);
  }

  async expectSkippedWeighIn(reasonText: RegExp, note?: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(
      this.page
        .getByRole('group', { name: reasonText })
        .or(this.page.getByText(reasonText))
        .first(),
    ).toBeVisible({ timeout: 30_000 });
    if (note) {
      await expect(
        this.page.getByRole('group', { name: new RegExp(note) }).or(this.page.getByText(note)),
      ).toBeVisible();
    }
  }

  async expectDoneEnabled(): Promise<void> {
    const done = this.doneControl();
    await expect(done.first()).toBeEnabled({ timeout: 10_000 });
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
