import { expect, type Page } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  enableFlutterAccessibility,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';
import { isLiveHostingTarget } from '../support/hosting';
import { passHostingWaf } from '../support/waf';

const continueAccountPattern =
  /Sign in or create an account|Se connecter ou créer un compte/i;

const acceptInvitationPattern = /Accept invitation|Accepter l'invitation/i;

const acceptSharePattern = /Accept & Add to My Pets|Accepter et ajouter à Mes animaux/i;

/**
 * Shared signed-out recipient block and return-to-invite navigation.
 */
export class InviteRecipientPage {
  constructor(private readonly page: Page) {}

  async gotoHashRoute(routePath: string): Promise<void> {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const normalized = routePath.startsWith('/') ? routePath : `/${routePath}`;
    if (isLiveHostingTarget(baseURL)) {
      await passHostingWaf(this.page, baseURL);
    }
    await this.page.goto(`/#${normalized}`, {
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

  async expectSignedOutRecipientPreview(options?: { inviterName?: string }): Promise<void> {
    const timeout = isLiveHostingTarget() ? 45_000 : 30_000;
    const invitedPattern = /invited you|vous a invité/i;
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(this.page.getByRole('button', { name: continueAccountPattern })).toBeVisible();
      const invitedGroup = this.page.getByRole('group', { name: invitedPattern });
      const invitedText = this.page.getByText(invitedPattern);
      if ((await invitedGroup.count()) > 0) {
        await expect(invitedGroup.first()).toBeVisible();
      } else {
        await expect(invitedText.first()).toBeVisible();
      }
      if (options?.inviterName) {
        const inviter = options.inviterName;
        const inviterGroup = this.page.getByRole('group', { name: new RegExp(inviter, 'i') });
        if ((await inviterGroup.count()) > 0) {
          await expect(inviterGroup.first()).toBeVisible();
        } else {
          await expect(this.page.getByText(inviter, { exact: true })).toBeVisible();
        }
      }
      await expect(this.page.getByRole('button', { name: acceptInvitationPattern })).toHaveCount(0);
      await expect(this.page.getByRole('button', { name: acceptSharePattern })).toHaveCount(0);
    }).toPass({ timeout });
  }

  async continueToLandingWithReturnTo(): Promise<void> {
    await this.page.getByRole('button', { name: continueAccountPattern }).click();
    await waitForFlutterRoutePattern(this.page, /\/landing/, 45_000);
    await expect(this.page.url()).toMatch(/returnTo=/);
  }

  async expectReturnedToInvite(routePattern: RegExp): Promise<void> {
    await waitForFlutterRoutePattern(this.page, routePattern, 90_000);
  }

  async expectExplicitAcceptVisible(): Promise<void> {
    const timeout = isLiveHostingTarget() ? 45_000 : 30_000;
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const acceptInvite = this.page.getByRole('button', { name: acceptInvitationPattern });
      const acceptShare = this.page.getByRole('button', { name: acceptSharePattern });
      const acceptCount = (await acceptInvite.count()) + (await acceptShare.count());
      expect(acceptCount).toBeGreaterThan(0);
    }).toPass({ timeout });
  }

  async expectDeclineVisible(): Promise<void> {
    await expect(
      this.page.getByRole('button', { name: /^Decline$|^Refuser$/i }),
    ).toBeVisible({ timeout: 30_000 });
  }
}
