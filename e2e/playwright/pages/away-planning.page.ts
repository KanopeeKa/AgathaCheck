import type { Locator, Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
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

  async expectPetCarerRow(
    petId: string,
    petName: string,
    carerLabel: string,
  ): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(
        semanticsKey(this.page, `away_plan_carer_pet_header_${petId}`).or(
          this.page.getByText(petName, { exact: false }).first(),
        ),
      ).toBeVisible();
      await expect(semanticsKey(this.page, `away_plan_carer_label_${petId}`)).toBeVisible();
      await expect(semanticsKey(this.page, `away_plan_carer_label_${petId}`)).toContainText(
        carerLabel,
      );
    }).toPass({ timeout: 30_000 });
  }

  async expectUpcomingAbsenceVisible(petName: string): Promise<void> {
    await expect(this.page.getByText(petName)).toBeVisible({ timeout: 30_000 });
  }

  async openPlan(absenceId: string): Promise<void> {
    await this.page.goto(flutterGotoUrl(`/pc/away/${absenceId}`));
    await refreshFlutterAccessibility(this.page);
    await this.expectPlanPageLoaded();
  }

  async expectCarerCoverageHeaderVisible(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(
      this.page.getByText(/Carer coverage|Couverture des soignants/i).first(),
    ).toBeVisible({ timeout: 30_000 });
  }

  async expectCarerCoverageHeaderHidden(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(
      this.page.getByText(/Carer coverage|Couverture des soignants/i),
    ).toHaveCount(0, { timeout: 15_000 });
  }

  async expectCareCoverageHeaderVisible(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(
      this.page.getByText(/Care coverage|Couverture des soins/i).first(),
    ).toBeVisible({ timeout: 30_000 });
  }

  async expectCareCoverageHeaderHidden(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(
      this.page.getByText(/Care coverage|Couverture des soins/i),
    ).toHaveCount(0, { timeout: 15_000 });
  }

  async expectCoverageHeadersHidden(): Promise<void> {
    await this.expectCarerCoverageHeaderHidden();
    await this.expectCareCoverageHeaderHidden();
  }

  async expectPlannedCareSection(): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const heading = semanticsKey(this.page, 'away_plan_planned_care_heading').or(
        this.page.getByText(/Planned care|Soins planifiés/i).first(),
      );
      await expect(heading).toBeVisible();
    }).toPass({ timeout: 45_000 });
  }

  async expectPlannedCareEntryVisible(entryName: string): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(this.page.getByText(entryName, { exact: false }).first()).toBeVisible();
    }).toPass({ timeout: 45_000 });
  }

  plannedCareRow(entryId: string, entryName?: string) {
    if (entryName && !entryId) {
      return this.page.getByRole('button', { name: new RegExp(entryName, 'i') }).first();
    }
    const bySemantics = semanticsKey(this.page, `away_plan_planned_care_${entryId}`);
    if (entryName) {
      return bySemantics.or(
        this.page.getByRole('button', { name: new RegExp(entryName, 'i') }).first(),
      );
    }
    return bySemantics;
  }

  async expectPlannedCareItemRow(entryId: string, entryName?: string): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(this.plannedCareRow(entryId, entryName)).toBeVisible();
    }).toPass({ timeout: 45_000 });
  }

  async expectPlannedCareRowShowsOverdue(
    entryId: string,
    entryName: string,
    overdueLabel: RegExp,
  ): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(this.plannedCareRow(entryId, entryName)).toBeVisible();
      await expect(this.page.getByText(overdueLabel).first()).toBeVisible();
    }).toPass({ timeout: 45_000 });
  }

  async expectPlannedCareRowShowsEstimated(entryId: string, entryName: string): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const row = this.plannedCareRow(entryId, entryName);
      await expect(row).toBeVisible();
      await expect(row).toContainText(/Estimated:|Estimé:/i);
    }).toPass({ timeout: 45_000 });
  }

  async expectPlannerSectionVisible(petId: string): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(semanticsKey(this.page, `away_plan_planner_heading_${petId}`)).toBeVisible();
    }).toPass({ timeout: 45_000 });
  }

  async expectCarerTaskSummaryHidden(): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(
        this.page.getByText(/care tasks? for your carer|tâches? de soin pour votre soignant/i),
      ).toHaveCount(0);
    }).toPass({ timeout: 45_000 });
  }

  async expectPlannerSuggestionVisible(petId: string, entryName: string): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(semanticsKey(this.page, `away_plan_planner_heading_${petId}`)).toBeVisible();
      await expect(this.plannedCareRow('', entryName)).toBeVisible();
      await expect(this.page.getByText(/Move from|Déplacer de/i).first()).toBeVisible();
      await expect(
        this.page.getByRole('button', { name: /^Accept$|^Accepter$/i }).first(),
      ).toBeVisible();
    }).toPass({ timeout: 45_000 });
  }

  async acceptPlannerSuggestion(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await this.page.getByRole('button', { name: /^Accept$|^Accepter$/i }).first().click();
    await refreshFlutterAccessibility(this.page);
  }

  async openPlanThis(entryId: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const row = this.plannedCareRow(entryId);
    await expect(row).toBeVisible({ timeout: 30_000 });
    const planThis = semanticsKey(this.page, `away_plan_plan_this_${entryId}`).or(
      row.getByRole('button', { name: /^Plan this$|^Planifier$/i }),
    );
    await expect(planThis.first()).toBeVisible({ timeout: 15_000 });
    await planThis.first().click();
    await refreshFlutterAccessibility(this.page);
  }

  async openPlannedCareItem(entryId: string): Promise<void> {
    const row = semanticsKey(this.page, `away_plan_planned_care_${entryId}`);
    await expect(row).toBeVisible({ timeout: 30_000 });
    await row.click();
    await refreshFlutterAccessibility(this.page);
  }

  async expectPlannedCareItemDetail(entryName: string): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      // Flutter web push from away plan may not update the hash route; assert detail UI.
      await expect(this.page.getByRole('button', { name: /go back/i })).toBeVisible();
      await expect(this.page.getByText(entryName, { exact: false }).first()).toBeVisible();
      await expect(this.page.getByRole('button', { name: /close event/i })).toBeVisible();
    }).toPass({ timeout: 45_000 });
  }

  async openEditScreen(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await this.page
      .getByRole('button', { name: /Edit away plan|Modifier le plan d'absence/i })
      .first()
      .click();
    await refreshFlutterAccessibility(this.page);
    // Flutter web push may not sync hash; assert edit screen chrome instead.
    await this.expectEditScreenLoaded();
  }

  async expectEditScreenLoaded(): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(this.page.getByRole('textbox', { name: /^Notes$/i })).toBeVisible();
      await expect(
        this.page.getByRole('button', { name: /Delete plan|Supprimer le plan/i }).first(),
      ).toBeVisible();
    }).toPass({ timeout: 60_000 });
  }

  async fillHandoverNote(note: string): Promise<void> {
    const field = this.page.getByRole('textbox', { name: /^Notes$/i });
    await expect(field).toBeVisible({ timeout: 30_000 });
    await field.click();
    await field.fill(note);
  }

  async saveEdit(): Promise<void> {
    await this.page
      .getByRole('button', { name: /Save absence|Enregistrer l'absence/i })
      .first()
      .click();
    await refreshFlutterAccessibility(this.page);
    await this.expectPlanPageLoaded();
  }

  async expectHandoverNoteOnPlan(note: string): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const bySemantics = semanticsKey(this.page, 'away_plan_handover_note_text');
      // Both sides of `.or()` can independently match (semantics node + text
      // span), so the combined locator can resolve to 2 elements; `.first()`
      // must wrap the whole `.or()`, not just one side, to keep strict mode happy.
      const combined = bySemantics.or(this.page.getByText(note, { exact: false })).first();
      await expect(combined).toBeVisible();
    }).toPass({ timeout: 45_000 });
  }

  async deleteAwayPlan(): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await this.page
        .getByRole('button', { name: /Delete plan|Supprimer le plan/i })
        .first()
        .click();
      // AppFormDestructiveButton's confirm prompt renders as alertdialog, not
      // dialog (see organization-detail.page.ts for the same pattern).
      const dialog = this.page.getByRole('alertdialog');
      await expect(dialog).toBeVisible({ timeout: 15_000 });
      await expect(
        dialog.getByText(/Delete this away plan|Supprimer ce plan d'absence/i),
      ).toBeVisible();
      await dialog
        .getByRole('button', { name: /^Delete$|^Supprimer$/i })
        .first()
        .click();
      await refreshFlutterAccessibility(this.page);
      // Post-delete navigation may pop without updating hash; assert hub chrome.
      await this.expectHubLoaded();
    }).toPass({ timeout: 90_000 });
  }

  async expectAbsenceNotListed(petName: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(this.page.getByText(petName)).toHaveCount(0, { timeout: 30_000 });
  }
}
