import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import { fillTextbox, refreshFlutterAccessibility } from '../support/flutter';
import { WeightTrackingPage } from './weight-tracking.page';

/**
 * Weight hub screen and Record weight sheet (WEIGHT B).
 * Maps to hub scenarios in weight_tracking.feature.
 */
export class WeightHubPage {
  private readonly tracking: WeightTrackingPage;

  constructor(private readonly page: Page) {
    this.tracking = new WeightTrackingPage(page);
  }

  async openHub(): Promise<void> {
    await this.tracking.openSection();
    await this.tracking.expectLoaded();
  }

  async openRecordWeightSheet(): Promise<void> {
    await this.openHub();
    const addButton = this.page
      .getByRole('button', {
        name: /Add weight entry|Record weight|Ajouter une entrée de poids|Enregistrer le poids/i,
      })
      .first();
    await addButton.click();
    await this.page
      .locator('input[aria-label*="Weight"]')
      .or(this.page.getByRole('textbox', { name: /Weight|Poids/i }))
      .first()
      .waitFor({ timeout: 15_000 });
  }

  async fillWeight(value: string | number): Promise<void> {
    await fillTextbox(this.page, /Weight|Poids/i, String(value));
  }

  countsAsSwitch() {
    return this.page
      .locator('[flt-semantics-identifier="record_weight_counts_as"]')
      .getByRole('switch')
      .or(this.page.getByRole('switch', { name: /Counts as|Compte comme/i }));
  }

  async waitForCountsAsReady(): Promise<void> {
    const checking = this.page.getByText(/Checking for a due weigh-in|pesée prévue/i);
    if (await checking.isVisible().catch(() => false)) {
      await checking.waitFor({ state: 'hidden', timeout: 15_000 });
    }
    await this.page.waitForTimeout(400);
  }

  async setCountsAsSwitch(on: boolean): Promise<void> {
    const switchEl = this.countsAsSwitch();
    await switchEl.waitFor({ timeout: 15_000 });
    const checked = await switchEl.isChecked();
    if (checked !== on) {
      await switchEl.click();
    }
  }

  async chooseWeighInRoutine(routineName: string | RegExp): Promise<void> {
    const pattern =
      routineName instanceof RegExp ? routineName : new RegExp(routineName, 'i');
    await this.page
      .getByRole('button', { name: pattern })
      .or(this.page.getByRole('radio', { name: pattern }))
      .first()
      .click();
  }

  async chooseDontCountAsWeighIn(): Promise<void> {
    await this.page
      .getByRole('button', { name: /Don't count it as a weigh-in|Ne pas compter/i })
      .or(
        this.page.getByRole('radio', {
          name: /Don't count it as a weigh-in|Ne pas compter/i,
        }),
      )
      .first()
      .click();
  }

  async saveSheet(): Promise<void> {
    const save = this.page.getByRole('button', { name: /^Save$|^Enregistrer$/i });
    await expect(save).toBeEnabled({ timeout: 15_000 });
    await save.click();
    await this.page
      .getByRole('button', { name: /^Save$|^Enregistrer$/i })
      .waitFor({ state: 'hidden', timeout: 15_000 })
      .catch(() => undefined);
    await this.page.waitForTimeout(400);
    await refreshFlutterAccessibility(this.page);
  }

  async tapUndoOnSnackBar(): Promise<void> {
    const undo = this.page
      .locator('[flt-semantics-identifier="weight_fulfil_undo"]')
      .or(this.page.getByRole('button', { name: /^Undo$|^Annuler$/i }));
    await undo.first().click();
    await this.page.waitForTimeout(800);
    await refreshFlutterAccessibility(this.page);
  }

  async expectSnackBarWithUndo(): Promise<void> {
    const snackbar = this.page
      .locator('[flt-semantics-identifier="weight_fulfil_snackbar"]')
      .or(this.page.getByText(/Saved · counted as|Enregistré · compte comme/i));
    await expect(snackbar.first()).toBeVisible({ timeout: 45_000 });
    const undo = this.page
      .locator('[flt-semantics-identifier="weight_fulfil_undo"]')
      .or(this.page.getByRole('button', { name: /^Undo$|^Annuler$/i }));
    await expect(undo.first()).toBeVisible({ timeout: 10_000 });
  }

  async openHistoryEntry(weight: number, unit = 'kg'): Promise<void> {
    await this.openHub();
    const weightPattern = new RegExp(
      `${weight.toFixed(1).replace('.', '\\.')}\\s*${unit}`,
      'i',
    );
    const row = this.page
      .getByRole('button', { name: weightPattern })
      .filter({
        has: this.page.getByRole('button', {
          name: /Delete weight entry|Supprimer l'entrée de poids/i,
        }),
      })
      .first();
    await row.scrollIntoViewIfNeeded();
    await row.click();
    await this.page
      .getByRole('textbox', { name: /Weight|Poids/i })
      .first()
      .waitFor({ timeout: 15_000 });
  }

  async clickDeleteOnEntryRow(weight: number, unit = 'kg'): Promise<void> {
    await this.openHub();
    const weightPattern = new RegExp(
      `${weight.toFixed(1).replace('.', '\\.')}\\s*${unit}`,
      'i',
    );
    const row = this.page
      .getByRole('button', { name: weightPattern })
      .filter({
        has: this.page.getByRole('button', {
          name: /Delete weight entry|Supprimer l'entrée de poids/i,
        }),
      })
      .first();
    await row.scrollIntoViewIfNeeded();
    await row.getByRole('button', {
      name: /Delete weight entry|Supprimer l'entrée de poids/i,
    }).click();
  }

  async expectLinkedDeleteConfirmation(routineName: string | RegExp): Promise<void> {
    const pattern =
      routineName instanceof RegExp ? routineName : new RegExp(routineName, 'i');
    await this.page
      .getByRole('alertdialog')
      .or(this.page.getByRole('dialog'))
      .first()
      .waitFor({ timeout: 10_000 });
    await expect(
      this.page.getByText(/counted as|comptait comme/i).filter({ hasText: pattern }),
    ).toBeVisible();
  }

  async confirmDeleteInDialog(): Promise<void> {
    await this.page.getByRole('button', { name: /^Delete$|^Supprimer$/i }).click();
    await this.page.waitForTimeout(800);
    await refreshFlutterAccessibility(this.page);
  }

  async selectDisplayUnit(unit: 'kg' | 'lb'): Promise<void> {
    await this.openHub();
    const name = unit === 'kg' ? /^kg$/i : /^lb$/i;
    await this.page.getByRole('button', { name }).click();
    await this.page.waitForTimeout(400);
    await refreshFlutterAccessibility(this.page);
  }

  async expectWeightDisplayed(weight: number, unit: 'kg' | 'lb'): Promise<void> {
    await this.tracking.expectWeightEntryVisible(weight, unit);
  }

  async expectSetUpWeighInRoutinePrompt(): Promise<void> {
    await this.openHub();
    const routineGroup = this.page.getByRole('group', {
      name: /No weigh-in routine|Aucune routine de pesée/i,
    });
    const setup = this.page.getByRole('button', {
      name: /Set up a weigh-in routine|Configurer une routine de pesée/i,
    });
    await expect(routineGroup.or(setup).first()).toBeVisible({ timeout: 45_000 });
    await expect(setup.first()).toBeVisible();
  }

  async expectReadOnlyWeightOnPetEdit(): Promise<void> {
    await this.page
      .getByText(/Weight \d|recorded|Poids .* enregistré|No weight recorded|Poids non enregistré/i)
      .first()
      .waitFor({ timeout: 15_000 });
    await expect(this.page.getByRole('textbox', { name: /Weight today|Poids du jour/i })).toHaveCount(
      0,
    );
    await this.page
      .getByRole('button', { name: /Record weight|Enregistrer le poids/i })
      .waitFor();
  }

  async followRecordWeightLinkOnEditForm(): Promise<void> {
    await this.page
      .getByRole('button', { name: /Record weight|Enregistrer le poids/i })
      .click();
    await this.tracking.expectLoaded();
  }
}
