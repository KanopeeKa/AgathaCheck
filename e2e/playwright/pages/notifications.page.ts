import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  expectAppBarTitle,
  flutterGotoUrl,
  isExperienceShellVisible,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';

const NOTIFICATIONS_ROUTE_PATTERN = /\/(g|o)\/notifications(?:\?|$)/;

/**
 * Notifications panel and screen.
 * Maps to: flutter_app/test/bdd/features/notifications.feature
 *
 * After the navigation reversal (phase-1-navigation.md):
 * - The unified bell (key: experience_notification_bell) opens the slide-over panel.
 * - /g/notifications and /o/notifications are deprecated (redirect).
 * - Badge is on the bell, not the hamburger.
 */
export class NotificationsPage {
  constructor(private readonly page: Page) {}

  /** Open the notification panel via the bell button in the experience shell. */
  async openPanelViaBell(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    const bell = this.page.getByRole('button', { name: /open notifications/i });
    await bell.waitFor({ timeout: 15_000 });
    await bell.click();
    await this.expectPanelLoaded();
  }

  /** Navigate to the notifications screen from the pet list or experience shell.
   *  Falls back to the legacy route if the shell is not visible. */
  async openFromPetList(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    if (await isExperienceShellVisible(this.page)) {
      await this.openPanelViaBell();
      return;
    }
    const legacyBell = this.page
      .getByRole('button', { name: /^Notifications/i })
      .or(this.page.getByRole('group', { name: /^Notifications/i }))
      .first();
    if (await legacyBell.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await legacyBell.click();
      await this.expectLoaded();
      return;
    }
    // Last resort: navigate directly to the deprecated route (it now redirects)
    await this.page.goto(flutterGotoUrl('/g/notifications'));
    await refreshFlutterAccessibility(this.page);
    await this.expectLoaded();
  }

  /** Wait for the notification panel slide-over to be visible. */
  async expectPanelLoaded(): Promise<void> {
    await this.page
      .getByRole('button', { name: 'Mark all as read' })
      .or(this.page.getByText('No notifications'))
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async expectLoaded(): Promise<void> {
    // Try panel first, then legacy full-screen
    const panelReady = this.page
      .getByRole('button', { name: 'Mark all as read' })
      .or(this.page.getByText('No notifications'))
      .first();
    const legacyTitle = this.page.getByText('Notifications').first();
    await Promise.race([
      panelReady.waitFor({ timeout: 30_000 }),
      legacyTitle.waitFor({ timeout: 30_000 }),
    ]);
  }

  async expectEmptyState(): Promise<void> {
    await this.page.getByText('No notifications').waitFor({ timeout: 15_000 });
  }

  async expectNotificationVisible(titleText: string): Promise<void> {
    await this.page
      .getByText(titleText, { exact: false })
      .first()
      .waitFor({ timeout: 15_000 });
  }

  async expectNotificationCount(expectedCount: number): Promise<void> {
    await expect(
      this.page.getByText(/notification:/, { exact: false }),
    ).toHaveCount(expectedCount, { timeout: 15_000 });
  }

  async markAllRead(): Promise<void> {
    await this.page.getByRole('button', { name: 'Mark all as read' }).click();
    await this.page.waitForTimeout(800);
  }

  async openSettings(): Promise<void> {
    await this.page
      .getByRole('button', { name: /notification settings/i })
      .click();
    await refreshFlutterAccessibility(this.page);
    await expectAppBarTitle(this.page, 'Notification Settings');
  }

  async clickNotification(titleText: string): Promise<void> {
    await this.page.getByText(titleText, { exact: false }).first().click();
    await this.page.waitForTimeout(600);
  }

  /** Assert the unread-count badge on the bell icon (experience shell). */
  async expectBadgeVisible(count: number): Promise<void> {
    const label = count > 99 ? '99+' : String(count);

    if (await isExperienceShellVisible(this.page)) {
      const bell = this.page.getByRole('button', { name: /open notifications/i });
      if (await bell.isVisible({ timeout: 5_000 }).catch(() => false)) {
        const badgeDigit = bell.getByText(
          new RegExp(`^${label.replace('+', '\\+')}$`),
        );
        if (await badgeDigit.isVisible({ timeout: 5_000 }).catch(() => false)) {
          return;
        }
      }
    }

    // Legacy fallback: check old app bar bell or pet-list notifications button
    const legacyControl = this.page
      .getByRole('button', {
        name: new RegExp(`Notifications,\\s*${label}\\s*unread`, 'i'),
      })
      .or(
        this.page.getByRole('group', {
          name: new RegExp(`Notifications,\\s*${label}\\s*unread`, 'i'),
        }),
      )
      .first();
    if (await legacyControl.isVisible({ timeout: 3_000 }).catch(() => false)) {
      return;
    }

    throw new Error(`Notifications badge (${label}) not found on bell`);
  }

  /** Assert no unread-count badge on the bell or legacy controls. */
  async expectNoBadgeVisible(): Promise<void> {
    if (await isExperienceShellVisible(this.page)) {
      const bell = this.page.getByRole('button', { name: /open notifications/i });
      if (await bell.isVisible({ timeout: 5_000 }).catch(() => false)) {
        const badgeDigit = bell.getByText(/^(?:99\+|[1-9]\d?)$/);
        await expect(badgeDigit).toHaveCount(0, { timeout: 5_000 });
        return;
      }
    }

    // Legacy fallback
    const legacyControl = this.page
      .getByRole('button', { name: /^Notifications/i })
      .or(this.page.getByRole('group', { name: /^Notifications/i }))
      .first();
    if (await legacyControl.isVisible({ timeout: 2_000 }).catch(() => false)) {
      const badgeLabel =
        (await legacyControl.getAttribute('aria-label')) ?? (await legacyControl.innerText());
      expect(badgeLabel).not.toMatch(/,\s*(?:99\+|[1-9]\d?)\s*unread/i);
    }
  }

  /** Select a notification kind filter chip. */
  async selectKindFilter(kind: 'All' | 'Care' | 'Organisation'): Promise<void> {
    const chip = this.page.getByRole('button', { name: new RegExp(`^${kind}$`, 'i') });
    await chip.waitFor({ timeout: 10_000 });
    await chip.click();
    await this.page.waitForTimeout(400);
  }
}
