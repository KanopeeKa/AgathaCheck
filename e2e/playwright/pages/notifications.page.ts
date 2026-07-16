import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  expectAppBarTitle,
  isExperienceShellVisible,
  openExperienceDrawer,
  refreshFlutterAccessibility,
} from '../support/flutter';

/**
 * Notifications screen (`/notifications`).
 * Maps to: flutter_app/test/bdd/features/notifications.feature
 */
export class NotificationsPage {
  constructor(private readonly page: Page) {}

  /** Navigate to the notifications screen from the pet list or experience shell. */
  async openFromPetList(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    const legacyBell = this.page
      .getByRole('button', { name: /^Notifications/i })
      .or(this.page.getByRole('group', { name: /^Notifications/i }))
      .first();
    if (await legacyBell.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await legacyBell.click();
    } else if (await isExperienceShellVisible(this.page)) {
      const path = this.page.url().includes('/o/') ? '/o/notifications' : '/g/notifications';
      await this.page.goto(path);
      await refreshFlutterAccessibility(this.page);
    } else {
      throw new Error('Could not open notifications: no app-bar bell or experience shell');
    }
    await this.expectLoaded();
  }

  async expectLoaded(): Promise<void> {
    await expectAppBarTitle(this.page, 'Notifications');
    await this.page
      .getByRole('button', { name: 'Mark all as read' })
      .or(this.page.getByText('No notifications'))
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async expectEmptyState(): Promise<void> {
    await this.page.getByText('No notifications').waitFor({ timeout: 15_000 });
  }

  /** Wait for at least one notification tile referencing the given title text. */
  async expectNotificationVisible(titleText: string): Promise<void> {
    await this.page
      .getByText(titleText, { exact: false })
      .first()
      .waitFor({ timeout: 15_000 });
  }

  /** Expect an approximate count of visible notification entries.
   *  Uses the semantic label pattern "… notification: …" emitted by Flutter. */
  async expectNotificationCount(expectedCount: number): Promise<void> {
    // Notification tiles are semantics nodes that contain the word "notification"
    // in their label.  Waiting for at least expectedCount is sufficient for
    // typical E2E seeding scenarios.
    await expect(
      this.page.getByText(/notification:/, { exact: false }),
    ).toHaveCount(expectedCount, { timeout: 15_000 });
  }

  async markAllRead(): Promise<void> {
    await this.page.getByRole('button', { name: 'Mark all as read' }).click();
    // Wait for the snackbar confirmation or for the button to still be visible
    await this.page.waitForTimeout(800);
  }

  async openSettings(): Promise<void> {
    await this.page
      .getByRole('button', { name: /notification settings/i })
      .click();
    await refreshFlutterAccessibility(this.page);
    await expectAppBarTitle(this.page, 'Notification Settings');
  }

  /** Click on the first notification tile that contains the given title text. */
  async clickNotification(titleText: string): Promise<void> {
    await this.page.getByText(titleText, { exact: false }).first().click();
    await this.page.waitForTimeout(600);
  }

  /** Assert the unread-count badge on the legacy app bar or experience drawer. */
  async expectBadgeVisible(count: number): Promise<void> {
    const label = count > 99 ? '99+' : String(count);
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
    if (await legacyControl.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await legacyControl.waitFor({ timeout: 10_000 });
      return;
    }

    if (await isExperienceShellVisible(this.page)) {
      await openExperienceDrawer(this.page);
      await this.page.getByText('Notifications', { exact: true }).waitFor({ timeout: 10_000 });
      await this.page.getByText(label, { exact: true }).first().waitFor({ timeout: 10_000 });
      return;
    }

    throw new Error(`Notifications badge (${label}) not found`);
  }

  /** Assert no unread-count badge on the legacy app bar or experience drawer. */
  async expectNoBadgeVisible(): Promise<void> {
    const unreadPattern = /,\s*(?:99\+|[1-9]\d?)\s*unread/i;

    const legacyControl = this.page
      .getByRole('button', { name: /^Notifications/i })
      .or(this.page.getByRole('group', { name: /^Notifications/i }))
      .first();
    if (await legacyControl.isVisible({ timeout: 2_000 }).catch(() => false)) {
      const badgeLabel =
        (await legacyControl.getAttribute('aria-label')) ?? (await legacyControl.innerText());
      expect(badgeLabel).not.toMatch(unreadPattern);
      return;
    }

    if (await isExperienceShellVisible(this.page)) {
      await openExperienceDrawer(this.page);
      const notificationsEntry = this.page
        .getByRole('button', { name: /^Notifications/i })
        .or(this.page.getByRole('group', { name: /^Notifications/i }))
        .or(this.page.getByRole('menuitem', { name: /^Notifications/i }))
        .first();
      if (await notificationsEntry.isVisible({ timeout: 2_000 }).catch(() => false)) {
        const badgeLabel =
          (await notificationsEntry.getAttribute('aria-label')) ?? (await notificationsEntry.innerText());
        expect(badgeLabel).not.toMatch(unreadPattern);
        return;
      }

      const notificationsTile = this.page.getByText('Notifications', { exact: true });
      await notificationsTile.waitFor({ timeout: 10_000 });
      const rowText = await notificationsTile
        .locator('xpath=ancestor::*[self::button or @role="button" or @role="group" or @role="menuitem"][1]')
        .innerText()
        .catch(() => notificationsTile.innerText());
      expect(rowText).not.toMatch(/\b(?:99\+|[1-9]\d?)\b/);
      return;
    }

    throw new Error('Notifications control not found for badge assertion');
  }
}
