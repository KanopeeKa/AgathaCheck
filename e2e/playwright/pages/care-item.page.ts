import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';

import {
  enableFlutterAccessibility,
  flutterGotoUrl,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';
import { formatHealthEntryStatusDate } from '../support/healthEntryDates';

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
    const button = this.page.getByRole('button', {
      name: /^Change date$|^Changer la date$/i,
    });
    await expect(button.first()).toBeVisible({ timeout: 30_000 });
    await button.first().click();
    await expect(
      this.page.getByText(/^Change date$|^Changer la date$/i).first(),
    ).toBeVisible({ timeout: 15_000 });
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
    const dateTrigger = this.page
      .getByRole('button', { name: /\d{2}\/\d{2}\/\d{4}/ })
      .first();
    await expect(dateTrigger).toBeVisible({ timeout: 15_000 });
    await dateTrigger.click();
    const dialog = this.page.getByRole('dialog');
    await expect(dialog).toBeVisible({ timeout: 15_000 });
    await dialog.getByText(new RegExp(`^${day},\\s`)).first().click({ force: true });
    await dialog.getByRole('button', { name: /^OK$|^Save$|Enregistrer/i }).first().click();
    await this.expectReschedulePreviewNextDates();
  }

  async confirmReschedule(): Promise<void> {
    const buttons = this.page.getByRole('button', {
      name: /^Change date$|^Changer la date$/i,
    });
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
}
