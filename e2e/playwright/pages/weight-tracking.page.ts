import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import { refreshFlutterAccessibility } from '../support/flutter';
import { isLiveHostingTarget } from '../support/hosting';

/**
 * Weight Tracking section on the Pet Detail screen.
 * The section is an ExpansionTile labelled "Weight Tracking".
 * Maps to: flutter_app/test/bdd/features/weight_tracking.feature
 */
export class WeightTrackingPage {
  constructor(private readonly page: Page) {}

  /** Expand the Weight Tracking ExpansionTile if it is not already open. */
  async openSection(): Promise<void> {
    const expandedMarker = this.page.getByRole('radio', { name: 'kg' });
    if (await expandedMarker.isVisible().catch(() => false)) {
      await refreshFlutterAccessibility(this.page);
      return;
    }

    const tile = this.page
      .getByRole('button', { name: /Weight Tracking|Suivi du poids/i })
      .or(this.page.getByRole('group', { name: /Weight Tracking|Suivi du poids/i }))
      .first();
    await tile.scrollIntoViewIfNeeded();
    await tile.click();
    await this.page.waitForTimeout(600);
    await refreshFlutterAccessibility(this.page);
  }

  /** Wait until the Weight Tracking section header is visible on the page. */
  async expectLoaded(): Promise<void> {
    await this.page
      .getByRole('button', { name: /Weight Tracking|Suivi du poids/i })
      .or(this.page.getByRole('group', { name: /Weight Tracking|Suivi du poids/i }))
      .first()
      .waitFor({ timeout: 30_000 });
  }

  /** Empty, entry rows, or error — Flutter web merges ListTile copy into group names. */
  private weightDataSettledLocator() {
    return this.page
      .getByRole('group', {
        name: /no weight data yet|aucune donnée de poids|\d+\.\d+ (kg|lb)/i,
      })
      .or(
        this.page.getByText(
          /no weight data yet|aucune donnée de poids|\d+\.\d+ (kg|lb)|error loading weight/i,
        ),
      );
  }

  /** Wait until the async weight list has finished loading (empty, entries, or error). */
  private async waitForWeightDataSettled(): Promise<void> {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const timeout = isLiveHostingTarget(baseURL) ? 45_000 : 30_000;
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await this.weightDataSettledLocator().first().waitFor({ timeout: 3_000 });
    }).toPass({ timeout });
  }

  /** Expect the empty-state prompt shown when there are no weight entries. */
  async expectEmptyState(): Promise<void> {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const timeout = isLiveHostingTarget(baseURL) ? 45_000 : 20_000;
    await expect(async () => {
      await this.openSection();
      await this.waitForWeightDataSettled();
      await expect(
        this.page
          .getByText(/no weight data yet|aucune donnée de poids/i)
          .or(this.page.getByRole('group', { name: /No weight data yet|Aucune donnée de poids/i }))
          .first(),
      ).toBeVisible();
    }).toPass({ timeout });
  }

  /** Click the "Add weight entry" button to open the bottom sheet. */
  async openAddWeightSheet(): Promise<void> {
    await this.openSection();
    await this.page.getByRole('button', { name: /Add weight entry/i }).click();
    // Wait for the bottom-sheet weight input field
    await this.page
      .locator('input[aria-label*="Weight"]')
      .or(this.page.getByRole('textbox', { name: /Weight/i }))
      .first()
      .waitFor({ timeout: 15_000 });
  }

  /**
   * Fill the Add Weight Entry bottom-sheet form.
   * The date picker is a button / InkWell; skipping date selection uses today by default.
   */
  async fillWeightForm(weight: string | number): Promise<void> {
    const weightInput = this.page
      .locator('input[aria-label*="Weight"]')
      .or(this.page.getByRole('textbox', { name: /Weight/i }))
      .first();
    await weightInput.click();
    await weightInput.fill(String(weight));
  }

  /** Click the Save button in the Add Weight Entry bottom-sheet. */
  async saveWeightEntry(): Promise<void> {
    await this.page
      .getByRole('button', { name: /^Save$/i })
      .click();
    await this.page.waitForTimeout(800);
    await refreshFlutterAccessibility(this.page);
  }

  /**
   * Expect a weight entry showing the given weight value (with optional unit).
   * The entry is rendered as a ListTile with text "25.5 kg".
   */
  async expectWeightEntryVisible(weight: number, unit = 'kg'): Promise<void> {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const timeout = isLiveHostingTarget(baseURL) ? 45_000 : 30_000;
    const label = `${weight.toFixed(1)} ${unit}`;
    const pattern = new RegExp(label.replace('.', '\\.'), 'i');
    await expect(async () => {
      await this.openSection();
      await this.waitForWeightDataSettled();
      await expect(
        this.page
          .getByRole('group', { name: pattern })
          .or(this.page.getByText(label, { exact: false }))
          .first(),
      ).toBeVisible();
    }).toPass({ timeout });
  }

  /** Count weight entry rows visible in the expanded section. */
  async expectWeightEntryCount(count: number): Promise<void> {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const timeout = isLiveHostingTarget(baseURL) ? 45_000 : 30_000;
    await expect(async () => {
      await this.openSection();
      await this.waitForWeightDataSettled();
      const entries = this.page.getByRole('group', { name: /^\d+\.\d+ (kg|lb)/ });
      await expect(entries).toHaveCount(count);
    }).toPass({ timeout });
  }

  /** Expect the kg / lb unit segmented control to be present. */
  async expectUnitSelectorVisible(): Promise<void> {
    await this.openSection();
    // Flutter SegmentedButton exposes segments as radio controls, not buttons.
    await this.page.getByRole('radio', { name: 'kg' }).waitFor({ timeout: 10_000 });
    await this.page.getByRole('radio', { name: 'lb' }).waitFor({ timeout: 10_000 });
  }
}
