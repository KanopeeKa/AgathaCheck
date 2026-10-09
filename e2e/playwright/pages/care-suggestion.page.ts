import { Page } from '@playwright/test';

import { CareAgendaPage } from './care-agenda.page';
import {
  enableFlutterAccessibility,
  flutterGotoUrl,
  refreshFlutterAccessibility,
  semanticsByName,
  waitForFlutterRoutePattern,
} from '../support/flutter';

const suggestionGroupRe =
  /Agatha recommends|Agatha recommande|Suggested by Agatha|Suggestion d'Agatha|Suggéré par Agatha/i;
const addRoutineRe = /^(Add routine|Add rhythm)$|^(Ajouter la routine|Ajouter le rythme)$/i;
const noThanksRe = /^No thanks$|^Pas merci$/i;
const laterRe = /^Later$|^Plus tard$/i;
const whyRe = /^Why this matters$|^Pourquoi c'est utile$/i;
const saveFormRe =
  /^(Add Health Event|Add health event|Ajouter.*événement)$/i;

export class CareSuggestionPage {
  constructor(private readonly page: Page) {}

  private suggestionCardRoot() {
    const addButton = this.page.getByRole('button', { name: addRoutineRe });
    const byIdentifier = this.page.locator(
      '[flt-semantics-identifier="care_suggestion_group"]',
    );
    return byIdentifier.filter({ has: addButton }).or(
      this.page.getByRole('group', { name: suggestionGroupRe }).filter({ has: addButton }),
    ).first();
  }

  /** Display titles (l10n + legacy catalog names still on wire). */
  private static readonly displayTitleRe =
    /Monthly weight check|Weight check|Annual dental check-in|Annual wellness checkup|Contrôle mensuel du poids|Bilan dentaire annuel|Bilan bien-être annuel/i;

  async openPetDetail(petId: string): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await this.page.goto(flutterGotoUrl(`/pet/${petId}`));
    await waitForFlutterRoutePattern(this.page, /\/pet\/[^/?]+/, 30_000);
    await refreshFlutterAccessibility(this.page);
  }

  async openEvents(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await this.page.goto(flutterGotoUrl('/pc/events'));
    await waitForFlutterRoutePattern(this.page, /\/pc\/events/, 30_000);
    await refreshFlutterAccessibility(this.page);
  }

  async expectSuggestionCardVisible(timeout = 30_000): Promise<void> {
    const { expect } = await import('@playwright/test');
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const card = this.suggestionCardRoot();
      await card.scrollIntoViewIfNeeded();
      await expect(card).toBeVisible();
      await expect(card.getByRole('button', { name: addRoutineRe })).toBeVisible();
    }).toPass({ timeout });
  }

  async readVisibleSuggestionRhythmPattern(): Promise<RegExp> {
    const { expect } = await import('@playwright/test');
    await refreshFlutterAccessibility(this.page);
    await this.expectSuggestionCardVisible(15_000);
    const titleNode = this.page.getByText(CareSuggestionPage.displayTitleRe).first();
    await expect(titleNode).toBeVisible({ timeout: 15_000 });
    const routineName = (await titleNode.textContent())?.trim() ?? '';
    if (!routineName) {
      throw new Error('Could not read suggestion display title on profile');
    }
    const escaped = routineName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    return new RegExp(escaped, 'i');
  }

  async expectSuggestionForRhythmNotVisible(
    rhythmPattern: RegExp,
    timeout = 15_000,
  ): Promise<void> {
    const { expect } = await import('@playwright/test');
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const card = this.page.locator(
        '[flt-semantics-identifier="care_suggestion_group"]',
      );
      const match = card.filter({ hasText: rhythmPattern });
      await expect(match).toHaveCount(0);
    }).toPass({ timeout });
  }

  async expectCareRhythmVisible(rhythmPattern: RegExp, timeout = 30_000): Promise<void> {
    const { expect } = await import('@playwright/test');
    const agenda = new CareAgendaPage(this.page);
    const petId = this.page.url().match(/\/pet\/([^/?]+)/)?.[1];
    if (!petId) {
      throw new Error(`Could not resolve pet id from URL: ${this.page.url()}`);
    }
    await enableFlutterAccessibility(this.page);
    await this.page.goto(flutterGotoUrl(`/pet/${petId}/events`));
    await waitForFlutterRoutePattern(this.page, new RegExp(`/pet/${petId}/events`), 30_000);
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await agenda.showUpcomingCare();
      const row = semanticsByName(this.page, rhythmPattern);
      await row.scrollIntoViewIfNeeded();
      await expect(row).toBeVisible();
    }).toPass({ timeout });
  }

  async acceptSuggestion(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const card = this.suggestionCardRoot();
    await card.scrollIntoViewIfNeeded();
    const respond = this.page.waitForResponse(
      (res) =>
        res.url().includes('/care-recommendations/') &&
        res.url().includes('/respond') &&
        res.request().method() === 'POST' &&
        res.ok(),
      { timeout: 45_000 },
    );
    await card.getByRole('button', { name: addRoutineRe }).click();
    await waitForFlutterRoutePattern(this.page, /\/care\/add/, 20_000);
    await refreshFlutterAccessibility(this.page);
    const saveSemantics = this.page.locator(
      '[flt-semantics-identifier="save_health_entry_button"]',
    );
    await saveSemantics.scrollIntoViewIfNeeded();
    await saveSemantics.click({ timeout: 20_000 });
    await respond;
    await refreshFlutterAccessibility(this.page);
  }

  async expectSuggestionCardHidden(timeout = 15_000): Promise<void> {
    const { expect } = await import('@playwright/test');
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(
        this.page.locator('[flt-semantics-identifier="care_suggestion_group"]'),
      ).toHaveCount(0);
    }).toPass({ timeout });
  }

  async expectSuggestionNotInEvents(timeout = 5_000): Promise<void> {
    const { expect } = await import('@playwright/test');
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(
        this.page.locator('[flt-semantics-identifier="care_suggestion_group"]'),
      ).toHaveCount(0);
    }).toPass({ timeout });
  }

  async expectAcceptAndNotRelevantVisible(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const card = this.suggestionCardRoot();
    await card.getByRole('button', { name: addRoutineRe }).waitFor({ timeout: 15_000 });
    await card.getByRole('button', { name: whyRe }).waitFor({ timeout: 15_000 });
    await card.getByRole('button', { name: noThanksRe }).waitFor({ timeout: 15_000 });
    await card.getByRole('button', { name: laterRe }).waitFor({ timeout: 15_000 });
  }
}
