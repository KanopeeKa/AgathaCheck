import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import { refreshFlutterAccessibility } from '../support/flutter';
import { isLiveHostingTarget } from '../support/hosting';

/**
 * Weight tracking screen (`/pet/:petId/weight`).
 * Maps to: flutter_app/test/bdd/features/weight_tracking.feature
 */
export class WeightTrackingPage {
  constructor(private readonly page: Page) {}

  /** Navigate to the dedicated weight tracking screen from pet profile. */
  async openSection(): Promise<void> {
    const onWeightScreen = await this.page
      .getByRole('radio', { name: 'kg' })
      .isVisible()
      .catch(() => false);
    if (onWeightScreen) {
      await refreshFlutterAccessibility(this.page);
      return;
    }

    const navRow = this.page
      .getByRole('button', { name: /Weight Tracking|Suivi du poids/i })
      .or(this.page.getByText(/Weight Tracking|Suivi du poids/i))
      .first();
    await navRow.scrollIntoViewIfNeeded();
    await navRow.click();
    await this.page.waitForTimeout(600);
    await refreshFlutterAccessibility(this.page);
  }

  /** Wait until the weight tracking screen is visible. */
  async expectLoaded(): Promise<void> {
    await this.page
      .getByRole('radio', { name: 'kg' })
      .or(this.page.getByRole('button', { name: /Weight Tracking|Suivi du poids/i }))
      .first()
      .waitFor({ timeout: 30_000 });
  }

  /** Wait until the async weight list has finished loading (empty, entries, or error). */
  private async waitForWeightDataSettled(): Promise<void> {
    await this.page
      .getByRole('group', {
        name: /no weight data yet|aucune donnée de poids|\d+\.\d+ (kg|lb)/i,
      })
      .or(this.page.getByText(/no weight data yet|aucune donnée de poids|\d+\.\d+ (kg|lb)|error loading weight/i))
      .first()
      .waitFor({ timeout: 15_000 });
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

  /** Click an "Add weight entry" affordance to open the bottom sheet. */
  async openAddWeightSheet(): Promise<void> {
    await this.openSection();
    const addButton = this.page
      .getByRole('button', { name: /Add weight entry|Ajouter une entrée de poids/i })
      .first();
    await addButton.click();
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
    await this.openSection();
    await this.waitForWeightDataSettled();
    const label = `${weight.toFixed(1)} ${unit}`;
    const pattern = new RegExp(label.replace('.', '\\.'), 'i');
    await this.page
      .getByRole('group', { name: pattern })
      .or(this.page.getByText(label, { exact: false }))
      .first()
      .waitFor({ timeout: 15_000 });
  }

  /** Count weight entry rows visible on the weight screen. */
  async expectWeightEntryCount(count: number): Promise<void> {
    await this.openSection();
    await this.waitForWeightDataSettled();
    const entries = this.page.getByRole('group', { name: /^\d+\.\d+ (kg|lb)/ });
    await expect(entries).toHaveCount(count, { timeout: 15_000 });
  }

  /** Expect the kg / lb unit segmented control to be present. */
  async expectUnitSelectorVisible(): Promise<void> {
    await this.openSection();
    await this.page.getByRole('radio', { name: 'kg' }).waitFor({ timeout: 10_000 });
    await this.page.getByRole('radio', { name: 'lb' }).waitFor({ timeout: 10_000 });
  }
}
