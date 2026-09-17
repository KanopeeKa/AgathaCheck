import { Page } from '@playwright/test';

import {
  enableFlutterAccessibility,
  flutterGotoUrl,
  refreshFlutterAccessibility,
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

  async expectSuggestionCardVisible(timeout = 30_000): Promise<void> {
    const { expect } = await import('@playwright/test');
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await this.page.getByText(suggestionTitleRe).first().waitFor({ timeout: 2_000 });
      await this.page.getByRole('button', { name: acceptRe }).first().waitFor({ timeout: 2_000 });
    }).toPass({ timeout });
  }

  async expectSuggestionCardNotVisible(timeout = 15_000): Promise<void> {
    const { expect } = await import('@playwright/test');
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const accept = this.page.getByRole('button', { name: acceptRe }).first();
      await expect(accept).toHaveCount(0);
    }).toPass({ timeout });
  }

  async acceptSuggestion(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await this.page.getByRole('button', { name: acceptRe }).first().click();
  }

  async expectSuggestionNotInEvents(timeout = 5_000): Promise<void> {
    const { expect } = await import('@playwright/test');
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const accept = this.page.getByRole('button', { name: acceptRe }).first();
      await expect(accept).toHaveCount(0);
    }).toPass({ timeout });
  }

  async expectAcceptAndNotRelevantVisible(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await this.page.getByRole('button', { name: acceptRe }).first().waitFor({ timeout: 15_000 });
    await this.page.getByRole('button', { name: notRelevantRe }).first().waitFor({ timeout: 15_000 });
    await this.page.getByRole('button', { name: dismissRe }).first().waitFor({ timeout: 15_000 });
  }
}
