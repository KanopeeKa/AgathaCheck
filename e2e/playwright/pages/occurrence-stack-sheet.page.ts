import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import { escapeRegExp, refreshFlutterAccessibility } from '../support/flutter';

/**
 * Occurrence stack sheet bottom sheet for multi-dose care triage.
 * Maps to: health_tracking.feature — multi-dose stack sheet scenario.
 */
export class OccurrenceStackSheetPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(entryName: string): Promise<void> {
    const pattern = new RegExp(
      `Record doses for ${escapeRegExp(entryName)}`,
      'i',
    );
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(this.page.getByText(pattern)).toBeVisible();
    }).toPass({ timeout: 15_000 });
  }

  async expectDueTodayZone(): Promise<void> {
    await expect(this.page.getByText(/^Due today$/i)).toBeVisible();
  }

  async expectDueTodayDoseCount(count: number, todayIso: string): Promise<void> {
    await this.expectDueTodayZone();
    // The sheet's semantics parent contains all zones, including stored tomorrow
    // slots. Match the displayed calendar date instead of counting every "at" row.
    // Dart DateFormat('dd MMM yy') in the app's English locale renders
    // September as "Sep". Node's en-GB Intl short month is "Sept", so
    // format the month with en-US while preserving Dart's day-month-year order.
    const [year, , day] = todayIso.split('-');
    const monthLabel = new Intl.DateTimeFormat('en-US', {
      month: 'short',
      timeZone: 'UTC',
    }).format(new Date(`${todayIso}T12:00:00Z`));
    const todayLabel = `${day} ${monthLabel} ${year.slice(-2)}`;
    await expect(this.page.getByText(new RegExp(`^${escapeRegExp(todayLabel)}\\s+at\\s+`, 'i'))).toHaveCount(count);
  }

  async recordLatestDose(): Promise<void> {
    await this.page.getByRole('button', { name: /Record latest dose/i }).click();
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(
        this.page.getByRole('button', { name: /Record latest dose/i }),
      ).toHaveCount(0);
    }).toPass({ timeout: 30_000 });
  }

  async dismiss(): Promise<void> {
    await this.page.getByRole('button', { name: /Not now/i }).click();
  }
}
