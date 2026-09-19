import type { Locator, Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  escapeRegExp,
  flutterGotoUrl,
  refreshFlutterAccessibility,
  semanticsByName,
  waitForFlutterRoutePattern,
} from '../support/flutter';

function isoDateParts(isoDate: string): { year: string; month: string; day: string } {
  const [year, month, day] = isoDate.split('-');
  return { year, month, day };
}

function formatDdMmYyyy(isoDate: string): string {
  const { year, month, day } = isoDateParts(isoDate);
  return `${day}/${month}/${year}`;
}

function calendarDayPattern(isoDate: string): RegExp {
  const { day } = isoDateParts(isoDate);
  return new RegExp(`^${Number(day)},\\s`);
}

function semanticsKey(page: Page, key: string) {
  return page.locator(`[flt-semantics-identifier="${key}"]`);
}

async function fillDateField(field: Locator, isoDate: string): Promise<void> {
  await field.click();
  await field.press('Control+a');
  await field.fill('');
  await field.pressSequentially(formatDdMmYyyy(isoDate), { delay: 30 });
  await field.press('Tab');
}

/**
 * Away Planning hub, wizard, and plan page vocabulary.
 */
export class AwayPlanningPage {
  constructor(private readonly page: Page) {}

  async openFromDashboardTile(): Promise<void> {
    const tile = semanticsKey(this.page, 'planned_absence_entry_tile');
    await expect(tile).toBeVisible({ timeout: 60_000 });
    await tile.click();
    await refreshFlutterAccessibility(this.page);
    // Shell push may not sync the hash on Flutter web; assert hub chrome instead.
    await this.expectHubLoaded();
  }

  async openHub(): Promise<void> {
    await this.page.goto(flutterGotoUrl('/pc/away'));
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/pc\/away(?:\?|$)/, 60_000);
  }

  async expectHubLoaded(): Promise<void> {
    await expect(
      this.page.getByText(/Away planning|Planification d'absence/i).first(),
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
    const switchToInput = dialog.getByRole('button', {
      name: /Switch to input|Passer en saisie/i,
    });
    const startField = dialog.getByRole('textbox', {
      name: /Start date|Date de début/i,
    });
    if (await switchToInput.isVisible().catch(() => false)) {
      // Calendar grid clicks are unreliable on Flutter web (semantics intercept pointers).
      await switchToInput.click();
      await refreshFlutterAccessibility(this.page);
    }
    if (await startField.isVisible().catch(() => false)) {
      const endField = dialog.getByRole('textbox', { name: /End date|Date de fin/i });
      await fillDateField(startField, startsOn);
      await fillDateField(endField, endsOn);
      await expect(dialog.getByText(/Invalid range|Plage invalide/i)).toHaveCount(0, {
        timeout: 5_000,
      });
    } else {
      const startDay = dialog.getByText(calendarDayPattern(startsOn)).first();
      await startDay.click({ force: true });
      await dialog.getByText(calendarDayPattern(endsOn)).first().click({ force: true });
    }
    await dialog.getByRole('button', { name: /^OK$|^Save$|Enregistrer/i }).first().click();
    await expect(dialog).not.toBeVisible({ timeout: 15_000 });
  }

  async continueWizard(): Promise<void> {
    const continueButton = semanticsKey(this.page, 'planned_absence_continue');
    if (await continueButton.isVisible().catch(() => false)) {
      await continueButton.click();
    } else {
      await this.page
        .getByRole('button', { name: /^Continue$|^Continuer$/i })
        .first()
        .click();
    }
    await this.page.waitForTimeout(750);
    await refreshFlutterAccessibility(this.page);
  }

  async selectPet(petId: string, petName?: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const checkbox = petName
      ? this.page.getByRole('checkbox', {
          name: new RegExp(`^${petName}\\b`, 'i'),
        })
      : semanticsKey(this.page, `planned_absence_pet_${petId}`).or(
          this.page.getByRole('checkbox').first(),
        );
    await expect(checkbox).toBeVisible({ timeout: 30_000 });
    if (!(await checkbox.isChecked().catch(() => false))) {
      await checkbox.click();
    }
    await expect(checkbox).toBeChecked({ timeout: 10_000 });
  }

  async saveAbsence(): Promise<void> {
    const saveButton = semanticsKey(this.page, 'planned_absence_save');
    if (await saveButton.isVisible().catch(() => false)) {
      await saveButton.click();
    } else {
      await this.page
        .getByRole('button', { name: /Save absence|Enregistrer l'absence/i })
        .first()
        .click();
    }
    await this.expectPlanPageLoaded();
  }

  async expectPlanPageLoaded(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(
      this.page.getByText(/Away plan|Plan d'absence/i).first(),
    ).toBeVisible({ timeout: 60_000 });
  }

  async expectWhoIsCaringSection(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(
      semanticsByName(this.page, /Who.s caring|Qui s.en occupe/i).first(),
    ).toBeVisible({ timeout: 30_000 });
  }

  async expectPetCarerRow(petName: string, carerLabel: string): Promise<void> {
    const rowPattern = new RegExp(
      `${escapeRegExp(petName)}.*${escapeRegExp(carerLabel)}`,
      'i',
    );
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(semanticsByName(this.page, rowPattern).first()).toBeVisible();
    }).toPass({ timeout: 30_000 });
  }

  async expectUpcomingAbsenceVisible(petName: string): Promise<void> {
    await expect(this.page.getByText(petName)).toBeVisible({ timeout: 30_000 });
  }
}
