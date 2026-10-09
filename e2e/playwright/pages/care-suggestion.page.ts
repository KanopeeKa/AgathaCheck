import { Page } from '@playwright/test';

import { CareAgendaPage } from './care-agenda.page';
import {
  enableFlutterAccessibility,
  flutterGotoUrl,
  refreshFlutterAccessibility,
  semanticsByName,
  waitForFlutterRoutePattern,
} from '../support/flutter';

const suggestionTitleRe = /Suggested by Agatha|Suggestion d'Agatha|Suggéré par Agatha/i;
const addRoutineRe = /^(Add routine|Add rhythm)$|^(Ajouter la routine|Ajouter le rythme)$/i;
const notRelevantRe = /^Not relevant$|^Pas pertinent$/i;
const dismissRe = /^Dismiss$|^Ignorer$/i;
const whyRe = /^Why\?$|^Pourquoi\s*\?$/i;

export class CareSuggestionPage {
  constructor(private readonly page: Page) {}

  private suggestionCardRoot() {
    // Prefer stable Flutter semantics id — Accept can be absent from the a11y tree
    // while pet policy is still loading (disabled FilledButton).
    return this.page.locator('[flt-semantics-identifier="care_suggestion_group"]').first();
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
      await expect(card.getByText(suggestionTitleRe)).toBeVisible();
    }).toPass({ timeout });
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const card = this.suggestionCardRoot();
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
      /(?:Suggested by Agatha|Suggestion d'Agatha|Suggéré par Agatha)\s+(.+?)\s+Every/i,
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
      const groups = this.page.getByRole('group', { name: suggestionTitleRe });
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
      { timeout: 30_000 },
    );
    await card.getByRole('button', { name: addRoutineRe }).click();
    await respond;
    await refreshFlutterAccessibility(this.page);
  }

  async expectSuggestionNotInEvents(timeout = 5_000): Promise<void> {
    const { expect } = await import('@playwright/test');
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(this.page.getByRole('group', { name: suggestionTitleRe })).toHaveCount(0);
    }).toPass({ timeout });
  }

  async expectAcceptAndNotRelevantVisible(): Promise<void> {
    const { expect } = await import('@playwright/test');
    const card = this.suggestionCardRoot();
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await card.getByRole('button', { name: addRoutineRe }).waitFor({ timeout: 5_000 });
      await card.getByRole('button', { name: whyRe }).waitFor({ timeout: 5_000 });
      await card.getByRole('button', { name: notRelevantRe }).waitFor({ timeout: 5_000 });
      await card.getByRole('button', { name: dismissRe }).waitFor({ timeout: 5_000 });
    }).toPass({ timeout: 30_000 });
  }
}
