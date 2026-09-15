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

  async openFromDashboardTile(): Promise<void> {
    await this.page
      .getByRole('button', {
        name: /I'll be away.*Preview care|Je serai absent.*Aperçu des soins/i,
      })
      .first()
      .click();
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/pc\/away(?:\?|$)/, 60_000);
  }

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
    await expect(
      this.page.getByText(/Preview care scheduled while you're away|Aperçu des soins/i),
    ).toBeVisible({ timeout: 30_000 });
  }

  async openWizard(): Promise<void> {
    await this.page.goto(flutterGotoUrl('/pc/away/new'));
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/pc\/away\/new/, 60_000);
  }

  async pickAbsenceDates(startsOn: string, endsOn: string): Promise<void> {
    const dateButton = semanticsKey(this.page, 'planned_absence_date_range');
    if (await dateButton.isVisible().catch(() => false)) {
      await dateButton.click();
    } else {
      await this.page.getByRole('button', { name: /Absence dates|Dates d'absence/i }).first().click();
    }
    const dialog = this.page.getByRole('dialog');
    await expect(dialog).toBeVisible({ timeout: 15_000 });
    const inputs = dialog.locator('input');
    await inputs.nth(0).fill(formatDdMmYyyy(startsOn));
    await inputs.nth(1).fill(formatDdMmYyyy(endsOn));
    await dialog.getByRole('button', { name: /OK|Save|Enregistrer/i }).first().click();
    await expect(dialog).not.toBeVisible({ timeout: 15_000 });
  }

  async continueWizard(): Promise<void> {
    const continueButton = semanticsKey(this.page, 'planned_absence_continue');
    if (await continueButton.isVisible().catch(() => false)) {
      await continueButton.click();
      return;
    }
    await this.page.getByRole('button', { name: /^Continue$|^Continuer$/i }).first().click();
  }

  async selectPet(petId: string): Promise<void> {
    const petRow = semanticsKey(this.page, `planned_absence_pet_${petId}`);
    if (await petRow.isVisible().catch(() => false)) {
      await petRow.click();
      return;
    }
    await this.page.getByRole('checkbox').first().click();
  }

  async saveAbsence(): Promise<void> {
    const saveButton = semanticsKey(this.page, 'planned_absence_save');
    if (await saveButton.isVisible().catch(() => false)) {
      await saveButton.click();
    } else {
      await this.page.getByRole('button', { name: /Save absence|Enregistrer l'absence/i }).first().click();
    }
    await waitForFlutterRoutePattern(this.page, /\/pc\/away\/[^/]+/, 60_000);
  }

  async expectPlanPageLoaded(): Promise<void> {
    await expect(
      semanticsByName(this.page, /Away plan|Plan d'absence/i).first(),
    ).toBeVisible({ timeout: 60_000 });
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
    await expect(this.page.getByText(petName)).toBeVisible({ timeout: 30_000 });
  }
}
