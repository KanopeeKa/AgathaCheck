import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import { dismissConsentBannerIfPresent, expectAppBarTitle } from '../support/flutter';

/**
 * Notifications screen (`/notifications`).
 * Maps to: flutter_app/test/bdd/features/notifications.feature
 */
export class NotificationsPage {
  constructor(private readonly page: Page) {}

  /** Navigate to the notifications screen by clicking the bell icon on the pet list. */
  async openFromPetList(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.page.getByRole('button', { name: 'Notifications' }).first().click();
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
      .getByRole('button', { name: 'Notification settings' })
      .click();
    await expectAppBarTitle(this.page, 'Notification Settings');
  }

  /** Click on the first notification tile that contains the given title text. */
  async clickNotification(titleText: string): Promise<void> {
    await this.page.getByText(titleText, { exact: false }).first().click();
    await this.page.waitForTimeout(600);
  }

  /**
   * Flutter renders the bell IconButton and unread badge Text as siblings inside
   * a Stack; scope lookups to that parent so we don't match unrelated numbers.
   */
  private notificationsBadgeScope() {
    return this.page
      .getByRole('button', { name: 'Notifications' })
      .first()
      .locator('xpath=..');
  }

  /** Assert the unread-count badge on the app-bar notifications control. */
  async expectBadgeVisible(count: number): Promise<void> {
    const label = count > 99 ? '99+' : String(count);
    await expect(
      this.notificationsBadgeScope().getByText(label, { exact: true }),
    ).toBeVisible({ timeout: 10_000 });
  }

  /** Assert no unread-count badge on the app-bar notifications control. */
  async expectNoBadgeVisible(): Promise<void> {
    await expect(
      this.notificationsBadgeScope().getByText(/^(?:99\+|[1-9]\d?)$/, {
        exact: true,
      }),
    ).toHaveCount(0, { timeout: 10_000 });
  }
}
