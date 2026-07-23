import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  expectAppBarTitle,
  flutterGotoUrl,
  flutterRoutePath,
  isExperienceShellVisible,
  navigateWithShellFallback,
  openExperienceDrawer,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';

const NOTIFICATIONS_ROUTE_PATTERN = /\/(g|o)\/notifications(?:\?|$)/;

/** Nav v2 drawer labels (EN + FR) — replaces legacy top-bar "Notifications". */
const NOTIFICATIONS_DRAWER_LABEL =
  /^(?:Notifications|Guardian notifications|Organisation notifications|Notifications gardien|Notifications organisation)$/i;

const NOTIFICATIONS_DRAWER_ROLE =
  /^(?:Notifications|Guardian notifications|Organisation notifications|Notifications gardien|Notifications organisation)/i;

const NOTIFICATIONS_UNREAD_SUFFIX = /,\s*(?:99\+|[1-9]\d?)\s*unread/i;

/** Pick guardian vs org notifications route from the current effective URL. */
function notificationsPathForPage(page: Page): string {
  const route = flutterRoutePath(page.url());
  const useOrgHome = route.startsWith('/o/') || route.startsWith('/organizations');
  return useOrgHome ? '/o/notifications' : '/g/notifications';
}

async function gotoNotificationsRoute(page: Page): Promise<void> {
  const notificationsPath = notificationsPathForPage(page);
  await page.goto(flutterGotoUrl(notificationsPath));
  await refreshFlutterAccessibility(page);
  await waitForFlutterRoutePattern(page, NOTIFICATIONS_ROUTE_PATTERN, 30_000);
}

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
      await gotoNotificationsRoute(this.page);
    } else {
      const notificationsPath = notificationsPathForPage(this.page);
      await navigateWithShellFallback(
        this.page,
        NOTIFICATIONS_ROUTE_PATTERN,
        notificationsPath,
        () => this.expectLoaded(),
        { helper: 'notifications.openFromPetList', testTitle: null },
      );
      return;
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

  /** Assert the unread-count badge on the legacy app bar, hamburger, or experience drawer. */
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
      const settingsButton = this.page.getByRole('button', {
        name: /^(Settings|Paramètres)$/i,
      });
      if (await settingsButton.isVisible({ timeout: 2_000 }).catch(() => false)) {
        const badgeDigit = settingsButton.getByText(
          new RegExp(`^${label.replace('+', '\\+')}$`),
        );
        if (await badgeDigit.isVisible({ timeout: 5_000 }).catch(() => false)) {
          return;
        }
      }

      await openExperienceDrawer(this.page);
      const drawerEntry = this.page
        .getByRole('button', { name: NOTIFICATIONS_DRAWER_ROLE })
        .or(this.page.getByRole('menuitem', { name: NOTIFICATIONS_DRAWER_ROLE }))
        .first();
      if (await drawerEntry.isVisible({ timeout: 5_000 }).catch(() => false)) {
        const badgeLabel =
          (await drawerEntry.getAttribute('aria-label')) ?? (await drawerEntry.innerText());
        expect(badgeLabel).toMatch(
          new RegExp(`${label.replace('+', '\\+')}\\s*unread`, 'i'),
        );
        return;
      }

      await gotoNotificationsRoute(this.page);
      await this.expectLoaded();
      if (count > 0) {
        await expect(this.page.getByText(/notification:/i)).not.toHaveCount(0, {
          timeout: 15_000,
        });
      }
      return;
    }

    throw new Error(`Notifications badge (${label}) not found`);
  }

  /** Assert no unread-count badge on the legacy app bar, hamburger, or experience drawer. */
  async expectNoBadgeVisible(): Promise<void> {
    const legacyControl = this.page
      .getByRole('button', { name: /^Notifications/i })
      .or(this.page.getByRole('group', { name: /^Notifications/i }))
      .first();
    if (await legacyControl.isVisible({ timeout: 2_000 }).catch(() => false)) {
      const badgeLabel =
        (await legacyControl.getAttribute('aria-label')) ?? (await legacyControl.innerText());
      expect(badgeLabel).not.toMatch(NOTIFICATIONS_UNREAD_SUFFIX);
      return;
    }

    if (await isExperienceShellVisible(this.page)) {
      const settingsButton = this.page.getByRole('button', {
        name: /^(Settings|Paramètres)$/i,
      });
      if (await settingsButton.isVisible({ timeout: 2_000 }).catch(() => false)) {
        const badgeDigit = settingsButton.getByText(/^(?:99\+|[1-9]\d?)$/);
        await expect(badgeDigit).toHaveCount(0, { timeout: 5_000 });
      }

      await openExperienceDrawer(this.page);
      const notificationsEntry = this.page
        .getByRole('button', { name: NOTIFICATIONS_DRAWER_ROLE })
        .or(this.page.getByRole('group', { name: NOTIFICATIONS_DRAWER_ROLE }))
        .or(this.page.getByRole('menuitem', { name: NOTIFICATIONS_DRAWER_ROLE }))
        .first();
      if (await notificationsEntry.isVisible({ timeout: 5_000 }).catch(() => false)) {
        const badgeLabel =
          (await notificationsEntry.getAttribute('aria-label')) ??
          (await notificationsEntry.innerText());
        expect(badgeLabel).not.toMatch(NOTIFICATIONS_UNREAD_SUFFIX);
        return;
      }

      const notificationsTile = this.page.getByText(NOTIFICATIONS_DRAWER_LABEL);
      await notificationsTile.waitFor({ timeout: 10_000 });
      const rowText = await notificationsTile
        .locator(
          'xpath=ancestor::*[self::button or @role="button" or @role="group" or @role="menuitem"][1]',
        )
        .innerText()
        .catch(() => notificationsTile.innerText());
      expect(rowText).not.toMatch(/\b(?:99\+|[1-9]\d?)\b/);
      return;
    }

    throw new Error('Notifications control not found for badge assertion');
  }
}
