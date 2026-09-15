import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  flutterGotoUrl,
  refreshFlutterAccessibility,
  semanticsByName,
  waitForFlutterRoutePattern,
} from '../support/flutter';

function formatDdMmYyyy(isoDate: string): string {
  const [year, month, day] = isoDate.split('-');
  return `${day}/${month}/${year}`;
}

function semanticsKey(page: Page, key: string) {
  return page.locator(`[flt-semantics-identifier="${key}"]`);
}

/**
 * Away Planning hub, wizard, and plan page vocabulary.
 */
export class AwayPlanningPage {
  constructor(private readonly page: Page) {}

  async openHub(): Promise<void> {
    await this.page.goto(flutterGotoUrl('/pc/away'));
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/pc\/away(?:\?|$)/, 60_000);
  }

  async expectHubLoaded(): Promise<void> {
    await expect(
      semanticsByName(this.page, /Away planning|Planification d'absence/i).first(),
    ).toBeVisible({ timeout: 60_000 });
  }

  async expectEmptyHub(): Promise<void> {
    await expect(semanticsKey(this.page, 'planned_absence_hub_empty_action')).toBeVisible({
      timeout: 30_000,
    });
  }

  async openWizardFromHub(): Promise<void> {
    const emptyAction = semanticsKey(this.page, 'planned_absence_hub_empty_action');
    if (await emptyAction.isVisible().catch(() => false)) {
      await emptyAction.click();
    } else {
      await semanticsKey(this.page, 'planned_absence_hub_add').click();
    }
    await waitForFlutterRoutePattern(this.page, /\/pc\/away\/new/, 30_000);
  }

  async openWizard(): Promise<void> {
    await this.page.goto(flutterGotoUrl('/pc/away/new'));
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/pc\/away\/new/, 60_000);
  }

  async pickAbsenceDates(startsOn: string, endsOn: string): Promise<void> {
    await semanticsKey(this.page, 'planned_absence_date_range').click();
    const dialog = this.page.getByRole('dialog');
    await expect(dialog).toBeVisible({ timeout: 15_000 });
    const inputs = dialog.locator('input');
    await inputs.nth(0).fill(formatDdMmYyyy(startsOn));
    await inputs.nth(1).fill(formatDdMmYyyy(endsOn));
    await dialog.getByRole('button', { name: /OK|Save|Enregistrer/i }).click();
    await expect(dialog).not.toBeVisible({ timeout: 15_000 });
  }

  async continueWizard(): Promise<void> {
    await semanticsKey(this.page, 'planned_absence_continue').click();
  }

  async selectPet(petId: string): Promise<void> {
    await semanticsKey(this.page, `planned_absence_pet_${petId}`).click();
  }

  async saveAbsence(): Promise<void> {
    await semanticsKey(this.page, 'planned_absence_save').click();
    await waitForFlutterRoutePattern(this.page, /\/pc\/away\/[^/]+/, 60_000);
  }

  async expectPlanPageLoaded(): Promise<void> {
    await expect(semanticsKey(this.page, 'away_plan_page')).toBeVisible({ timeout: 60_000 });
  }

  async expectWhoIsCaringSection(): Promise<void> {
    await expect(
      semanticsByName(this.page, /Who's caring|Qui s'en occupe/i).first(),
    ).toBeVisible({ timeout: 30_000 });
  }

  async expectPetCarerRow(petName: string, carerLabel: string): Promise<void> {
    await expect(this.page.getByText(petName, { exact: true })).toBeVisible();
    await expect(this.page.getByText(carerLabel)).toBeVisible();
  }

  async expectUpcomingAbsenceVisible(petName: string): Promise<void> {
    await expect(semanticsKey(this.page, 'planned_absence_hub_list')).toBeVisible({
      timeout: 30_000,
    });
    await expect(this.page.getByText(petName)).toBeVisible();
  }
}
