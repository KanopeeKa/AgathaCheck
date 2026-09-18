import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  enableFlutterAccessibility,
  refreshFlutterAccessibility,
} from '../support/flutter';
import { isLiveHostingTarget } from '../support/hosting';
import { passHostingWaf } from '../support/waf';

/**
 * Email share invite landing (`/#/invite/:code`).
 */
export class InviteLandingPage {
  constructor(private readonly page: Page) {}

  async goto(inviteCode: string): Promise<void> {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    if (isLiveHostingTarget(baseURL)) {
      await passHostingWaf(this.page, baseURL);
    }
    await this.page.goto(`/#/invite/${inviteCode}`, {
      waitUntil: 'domcontentloaded',
      timeout: 60_000,
    });
    await this.page.waitForSelector('flutter-view, flt-glass-pane', {
      state: 'attached',
      timeout: isLiveHostingTarget(baseURL) ? 90_000 : 60_000,
    });
    await enableFlutterAccessibility(this.page);
    await dismissConsentBannerIfPresent(this.page);
    await this.page.waitForTimeout(750);
  }

  async expectLoaded(petName: string, inviterFirstName = 'Alice'): Promise<void> {
    const timeout = isLiveHostingTarget() ? 45_000 : 30_000;
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(
        this.page.getByText(new RegExp(`${inviterFirstName}.*invited you|${inviterFirstName}.*vous a invité`, 'i')),
      ).toBeVisible();
      await expect(this.page.getByText(petName)).toBeVisible();
    }).toPass({ timeout });
  }

  async acceptInvitation(): Promise<void> {
    const acceptButton = this.page.getByRole('button', {
      name: /Accept invitation|Accepter l'invitation/i,
    });
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(acceptButton).toBeVisible();
    }).toPass({ timeout: 30_000 });
    await acceptButton.click();
  }
}
