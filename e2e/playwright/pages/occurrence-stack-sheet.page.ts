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

  async expectDueTodayDoseCount(count: number): Promise<void> {
    await this.expectDueTodayZone();
    const dueToday = this.page.getByText(/^Due today$/i);
    const zone = this.page.locator('flt-semantics').filter({ has: dueToday });
    await expect(zone.getByText(/\bat\b/i)).toHaveCount(count);
  }

  async recordLatestDose(): Promise<void> {
    await this.page.getByRole('button', { name: /Record latest dose/i }).click();
    await this.page.getByRole('button', { name: /Mark Completed/i }).click();
    await refreshFlutterAccessibility(this.page);
  }

  async dismiss(): Promise<void> {
    await this.page.getByRole('button', { name: /Not now/i }).click();
  }
}
