import { Page } from '@playwright/test';

import {
  enableFlutterAccessibility,
  flutterGotoUrl,
  refreshFlutterAccessibility,
  semanticsByName,
  waitForFlutterRoutePattern,
} from '../support/flutter';

const suggestionTitleRe = /Suggested by Agatha|Suggestion d'Agatha|Suggéré par Agatha/i;
const addRhythmRe = /^Add rhythm$|^Ajouter le rythme$/i;
const notRelevantRe = /^Not relevant$|^Pas pertinent$/i;
const dismissRe = /^Dismiss$|^Ignorer$/i;

export class CareSuggestionPage {
  constructor(private readonly page: Page) {}

  private suggestionCard() {
    return semanticsByName(this.page, suggestionTitleRe);
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
      const card = this.suggestionCard();
      await card.waitFor({ state: 'visible', timeout: 2_000 });
      await card.getByRole('button', { name: addRhythmRe }).waitFor({ timeout: 2_000 });
    }).toPass({ timeout });
  }

  async readVisibleSuggestionRhythmPattern(): Promise<RegExp> {
    await refreshFlutterAccessibility(this.page);
    const label =
      (await this.page
        .getByRole('group', { name: suggestionTitleRe })
        .first()
        .evaluate((el) => el.getAttribute('aria-label') || '')) || '';
    const match = label.match(
      /(?:Suggested by Agatha|Suggestion d'Agatha)\s+(.+?)\s+(?:Every|Tous les)/i,
    );
    if (!match?.[1]) {
      throw new Error(`Could not parse suggestion rhythm from group label: ${label}`);
    }
    const escaped = match[1].replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
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
    await this.suggestionCard().getByRole('button', { name: addRhythmRe }).click();
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
    const card = this.suggestionCard();
    await card.getByRole('button', { name: addRhythmRe }).waitFor({ timeout: 15_000 });
    await card.getByRole('button', { name: notRelevantRe }).waitFor({ timeout: 15_000 });
    await card.getByRole('button', { name: dismissRe }).waitFor({ timeout: 15_000 });
  }
}
