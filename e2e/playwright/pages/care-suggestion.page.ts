import { Page } from '@playwright/test';

import {
  enableFlutterAccessibility,
  flutterGotoUrl,
  refreshFlutterAccessibility,
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
    return this.page
      .getByRole('group', { name: suggestionTitleRe })
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

  async expectCareRhythmVisible(rhythmPattern: RegExp, timeout = 15_000): Promise<void> {
    const { expect } = await import('@playwright/test');
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(this.page.getByRole('button', { name: rhythmPattern }).first()).toBeVisible();
    }).toPass({ timeout });
  }

  async acceptSuggestion(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await this.suggestionCardRoot().getByRole('button', { name: addRoutineRe }).click();
  }

  async expectSuggestionNotInEvents(timeout = 5_000): Promise<void> {
    const { expect } = await import('@playwright/test');
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(this.page.getByRole('group', { name: suggestionTitleRe })).toHaveCount(0);
    }).toPass({ timeout });
  }

  async expectAcceptAndNotRelevantVisible(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const card = this.suggestionCardRoot();
    await card.getByRole('button', { name: addRoutineRe }).waitFor({ timeout: 15_000 });
    await card.getByRole('button', { name: whyRe }).waitFor({ timeout: 15_000 });
    await card.getByRole('button', { name: notRelevantRe }).waitFor({ timeout: 15_000 });
    await card.getByRole('button', { name: dismissRe }).waitFor({ timeout: 15_000 });
  }
}
