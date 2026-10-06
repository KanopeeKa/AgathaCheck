import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';

import {
  enableFlutterAccessibility,
  flutterGotoUrl,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';
import { formatHealthEntryStatusDate } from '../support/healthEntryDates';

function semanticsKey(page: Page, key: string) {
  return page.locator(`[flt-semantics-identifier="${key}"]`);
}

/**
 * Care item (pet event) detail — occurrence actions and reschedule sheet.
 */
export class CareItemPage {
  constructor(private readonly page: Page) {}

  async open(petId: string, entryId: string): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await this.page.goto(flutterGotoUrl(`/pet/${petId}/events/${entryId}`));
    await waitForFlutterRoutePattern(
      this.page,
      new RegExp(`/pet/${petId}/events/${entryId}`),
      60_000,
    );
    await refreshFlutterAccessibility(this.page);
    await expect(this.page.getByRole('button', { name: /go back/i })).toBeVisible({
      timeout: 60_000,
    });
    await this.expectCareDetailsScreenTitle();
  }

  /** App bar / shell title — not the care item name (care-item-context-header-spec D-CIH-001). */
  async expectCareDetailsScreenTitle(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(
      this.page
        .getByRole('heading', { name: /^Care details$|^Détail du soin$/i })
        .first(),
    ).toBeVisible({ timeout: 30_000 });
  }

  async expectContextStripCareName(careName: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(
      this.page.locator('[key="care_item_context_strip_title"]').or(
        this.page.getByText(careName, { exact: true }),
      ).first(),
    ).toBeVisible({ timeout: 30_000 });
  }

  async expectPetContextTile(petName: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const tile = semanticsKey(this.page, 'care_item_pet_tile');
    await expect(tile).toBeVisible({ timeout: 30_000 });
    await expect(tile).toHaveAttribute('aria-label', petName);
  }

  async expectContextStripStatusChip(label: RegExp): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(
      this.page.locator('[key="care_item_context_strip_chip"]').or(
        this.page.getByText(label),
      ).first(),
    ).toBeVisible({ timeout: 30_000 });
  }

  async goBack(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await this.page
      .locator('[flt-semantics-identifier="experience_back_button"]')
      .or(this.page.getByRole('button', { name: /go back|Back|Retour/i }))
      .first()
      .click();
  }

  async openRescheduleSheet(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const row = this.page
      .locator('[flt-semantics-identifier^="care_item_occurrence_row_"]')
      .first();
    await expect(row).toBeVisible({ timeout: 30_000 });
    await row.click();
    await refreshFlutterAccessibility(this.page);
    const changeDate = this.page
      .locator('[flt-semantics-identifier="occurrence_change_date"]')
      .or(
        this.page.getByRole('button', {
          name: /^Change date$|^Changer la date$/i,
        }),
      );
    await expect(changeDate.first()).toBeVisible({ timeout: 30_000 });
    await changeDate.first().click();
  }

  async expectOpenOccurrenceRowVisible(occurrenceId: string): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const row = this.page
        .locator(`[flt-semantics-identifier="care_item_occurrence_row_${occurrenceId}"]`)
        .or(
          this.page.locator(
            `[flt-semantics-identifier="care_item_upcoming_row_${occurrenceId}"]`,
          ),
        );
      await expect(row).toBeVisible();
    }).toPass({ timeout: 45_000 });
  }

  async expectReschedulePreviewNextDates(): Promise<void> {
    await expect(
      this.page
        .getByText(/Next ones:|Next one estimated|Prochaines dates|Prochaine estimation/i)
        .first(),
    ).toBeVisible({ timeout: 15_000 });
  }

  async pickRescheduleDateInSheet(dayOffsetFromToday: number): Promise<void> {
    const target = new Date();
    target.setUTCDate(target.getUTCDate() + dayOffsetFromToday);
    const day = target.getUTCDate();
    await refreshFlutterAccessibility(this.page);
    const dialog = this.page.getByRole('dialog');
    const dateTrigger = this.page
      .getByRole('button', { name: /\d{2}\/\d{2}\/\d{4}/ })
      .first();
    const sheetDatePicker = await dateTrigger.isVisible().catch(() => false);
    if (!sheetDatePicker) {
      await expect(dialog).toBeVisible({ timeout: 15_000 });
      await dialog.getByText(new RegExp(`^${day},\\s`)).first().click({ force: true });
      await dialog.getByRole('button', { name: /^OK$|^Save$|Enregistrer/i }).first().click();
      await refreshFlutterAccessibility(this.page);
      return;
    }
    await dateTrigger.click();
    await expect(dialog).toBeVisible({ timeout: 15_000 });
    await dialog.getByText(new RegExp(`^${day},\\s`)).first().click({ force: true });
    await dialog.getByRole('button', { name: /^OK$|^Save$|Enregistrer/i }).first().click();
    await this.expectReschedulePreviewNextDates();
  }

  async confirmReschedule(): Promise<void> {
    const buttons = this.page.getByRole('button', {
      name: /^Change date$|^Changer la date$/i,
    });
    if ((await buttons.count()) <= 1) {
      await refreshFlutterAccessibility(this.page);
      return;
    }
    await buttons.last().click();
    await refreshFlutterAccessibility(this.page);
  }

  async expectOpenOccurrenceDateVisible(isoDate: string): Promise<void> {
    const statusDate = formatHealthEntryStatusDate(isoDate);
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const dateLocator = this.page
        .getByRole('group', { name: statusDate })
        .or(this.page.getByText(statusDate, { exact: false }))
        .first();
      await expect(dateLocator).toBeVisible();
    }).toPass({ timeout: 30_000 });
  }

  async expectAbsenceSectionVisible(): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const strip = semanticsKey(this.page, 'care_item_absence_section').or(
        this.page.getByRole('banner', { name: /Absence/i }),
      );
      await expect(strip.first()).toBeVisible();
      await expect(this.page.getByRole('button', { name: /^Review date$|^Revoir la date$/i }).first()).toBeVisible();
    }).toPass({ timeout: 45_000 });
  }

  async expectAbsenceKeepWithCarer(carerName: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const keep = semanticsKey(this.page, 'care_item_absence_keep_date').or(
      this.page.getByRole('button', {
        name: new RegExp(`Keep with ${carerName}`, 'i'),
      }),
    );
    await expect(keep.first()).toBeVisible({ timeout: 15_000 });
  }

  async expectAbsenceReviewDateAction(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const review = semanticsKey(this.page, 'care_item_absence_review_date').or(
      this.page.getByRole('button', { name: /^Review date$|^Revoir la date$/i }),
    );
    await expect(review.first()).toBeVisible({ timeout: 15_000 });
  }

  async openAbsenceOccurrenceReview(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const review = semanticsKey(this.page, 'care_item_absence_review_date').or(
      this.page.getByRole('button', { name: /^Review date$|^Revoir la date$/i }),
    );
    await expect(review.first()).toBeVisible({ timeout: 15_000 });
    await review.first().click();
    await this.expectOccurrenceReviewSheet();
  }

  async tapAbsenceKeepWithCarer(carerName?: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const keep = semanticsKey(this.page, 'care_item_absence_keep_date').or(
      carerName
        ? this.page.getByRole('button', {
            name: new RegExp(`Keep with ${carerName}`, 'i'),
          })
        : this.page.getByRole('button', { name: /^Keep with /i }),
    );
    await expect(keep.first()).toBeVisible({ timeout: 15_000 });
    await keep.first().click();
    await refreshFlutterAccessibility(this.page);
  }

  async openChangeDateFromOccurrenceReview(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const changeDate = semanticsKey(this.page, 'occurrence_review_change_date').or(
      this.page.getByRole('button', { name: /^Change date$|^Changer la date$/i }),
    );
    await expect(changeDate.first()).toBeVisible({ timeout: 15_000 });
    await changeDate.first().click();
    await expect(
      this.page.getByText(/^Change date$|^Changer la date$/i).first(),
    ).toBeVisible({ timeout: 15_000 });
  }

  async rescheduleFromAbsenceReviewToDayOffset(dayOffsetFromToday: number): Promise<void> {
    await this.openAbsenceOccurrenceReview();
    await this.openChangeDateFromOccurrenceReview();
    await this.pickRescheduleDateInSheet(dayOffsetFromToday);
    await this.confirmReschedule();
  }

  async expectOccurrenceReviewSheet(): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const skip = semanticsKey(this.page, 'occurrence_review_skip').or(
        this.page.getByRole('button', { name: /^Skip$|^Ignorer$/i }),
      );
      const changeDate = semanticsKey(this.page, 'occurrence_review_change_date').or(
        this.page.getByRole('button', { name: /^Change date$|^Changer la date$/i }),
      );
      await expect(skip.first()).toBeVisible();
      await expect(changeDate.first()).toBeVisible();
    }).toPass({ timeout: 60_000 });
  }

  async skipFromOccurrenceReviewSheet(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const skip = semanticsKey(this.page, 'occurrence_review_skip').or(
      this.page.getByRole('button', { name: /^Skip$|^Ignorer$/i }),
    );
    await skip.first().click();
    await refreshFlutterAccessibility(this.page);
  }

  async openItemMenu(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const menu = this.page
      .locator('[flt-semantics-identifier="care_item_menu"]')
      .or(
        this.page.getByRole('button', {
          name: /^Care item actions$|^Actions sur le soin$/i,
        }),
      );
    await expect(menu.first()).toBeVisible({ timeout: 30_000 });
    await menu.first().click();
  }

  async pauseFromItemMenu(options: { noEndDate?: boolean; untilIso?: string } = {}): Promise<void> {
    await this.openItemMenu();
    await this.page
      .getByRole('menuitem', { name: /^Pause$|^Mettre en pause$/i })
      .click();
    await expect(
      this.page.locator('[flt-semantics-identifier="postpone_sheet"]'),
    ).toBeVisible({ timeout: 15_000 });
    const noEnd = options.noEndDate ?? true;
    if (!noEnd && options.untilIso) {
      const switchTile = this.page.locator('[flt-semantics-identifier="postpone_no_end_date"]');
      const isOn = await switchTile.getByRole('switch').isChecked().catch(() => true);
      if (isOn) {
        await switchTile.click();
      }
      await this.page.locator('[flt-semantics-identifier="postpone_until_picker"]').click();
      const [, , day] = options.untilIso.split('-').map((v) => parseInt(v, 10));
      const dialog = this.page.getByRole('dialog');
      await expect(dialog).toBeVisible({ timeout: 15_000 });
      await dialog.getByText(new RegExp(`^${day},\\s`)).first().click({ force: true });
      await dialog.getByRole('button', { name: /^OK$|^Save$|Enregistrer/i }).first().click();
    }
    await this.page
      .locator('[flt-semantics-identifier="postpone_confirm"]')
      .or(this.page.getByRole('button', { name: /^Pause$|^Mettre en pause$/i }).last())
      .click();
    await refreshFlutterAccessibility(this.page);
  }

  async expectPausedBanner(): Promise<void> {
    await expect(
      this.page.locator('[flt-semantics-identifier="care_item_paused_banner"]').or(
        this.page.getByText(/Paused since|Paused until|En pause/i),
      ).first(),
    ).toBeVisible({ timeout: 30_000 });
  }

  async resumeFromItemMenu(expectedIso?: string): Promise<void> {
    await this.openItemMenu();
    await this.page
      .getByRole('menuitem', { name: /^Resume$|^Reprendre$/i })
      .click();
    await expect(
      this.page.locator('[flt-semantics-identifier="resume_date_sheet"]'),
    ).toBeVisible({ timeout: 15_000 });
    if (expectedIso) {
      await expect(
        this.page
          .locator('[flt-semantics-identifier="resume_date_picker"]')
          .or(this.page.getByRole('button', { name: /New date|Nouvelle date/i }).locator('..')),
      ).toContainText(expectedIso);
    }
    const resumeResponse = this.page.waitForResponse(
      (res) => res.url().includes('/health-entries/') && res.url().endsWith('/resume') && res.request().method() === 'POST',
      { timeout: 30_000 },
    );
    await this.page
      .locator('[flt-semantics-identifier="resume_confirm"]')
      .or(this.page.getByRole('button', { name: /^Resume$|^Reprendre$/i }).last())
      .click();
    const res = await resumeResponse;
    if (!res.ok()) {
      throw new Error(`resume failed (${res.status()}): ${await res.text()}`);
    }
    await refreshFlutterAccessibility(this.page);
  }

  async expectNeedsAttentionVisible(): Promise<void> {
    await expect(
      this.page.locator(
        '[flt-semantics-identifier="care_item_needs_attention_section"]',
      ),
    ).toBeVisible({ timeout: 30_000 });
  }

  async expectBulkStackDoneSnackbar(count: number): Promise<void> {
    const en =
      count === 1
        ? /1 marked done/i
        : new RegExp(`${count} marked done`, 'i');
    const fr =
      count === 1
        ? /1 marqué comme fait/i
        : new RegExp(`${count} marqués comme faits`, 'i');
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(
        this.page
          .locator('[flt-semantics-identifier="care_stack_snackbar"]')
          .or(this.page.getByText(en))
          .or(this.page.getByText(fr))
          .first(),
      ).toBeVisible();
    }).toPass({ timeout: 45_000 });
  }

  async markLeadingDone(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await this.page
      .locator('[flt-semantics-identifier^="care_item_mark_done_"]')
      .or(
        this.page.getByRole('button', {
          name: /Mark .* as done|Marquer .* comme fait/i,
        }),
      )
      .first()
      .click();
    await refreshFlutterAccessibility(this.page);
  }

  /** @deprecated Use {@link OccurrencePage.planAnotherDateFromMenu} on the occurrence screen (§18.6.4). */
  async planAnotherDateFromMenu(
    isoDate: string,
    occurrencePage: import('./occurrence.page').OccurrencePage,
  ): Promise<void> {
    await occurrencePage.planAnotherDateFromMenu(isoDate);
  }

  async markAllDone(count?: number): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const label =
      count === undefined
        ? /Mark \d+ as done|Marquer \d+ comme fait/i
        : new RegExp(
            `Mark ${count} as done|Marquer ${count} comme fait`,
            'i',
          );
    await this.page
      .locator('[flt-semantics-identifier="care_item_bulk_mark_done"]')
      .or(this.page.getByRole('button', { name: label }))
      .first()
      .click();
    await refreshFlutterAccessibility(this.page);
  }

  async skipAll(count?: number): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const label =
      count === undefined
        ? /Skip \d+|Ignorer \d+/i
        : new RegExp(`Skip ${count}|Ignorer ${count}`, 'i');
    await this.page
      .locator('[flt-semantics-identifier="care_item_bulk_skip"]')
      .or(this.page.getByRole('button', { name: label }))
      .first()
      .click();
    await refreshFlutterAccessibility(this.page);
  }

  /** @deprecated use markAllDone(count) */
  async markAllDoneLegacy(): Promise<void> {
    await this.markAllDone(2);
  }

  async expandPastOccurrences(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await this.page
      .getByRole('button', { name: /Past dates|Dates passées/i })
      .or(this.page.getByText(/^Past dates$|^Dates passées$/i))
      .first()
      .click();
    await refreshFlutterAccessibility(this.page);
  }

  async openPastOccurrence(occurrenceId: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await this.page.locator(`[flt-semantics-identifier="pet_event_past_occurrence_${occurrenceId}"]`).or(
      this.page.locator(`[key="pet_event_past_occurrence_${occurrenceId}"]`),
    ).first().click();
    await refreshFlutterAccessibility(this.page);
  }

  async expectCareProviderVisible(providerName: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(this.page.getByText(providerName, { exact: false }).first()).toBeVisible({
      timeout: 30_000,
    });
  }

  async expectAbsenceReviewActionsHidden(): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(semanticsKey(this.page, 'care_item_absence_review_date')).toHaveCount(0);
      await expect(semanticsKey(this.page, 'care_item_absence_keep_date')).toHaveCount(0);
    }).toPass({ timeout: 45_000 });
  }
}
