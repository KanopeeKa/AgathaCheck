import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import { escapeRegExp, refreshFlutterAccessibility, semanticsByName } from '../support/flutter';

/**
 * Health dashboard (`/health`).
 * Maps to: flutter_app/test/bdd/features/health_tracking.feature
 */
export class HealthDashboardPage {
  constructor(private readonly page: Page) {}

  /** Empty-state copy — Flutter web often merges tab body text into tabpanel/group names. */
  private emptyStateLocator() {
    return this.page
      .getByText(/No entries yet|Aucun événement/i)
      .or(
        this.page.getByRole('group', {
          name: /No entries yet|Aucun événement/i,
        }),
      )
      .or(
        this.page.getByRole('tabpanel', {
          name: /No entries yet|Aucun événement/i,
        }),
      )
      .or(this.page.getByText(/Tap \+ to add one|Appuyez sur \+ pour en ajouter/i));
  }

  /** Wait until async health entries have settled (empty, rows, or error). */
  private async waitForDashboardSettled(): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await this.emptyStateLocator()
        .or(this.page.getByText(/Mark as done|Marquer comme fait/i))
        .or(this.page.getByRole('button', { name: /retry|try again|réessayer/i }))
        .or(this.page.getByText(/Error loading entries|Error loading pets/i))
        .first()
        .waitFor({ timeout: 3_000 });
    }).toPass({ timeout: 45_000 });
  }

  async expectLoaded(): Promise<void> {
    const { expect } = await import('@playwright/test');
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const marker = this.page
        .getByRole('tab', { name: /^(All|Tous)$/i })
        .or(this.page.getByRole('tab', { name: /^(Medications|Médicaments)$/i }))
        .or(this.page.getByRole('button', { name: /Add Health Event/i }))
        .or(this.page.getByText(/Due and Overdue|À faire et en retard/i))
        .or(this.emptyStateLocator())
        .first();
      await expect(marker).toBeVisible();
    }).toPass({ timeout: 30_000 });
    await this.waitForDashboardSettled();
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
    const eventsNav = this.page.getByRole('button', { name: 'Events' });
    if (await eventsNav.isVisible().catch(() => false)) {
      await eventsNav.click();
    } else {
      await this.page.getByRole('button', { name: 'To Do' }).click();
    }
    await this.expectLoaded();
  }

  async expectEntryVisible(name: string, timeout = 15_000): Promise<void> {
    const pattern = new RegExp(escapeRegExp(name), 'i');
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(semanticsByName(this.page, pattern)).toBeVisible();
    }).toPass({ timeout });
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
    await this.waitForDashboardSettled();
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(this.emptyStateLocator().first()).toBeVisible();
    }).toPass({ timeout: 30_000 });
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
