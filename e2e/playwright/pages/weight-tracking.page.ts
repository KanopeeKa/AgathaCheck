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

  /**
   * ExpansionTile root for the Weight Tracking card.
   * Scoped locators avoid false matches on the profile header weight chip
   * (latest weight shows the same "{value} kg" pattern before the list loads).
   */
  private weightSectionRoot() {
    return this.page
      .getByRole('group', { name: /Weight Tracking|Suivi du poids/i })
      .first();
  }

  /** Expand the Weight Tracking ExpansionTile if it is not already open. */
  async openSection(): Promise<void> {
    const expandedMarker = this.page.getByRole('radio', { name: 'kg' });
    if (await expandedMarker.isVisible().catch(() => false)) {
      await this.weightSectionRoot().scrollIntoViewIfNeeded();
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

  /**
   * List rows, empty state, or error — scoped to the section.
   * Avoids false positives from the profile header chip or chart axis labels
   * (chart can render before list rows are scrolled into view).
   */
  private weightDataSettledLocator() {
    const section = this.weightSectionRoot();
    return section
      .getByRole('button', {
        name: /Delete weight entry|Supprimer l'entrée de poids/i,
      })
      .or(section.getByText(/no weight data yet|aucune donnée de poids/i))
      .or(
        section.getByText(
          /error loading weight|erreur de chargement des données de poids/i,
        ),
      );
  }

  /**
   * Scroll the pet-detail page so weight list rows below the chart enter the
   * Flutter web accessibility tree (CustomScrollView clips off-screen semantics).
   */
  private async revealWeightListRows(): Promise<void> {
    const section = this.weightSectionRoot();
    await section.scrollIntoViewIfNeeded();
    await section.hover();
    // Chart (~200px) + unit row push list tiles below the viewport on pet detail.
    for (let i = 0; i < 3; i++) {
      await this.page.mouse.wheel(0, 300);
      await this.page.waitForTimeout(200);
    }
    await refreshFlutterAccessibility(this.page);
  }

  /** Wait until the async weight list has finished loading (empty, entries, or error). */
  private async waitForWeightDataSettled(): Promise<void> {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const timeout = isLiveHostingTarget(baseURL) ? 45_000 : 30_000;
    await expect(async () => {
      await this.revealWeightListRows();
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
      const section = this.weightSectionRoot();
      await expect(
        section
          .getByText(/no weight data yet|aucune donnée de poids/i)
          .or(section.getByRole('group', { name: /No weight data yet|Aucune donnée de poids/i }))
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
      const section = this.weightSectionRoot();
      const entry = section
        .getByRole('group', { name: pattern })
        .or(section.getByText(label, { exact: false }))
        .first();
      await entry.scrollIntoViewIfNeeded();
      await expect(entry).toBeVisible();
    }).toPass({ timeout });
  }

  /** Count weight entry rows visible in the expanded section. */
  async expectWeightEntryCount(count: number): Promise<void> {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const timeout = isLiveHostingTarget(baseURL) ? 45_000 : 30_000;
    await expect(async () => {
      await this.openSection();
      await this.waitForWeightDataSettled();
      const section = this.weightSectionRoot();
      const entries = section.getByRole('button', {
        name: /Delete weight entry|Supprimer l'entrée de poids/i,
      });

      if (count === 0) {
        await expect(entries).toHaveCount(0);
        return;
      }

      // Walk each row into view so Flutter web exposes every delete button.
      for (let i = 0; i < count; i++) {
        const row = entries.nth(i);
        await row.scrollIntoViewIfNeeded();
        await refreshFlutterAccessibility(this.page);
        await expect(row).toBeVisible();
      }
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
