import type { Page } from '@playwright/test';
import { escapeRegExp, refreshFlutterAccessibility, semanticsByName } from '../support/flutter';

/**
 * Health dashboard (`/health`).
 * Maps to: flutter_app/test/bdd/features/health_tracking.feature
 */
export class HealthDashboardPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
    await this.page
      .getByRole('button', { name: 'Add Health Event' })
      .or(this.page.getByText('All', { exact: true }))
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async openAddEntry(): Promise<void> {
    const fab = this.page.getByRole('button', { name: 'Add Health Event' });
    const box = await fab.boundingBox();
    if (!box) {
      throw new Error('Add Health Event button not found');
    }
    await this.page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    await this.page.locator('input[aria-label*="Entry Name"]').first().waitFor({ timeout: 30_000 });
  }

  async returnToDashboard(): Promise<void> {
    await this.page.getByRole('button', { name: 'Go back' }).click();
    await this.page.getByRole('button', { name: 'To Do' }).click();
    await this.expectLoaded();
  }

  async expectEntryVisible(name: string): Promise<void> {
    await semanticsByName(this.page, new RegExp(escapeRegExp(name), 'i')).waitFor({
      timeout: 15_000,
    });
  }

  async openEntryForEdit(name: string): Promise<void> {
    const card = this.page
      .locator('flt-semantics')
      .filter({ hasText: name })
      .filter({ hasText: 'Mark as done' });
    const count = await card.count();
    await card.nth(Math.max(0, count - 1)).click();
    await this.page.locator('input[aria-label*="Entry Name"]').first().waitFor({ timeout: 15_000 });
  }

  async markEntryAsDone(name: string): Promise<void> {
    await this.openEntryForEdit(name);
  }

  async expectEntryMarkedComplete(name: string): Promise<void> {
    await semanticsByName(this.page, new RegExp(escapeRegExp(name), 'i')).waitFor({
      timeout: 15_000,
    });
    await this.page.getByRole('button', { name: /Undo/i }).first().waitFor({ timeout: 30_000 });
  }

  async expectEmptyState(): Promise<void> {
    await this.page
      .getByRole('tabpanel', { name: /No entries yet/i })
      .or(this.page.getByText(/No entries yet/i))
      .first()
      .waitFor({ timeout: 15_000 });
  }

  async selectTab(tabName: string): Promise<void> {
    await this.page
      .getByRole('tab', { name: tabName, exact: true })
      .or(this.page.getByText(tabName, { exact: true }))
      .first()
      .click();
    await this.page.waitForTimeout(500);
  }

  async expectEntryNotVisible(name: string): Promise<void> {
    const matches = this.page.getByText(name, { exact: false });
    const count = await matches.count();
    for (let i = 0; i < count; i++) {
      if (await matches.nth(i).isVisible()) {
        throw new Error(`Expected entry "${name}" to not be visible but found a visible instance`);
      }
    }
  }

  async selectOrgFilter(orgName: string): Promise<void> {
    await this.page
      .getByRole('button', { name: orgName, exact: true })
      .or(this.page.getByRole('checkbox', { name: orgName, exact: true }))
      .or(this.page.getByText(orgName, { exact: true }))
      .first()
      .click();
    await refreshFlutterAccessibility(this.page);
    await this.page.waitForTimeout(500);
  }
}
