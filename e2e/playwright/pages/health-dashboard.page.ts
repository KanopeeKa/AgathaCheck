import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import { escapeRegExp, refreshFlutterAccessibility, semanticsByName } from '../support/flutter';

/**
 * Health dashboard (`/health`).
 * Maps to: flutter_app/test/bdd/features/health_tracking.feature
 */
export class HealthDashboardPage {
  constructor(private readonly page: Page) {}

  /** Guardian `/g/events` due-events inbox (D17) — distinct from org tabbed dashboard. */
  private guardianDueEventsEmptyLocator() {
    return this.page
      .getByText(/You're all caught up|Tout est à jour/i)
      .or(
        this.page.getByText(
          /No events are overdue or due today|Aucun événement en retard ou prévu aujourd'hui/i,
        ),
      );
  }

  /** Guardian `/g/events` global list (phase 14+) — filter bar + EventListCard rows. */
  private guardianGlobalEventsLoadedLocator() {
    return this.page
      .getByRole('button', { name: /Add an event|Ajouter un événement/i })
      .or(this.page.getByText(/^Events$|^Événements$/i))
      .or(this.page.getByText(/Due and Overdue|À faire et en retard/i))
      .or(this.page.getByText(/No entries yet|Aucun événement/i));
  }

  /** EventListCard semantics include type in the label (`name, Medication, date`). */
  private guardianGlobalEventsEntryLocator() {
    return this.page
      .locator('flt-semantics')
      .filter({
        hasText: /, (Medication|Médicament|Preventive|Préventif|Vet Visit|Visite vétérinaire|Other|Autre), /i,
      });
  }

  /** Empty-state copy — Flutter web often merges tab body text into tabpanel/group names. */
  private fullDashboardEmptyLocator() {
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

  private emptyStateLocator() {
    return this.fullDashboardEmptyLocator().or(this.guardianDueEventsEmptyLocator());
  }

  /** Wait until async health entries have settled (empty, rows, or error). */
  private async waitForDashboardSettled(): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await this.emptyStateLocator()
        .or(this.guardianGlobalEventsLoadedLocator())
        .or(this.guardianGlobalEventsEntryLocator())
        .or(this.page.getByText(/Mark as done|Marquer comme fait/i))
        .or(this.page.getByRole('button', { name: /retry|try again|réessayer/i }))
        .or(this.page.getByText(/Error loading entries|Error loading pets/i))
        .first()
        .waitFor({ timeout: 3_000 });
    }).toPass({ timeout: 45_000 });
  }

  async expectLoaded(): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const marker = this.page
        .getByRole('tab', { name: /^(All|Tous)$/i })
        .or(this.page.getByRole('tab', { name: /^(Medications|Médicaments)$/i }))
        .or(this.page.getByRole('button', { name: /Add Health Event/i }))
        .or(this.page.getByRole('button', { name: /Add an event|Ajouter un événement/i }))
        .or(this.page.getByText(/Due and Overdue|À faire et en retard/i))
        .or(this.emptyStateLocator())
        .or(this.guardianGlobalEventsLoadedLocator())
        .first();
      await expect(marker).toBeVisible();
    }).toPass({ timeout: 30_000 });
    await this.waitForDashboardSettled();
  }

  async openAddEntry(): Promise<void> {
    const fab = this.page
      .getByRole('button', { name: /Add Health Event|Add an event|Ajouter un événement/i })
      .first();
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
    const tab = this.page
      .getByRole('tab', { name: tabName, exact: true })
      .or(this.page.getByText(tabName, { exact: true }))
      .first();
    if (!(await tab.isVisible({ timeout: 3_000 }).catch(() => false))) {
      throw new Error(
        `Health dashboard tab "${tabName}" not found — guardian /g/events uses the due-events inbox without tabs`,
      );
    }
    await tab.click();
    await this.page.waitForTimeout(500);
  }

  /** Guardian `/g/events` global list — status filter chip (manage-events filter bar). */
  async selectDueOverdueFilter(): Promise<void> {
    const chip = this.page
      .getByRole('button', { name: /Due and Overdue|À faire et en retard/i })
      .first();
    if (!(await chip.isVisible({ timeout: 3_000 }).catch(() => false))) {
      throw new Error(
        'Due and Overdue filter chip not found — guardian /g/events may not have loaded manage-events filters',
      );
    }
    await chip.click();
    await refreshFlutterAccessibility(this.page);
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
