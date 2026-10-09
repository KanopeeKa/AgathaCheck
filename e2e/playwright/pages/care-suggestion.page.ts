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
    return this.page
      .getByRole('group', { name: suggestionGroupRe })
      .filter({ has: this.page.getByRole('button', { name: addRoutineRe }) })
      .first();
  }

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
    await refreshFlutterAccessibility(this.page);
    const card = this.suggestionCardRoot();
    const label =
      (await card.getAttribute('aria-label')) ||
      (await card.evaluate((el) => el.getAttribute('aria-label') || ''));
    const match = label.match(
      /(?:Agatha recommends|Agatha recommande|Suggested by Agatha|Suggestion d'Agatha|Suggéré par Agatha)\s*[.:]?\s*(.+?)(?:\s+Every|\s+Chaque|$)/i,
    );
    const routineName = match?.[1]?.trim() ?? '';
    if (!routineName) {
      throw new Error(`Could not parse suggestion routine from group label: ${label}`);
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
      const groups = this.page.getByRole('group', { name: suggestionGroupRe });
      const count = await groups.count();
      for (let i = 0; i < count; i++) {
        const label = await groups.nth(i).evaluate((el) => el.getAttribute('aria-label') || '');
        if (rhythmPattern.test(label)) {
          throw new Error(`Suggestion card still visible for ${rhythmPattern}: ${label}`);
        }
      }
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
    await waitForFlutterRoutePattern(this.page, /\/care\/add/, 15_000);
    await refreshFlutterAccessibility(this.page);
    const saveButton = this.page.getByRole('button', { name: saveFormRe });
    await saveButton.click({ timeout: 15_000 }).catch(async () => {
      await this.page.locator('[flt-semantics-identifier="save_health_entry_button"]').click();
    });
    await respond;
    await refreshFlutterAccessibility(this.page);
  }

  async expectSuggestionNotInEvents(timeout = 5_000): Promise<void> {
    const { expect } = await import('@playwright/test');
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(this.page.getByRole('group', { name: suggestionGroupRe })).toHaveCount(0);
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
