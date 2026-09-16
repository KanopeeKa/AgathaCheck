import { Page } from '@playwright/test';

import {
  enableFlutterAccessibility,
  escapeRegExp,
  flutterGotoUrl,
  refreshFlutterAccessibility,
  semanticsByName,
  waitForFlutterRoutePattern,
} from '../support/flutter';

const suggestionTitleRe = /Suggested by Agatha|Suggéré par Agatha/i;
const acceptRe = /^Accept$|^Accepter$/i;
const notRelevantRe = /^Not relevant$|^Non pertinent$/i;
const dismissRe = /^Dismiss$|^Ignorer$/i;

export class CareSuggestionPage {
  constructor(private readonly page: Page) {}

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

  async expectSuggestionCardVisible(suggestedName: string, timeout = 30_000): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await semanticsByName(this.page, suggestionTitleRe).first().waitFor({ timeout });
    await this.page
      .getByText(new RegExp(escapeRegExp(suggestedName)))
      .first()
      .waitFor({ timeout });
  }

  async expectSuggestionCardNotVisible(timeout = 5_000): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await semanticsByName(this.page, suggestionTitleRe)
      .first()
      .waitFor({ state: 'detached', timeout });
  }

  async acceptSuggestion(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await this.page.getByRole('button', { name: acceptRe }).first().click();
  }

  async expectSuggestionNotInEvents(timeout = 5_000): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await semanticsByName(this.page, suggestionTitleRe)
      .first()
      .waitFor({ state: 'detached', timeout });
  }

  async expectAcceptAndNotRelevantVisible(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await this.page.getByRole('button', { name: acceptRe }).first().waitFor({ timeout: 15_000 });
    await this.page.getByRole('button', { name: notRelevantRe }).first().waitFor({ timeout: 15_000 });
    await this.page.getByRole('button', { name: dismissRe }).first().waitFor({ timeout: 15_000 });
  }
}
