import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  enableFlutterAccessibility,
  expectAppBarTitle,
  flutterRoutePath,
  reachAuthenticatedHome,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';
import { NotificationsPage } from './notifications.page';

/**
 * Bell slide-over panel header destinations (D-4.1).
 * Maps to: flutter_app/test/bdd/features/trust_surfaces.feature
 */
export class NotificationPanelPage {
  private readonly notifications: NotificationsPage;

  constructor(private readonly page: Page) {
    this.notifications = new NotificationsPage(page);
  }

  async openFromBell(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await this.notifications.openPanelViaBell();
    await expect(this.panelHeaderControls()).toBeVisible({ timeout: 20_000 });
  }

  /** Inbox + settings icon controls in the slide-over header (stable bundle). */
  private panelHeaderControls() {
    return this.page
      .getByRole('button', { name: /Open full inbox|Ouvrir la boîte de réception/i })
      .or(
        this.page.getByRole('button', {
          name: /Notification settings|Paramètres de notification/i,
        }),
      )
      .first();
  }

  private openInboxButton() {
    return this.page
      .getByTitle(/Open full inbox|Ouvrir la boîte de réception/i)
      .or(this.page.locator('[flt-semantics-identifier="notification_panel_open_inbox"]'))
      .or(this.page.getByRole('button', { name: /Open full inbox|Ouvrir la boîte de réception/i }))
      .first();
  }

  private settingsButton() {
    return this.page
      .getByTitle(/Notification settings|Paramètres de notification/i)
      .or(this.page.locator('[flt-semantics-identifier="notification_panel_settings"]'))
      .or(this.page.getByRole('button', { name: /Notification settings|Paramètres de notification/i }))
      .first();
  }

  async openFullInboxFromPanel(): Promise<void> {
    const control = this.panelHeaderButton(
      /Open full inbox|Ouvrir la boîte de réception/i,
      'notification_panel_open_inbox',
    );
    await expect(async () => {
      if (!(await control.isVisible().catch(() => false))) {
        await this.notifications.openPanelViaBell();
      }
      await control.scrollIntoViewIfNeeded();
      await control.click({ timeout: 5_000 });
      await this.page.waitForTimeout(800);
      await refreshFlutterAccessibility(this.page);
      await this.expectFullInboxScreen();
    }).toPass({ timeout: 45_000 });
  }

  private panelHeaderButton(name: RegExp, identifier: string) {
    return this.page
      .getByLabel(name)
      .or(this.page.getByRole('button', { name }))
      .or(this.page.locator(`[flt-semantics-identifier="${identifier}"]`))
      .first();
  }

  async openSettingsFromPanel(): Promise<void> {
    const control = this.panelHeaderButton(
      /Notification settings|Paramètres de notification/i,
      'notification_panel_settings',
    );
    await expect(async () => {
      if (!(await control.isVisible().catch(() => false))) {
        await this.notifications.openPanelViaBell();
      }
      await control.scrollIntoViewIfNeeded();
      await control.click({ timeout: 5_000 });
      await this.page.waitForTimeout(800);
      await refreshFlutterAccessibility(this.page);
      await expectAppBarTitle(
        this.page,
        /Notification Settings|Paramètres de notification/i,
      );
    }).toPass({ timeout: 45_000 });
  }

  async expectFullInboxScreen(): Promise<void> {
    await expectAppBarTitle(this.page, /Notifications/i);
    await expect(
      this.page.getByRole('button', { name: /Activity|Activité/i }).first(),
    ).toBeVisible({ timeout: 20_000 });
    await expect(
      this.page.getByRole('button', { name: /For you|Pour vous/i }).first(),
    ).toBeVisible({ timeout: 20_000 });
  }

  async expectNotificationSettingsScreen(): Promise<void> {
    await expectAppBarTitle(
      this.page,
      /Notification Settings|Paramètres de notification/i,
    );
  }

  async expectConsentBannerVisible(): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      for (let i = 0; i < 4; i += 1) {
        await this.page.mouse.wheel(0, 500);
        await this.page.waitForTimeout(150);
      }
      const reject = this.page.getByRole('button', {
        name: /Reject Optional|Refuser l'optionnel/i,
      });
      await reject.first().scrollIntoViewIfNeeded();
      await expect(reject.first()).toBeVisible({ timeout: 5_000 });
    }).toPass({ timeout: 45_000 });
  }

  async tapRejectOptionalConsent(): Promise<void> {
    const reject = this.page
      .getByRole('button', { name: /Reject Optional|Refuser l'optionnel/i })
      .first();
    await reject.scrollIntoViewIfNeeded();
    await reject.click();
    await this.page.waitForTimeout(800);
    await refreshFlutterAccessibility(this.page);
  }

  async expectConsentBannerHidden(): Promise<void> {
    await expect(
      this.page.getByText(/Your Privacy Matters|Votre vie privée compte/i),
    ).toHaveCount(0, { timeout: 20_000 });
  }

  /** Login helper that does not auto-accept the consent banner (landing submit does). */
  async signInWithoutConsentDismiss(email: string, password: string): Promise<void> {
    await enableFlutterAccessibility(this.page);
    const emailField = this.page.getByRole('textbox', { name: 'Email' });
    await emailField.waitFor({ state: 'visible', timeout: 30_000 });
    await emailField.click();
    await emailField.fill('');
    await emailField.pressSequentially(email, { delay: 25 });

    const passwordField = this.page.getByRole('textbox', { name: 'Password' });
    await passwordField.click();
    await passwordField.fill('');
    await passwordField.pressSequentially(password, { delay: 25 });

    await this.page.getByRole('button', { name: 'Sign In', exact: true }).click();
    await reachAuthenticatedHome(this.page);
  }
}
