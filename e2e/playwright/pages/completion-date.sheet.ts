import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';

import { refreshFlutterAccessibility } from '../support/flutter';

/** "When was this done?" sheet for After-it's-done overdue care (DN-3). */
export class CompletionDateSheetPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
    await expect(this.page.getByText(/When was this done\?|Quand cela a été fait/i)).toBeVisible({
      timeout: 15_000,
    });
  }

  async chooseToday(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await this.page.getByRole('button', { name: /^Today$|^Aujourd'hui$/i }).click();
    await refreshFlutterAccessibility(this.page);
  }
}
