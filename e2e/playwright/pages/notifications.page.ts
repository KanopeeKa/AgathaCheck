import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  expectAppBarTitle,
  filterChipByName,
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

  /** Empty-state copy — Flutter web often merges drawer body text into the group name. */
  private emptyStateLocator() {
    return this.page
      .getByText(/No notifications|Aucune notification/i)
      .or(
        this.page.getByRole('group', {
          name: /No notifications|Aucune notification/i,
        }),
      )
      .or(
        this.page.getByRole('region', {
          name: /No notifications|Aucune notification/i,
        }),
      );
  }

  /** Panel list settled: empty state, notification rows, or error retry. */
  private listBodyLocator() {
    return this.emptyStateLocator()
      .or(this.page.getByText(/notification:/i))
      .or(this.page.getByRole('button', { name: /retry|try again|réessayer/i }));
  }

  /** Open the notification panel via the bell button in the experience shell. */
  async openPanelViaBell(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    const bell = this.page.getByRole('button', { name: /open notifications/i });
    await bell.waitFor({ timeout: 15_000 });
    await bell.click();
    await refreshFlutterAccessibility(this.page);
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
    // Last resort: guardian home + bell (deprecated /g/notifications redirects away)
    await this.page.goto(flutterGotoUrl('/g/home'));
    await refreshFlutterAccessibility(this.page);
    await this.openPanelViaBell();
  }

  /** Wait until async notification list data has settled (empty, rows, or error). */
  private async waitForNotificationListSettled(): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await this.listBodyLocator()
        .or(this.page.getByText(/Failed to load notifications|Échec du chargement/i))
        .first()
        .waitFor({ timeout: 3_000 });
    }).toPass({ timeout: 45_000 });
  }

  /** Wait for the notification panel slide-over to be visible. */
  async expectPanelLoaded(): Promise<void> {
    // Kind-filter chips live only inside the endDrawer — unlike a generic Close
    // button they cannot false-positive from unrelated page chrome (PR #397 gap).
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const allChip = filterChipByName(this.page, /^All$|^Tout$/i).and(
        this.page.locator(':visible'),
      );
      await allChip.waitFor({ timeout: 3_000 });
      const markAll = this.page
        .getByRole('button', { name: /Mark all as read|Tout marquer comme lu/i })
        .or(
          this.page.getByRole('checkbox', {
            name: /Mark all as read|Tout marquer comme lu/i,
          }),
        )
        .and(this.page.locator(':visible'));
      await markAll.waitFor({ timeout: 3_000 });
    }).toPass({ timeout: 15_000 });
    await this.waitForNotificationListSettled();
  }

  async expectLoaded(): Promise<void> {
    // Try panel first, then legacy full-screen
    const panelReady = this.page
      .getByRole('button', { name: /Mark all as read|Tout marquer comme lu/i })
      .or(this.emptyStateLocator());
    const legacyTitle = this.page.getByText('Notifications').first();
    await Promise.race([
      panelReady.first().waitFor({ timeout: 30_000 }),
      legacyTitle.waitFor({ timeout: 30_000 }),
    ]);
  }

  async expectEmptyState(): Promise<void> {
    await this.waitForNotificationListSettled();
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await this.emptyStateLocator().first().waitFor({ timeout: 3_000 });
    }).toPass({ timeout: 15_000 });
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
    const settingsBtn = this.page
      .getByRole('button', { name: /notification settings|paramètres de notification/i })
      .and(this.page.locator(':visible'));
    await settingsBtn.waitFor({ timeout: 15_000 });
    await settingsBtn.click();
    await refreshFlutterAccessibility(this.page);
    await expectAppBarTitle(
      this.page,
      /Notification Settings|Paramètres de notification/i,
    );
  }

  async clickNotification(titleText: string): Promise<void> {
    await this.page.getByText(titleText, { exact: false }).first().click();
    await this.page.waitForTimeout(600);
  }

  /** Digit locator for the experience-shell bell badge (Flutter web Stack semantics). */
  private bellBadgeDigitLocator(label: string) {
    const digitPattern = new RegExp(`^${label.replace('+', '\\+')}$`);
    const bell = this.page.getByRole('button', { name: /open notifications/i });
    // Badge label may be a Stack sibling on Flutter web, not a descendant of the button.
    return bell
      .getByText(digitPattern)
      .or(bell.locator('xpath=..').getByText(digitPattern))
      .or(
        this.page
          .getByRole('banner')
          .getByText(digitPattern)
          .and(this.page.locator(':visible')),
      );
  }

  /** Assert the unread-count badge on the bell icon (experience shell). */
  async expectBadgeVisible(count: number): Promise<void> {
    const label = count > 99 ? '99+' : String(count);

    await expect(async () => {
      await refreshFlutterAccessibility(this.page);

      if (await isExperienceShellVisible(this.page)) {
        const bell = this.page.getByRole('button', { name: /open notifications/i });
        await bell.waitFor({ timeout: 5_000 });
        const badgeDigit = this.bellBadgeDigitLocator(label);
        if (await badgeDigit.first().isVisible().catch(() => false)) {
          return;
        }
        const ariaLabel = await bell.getAttribute('aria-label');
        if (ariaLabel) {
          const countPattern =
            label === '99+'
              ? /99\+/
              : new RegExp(`\\b${label.replace('+', '\\+')}\\b`);
          if (countPattern.test(ariaLabel)) {
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
      if (await legacyControl.isVisible().catch(() => false)) {
        return;
      }

      throw new Error(`Notifications badge (${label}) not found on bell`);
    }).toPass({ timeout: 45_000 });
  }

  /** Assert no unread-count badge on the bell or legacy controls. */
  async expectNoBadgeVisible(): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);

      if (await isExperienceShellVisible(this.page)) {
        const bell = this.page.getByRole('button', { name: /open notifications/i });
        await bell.waitFor({ timeout: 5_000 });
        const badgeDigit = bell
          .getByText(/^(?:99\+|[1-9]\d?)$/)
          .or(bell.locator('xpath=..').getByText(/^(?:99\+|[1-9]\d?)$/))
          .or(
            this.page
              .getByRole('banner')
              .getByText(/^(?:99\+|[1-9]\d?)$/)
              .and(this.page.locator(':visible')),
          );
        await expect(badgeDigit).toHaveCount(0, { timeout: 3_000 });
        return;
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
    }).toPass({ timeout: 30_000 });
  }

  /** Select a notification kind filter chip. */
  async selectKindFilter(kind: 'All' | 'Care' | 'Organisation'): Promise<void> {
    const chip = this.page.getByRole('button', { name: new RegExp(`^${kind}$`, 'i') });
    await chip.waitFor({ timeout: 10_000 });
    await chip.click();
    await this.page.waitForTimeout(400);
  }
}
