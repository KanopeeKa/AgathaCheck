import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  expectAppBarTitle,
  flutterGotoUrl,
  flutterRoutePath,
  isExperienceShellVisible,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';

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

  /** Empty-state copy — v2 Activity/For you tabs; legacy full-screen used "No notifications". */
  private emptyStateLocator() {
    return this.page
      .getByText(
        /No notifications|Aucune notification|Nothing new\.|Rien de nouveau|No suggestions right now|Pas de suggestion/i,
      )
      .or(
        this.page.getByRole('group', {
          name: /No notifications|Aucune notification|Nothing new|Rien de nouveau/i,
        }),
      )
      .or(
        this.page.getByRole('region', {
          name: /No notifications|Aucune notification|Nothing new|Rien de nouveau/i,
        }),
      );
  }

  /** Notification rows — tile semantics include kind, type label, and title. */
  private notificationRowLocator() {
    return this.page.getByRole('button', {
      name: /(?:Care|Organisation|Soins).*(?:Overdue|Due Soon|Reminder|Completed|General|En retard|Bientôt|Action needed|Unread|Lu|Read)/i,
    });
  }

  /** Panel list settled: empty state, notification rows, or error retry. */
  private listBodyLocator() {
    return this.emptyStateLocator()
      .or(this.notificationRowLocator())
      .or(this.page.getByRole('button', { name: /retry|try again|réessayer/i }));
  }

  private notificationBellLocator() {
    return this.page
      .locator('[flt-semantics-identifier="experience_notification_bell"]')
      .or(this.page.getByRole('button', { name: /open notifications|ouvrir les notifications/i }))
      .first();
  }

  /** Open the notification panel via the bell button in the experience shell. */
  async openPanelViaBell(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    const bell = this.notificationBellLocator();
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await bell.waitFor({ timeout: 5_000 });
      await bell.click();
      await this.page.waitForTimeout(400);
      await refreshFlutterAccessibility(this.page);
      await this.panelChromeLocator().first().waitFor({ timeout: 3_000 });
    }).toPass({ timeout: 30_000 });
    await this.expectPanelLoaded();
  }

  /** Drawer-only chrome: mark-all, v2 explainer, inbox tabs, or Activity empty copy. */
  private panelChromeLocator() {
    return this.page
      .getByRole('button', { name: /Mark all as read|Tout marquer comme lu/i })
      .or(
        this.page.getByText(
          /Reminders now live in Actions|Les rappels sont dans Actions|Nothing new\.|Rien de nouveau/i,
        ),
      )
      .or(this.page.getByRole('button', { name: /Activity|Activité|For you|Pour vous/i }));
  }

  private inboxTabButton(tab: 'activity' | 'forYou') {
    const pattern =
      tab === 'activity' ? /Activity|Activité/i : /For you|Pour vous/i;
    return this.page.getByRole('button', { name: pattern }).first();
  }

  /** Navigate to the notifications screen from the pet list or experience shell.
   *  Falls back to the legacy route if the shell is not visible. */
  async openFromPetList(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    if (await isExperienceShellVisible(this.page)) {
      const path = flutterRoutePath(this.page.url());
      if (!/^\/pc\/home(?:\?|$)/.test(path)) {
        await this.page.goto(flutterGotoUrl('/pc/home'));
        await refreshFlutterAccessibility(this.page);
        await waitForFlutterRoutePattern(this.page, /\/pc\/home(?:\?|$)/, 30_000);
      }
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
    await this.page.goto(flutterGotoUrl('/pc/home'));
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
    // v2 panel chrome lives only inside the endDrawer (no legacy All/Care chips).
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await this.panelChromeLocator().first().waitFor({ timeout: 8_000 });
      const legacyAll = this.page
        .getByRole('button', { name: /^All$|^Tout$/i })
        .and(this.page.locator(':visible'));
      if (await legacyAll.isVisible().catch(() => false)) {
        return;
      }
      await this.inboxTabButton('activity').waitFor({ timeout: 5_000 });
      await this.inboxTabButton('forYou').waitFor({ timeout: 5_000 });
    }).toPass({ timeout: 30_000 });
    await this.waitForNotificationListSettled();
  }

  async selectInboxTab(tab: 'activity' | 'forYou'): Promise<void> {
    await this.inboxTabButton(tab).click();
    await refreshFlutterAccessibility(this.page);
    await this.page.waitForTimeout(400);
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

  /** For you tab empty copy (Activity may show account sign-in after login). */
  async expectForYouEmptyState(): Promise<void> {
    await this.selectInboxTab('forYou');
    await expect(
      this.page.getByText(/No suggestions right now|Pas de suggestion pour l'instant/i).first(),
    ).toBeVisible({ timeout: 15_000 });
  }

  async expectNotificationVisible(titleText: string): Promise<void> {
    await this.page
      .getByText(titleText, { exact: false })
      .first()
      .waitFor({ timeout: 15_000 });
  }

  /** Assert date-group section headers (e.g. Today, Yesterday). */
  async expectDateGroupLabels(labels: string[]): Promise<void> {
    await this.waitForNotificationListSettled();
    await refreshFlutterAccessibility(this.page);
    for (const label of labels) {
      const escaped = label.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const pattern = new RegExp(`^${escaped}$`, 'i');
      await expect(
        this.page
          .getByRole('group', { name: pattern })
          .or(this.page.getByText(pattern))
          .or(this.page.getByRole('button', { name: new RegExp(`^${escaped}\\b`, 'i') }))
          .first(),
      ).toBeVisible({ timeout: 30_000 });
    }
  }

  /** Assert a pet name appears in the notification list (colour strip is visual-only). */
  async expectPetNameVisible(petName: string): Promise<void> {
    await expect(
      this.page.getByText(petName, { exact: false }).first(),
    ).toBeVisible({ timeout: 15_000 });
  }

  async expectNotificationCount(expectedCount: number): Promise<void> {
    await expect(this.notificationRowLocator()).toHaveCount(expectedCount, {
      timeout: 15_000,
    });
  }

  async markAllRead(): Promise<void> {
    await this.page.getByRole('button', { name: 'Mark all as read' }).click();
    await this.page.waitForTimeout(800);
  }

  async openSettings(): Promise<void> {
    // v2 bell panel has no settings control — route is still /notifications/settings.
    await this.page.goto(flutterGotoUrl('/notifications/settings'));
    await refreshFlutterAccessibility(this.page);
    await expectAppBarTitle(
      this.page,
      /Notification Settings|Paramètres de notification/i,
    );
  }

  async clickNotification(titleText: string): Promise<void> {
    const escaped = titleText.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const rowPattern = new RegExp(`(?:Care|Organisation|Soins).*${escaped}`, 'i');
    const careItemRoute = /\/pet\/[^/]+\/events\/[^/?#]+/;

    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      const row = this.page
        .getByRole('button', { name: rowPattern })
        .or(
          this.page.getByRole('button', {
            name: new RegExp(`(?:Care|Soins).*Overdue.*${escaped}`, 'i'),
          }),
        )
        .first();
      await row.waitFor({ timeout: 15_000 });
      await row.scrollIntoViewIfNeeded();
      const box = await row.boundingBox();
      if (box) {
        await this.page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
      } else {
        await row.focus();
        await this.page.keyboard.press('Enter');
      }
      await this.page.waitForTimeout(1_500);
      const path = flutterRoutePath(this.page.url());
      if (!careItemRoute.test(path)) {
        throw new Error(`Notification tap did not navigate (path=${path})`);
      }
    }).toPass({ timeout: 60_000 });
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
    await refreshFlutterAccessibility(this.page);
    await this.page.waitForTimeout(400);
  }
}
