import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';

import { refreshFlutterAccessibility } from '../support/flutter';
import { CareItemPage } from './care-item.page';

/**
 * Weight observation block on a weigh-in routine care item (WEIGHT C / W10).
 */
export class WeightCarePage {
  private readonly careItem: CareItemPage;

  constructor(private readonly page: Page) {
    this.careItem = new CareItemPage(page);
  }

  async open(petId: string, entryId: string): Promise<void> {
    await this.careItem.open(petId, entryId);
  }

  async expectWeightSectionVisible(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(
      this.page.locator('[flt-semantics-identifier="weight_care_item_section"]'),
    ).toBeVisible({ timeout: 30_000 });
    await expect(
      this.page.getByRole('button', { name: /See all weights|Voir tous les poids/i }),
    ).toBeVisible();
    await expect(
      this.page.getByRole('banner', { name: /^Weight|^Poids/i }),
    ).toBeVisible();
  }
}
