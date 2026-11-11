/**
 * @bdd trust_surfaces.feature
 * Scenario: Bell panel opens notification settings from the shell
 * Scenario: Bell panel opens the full inbox from the shell
 * Scenario: Reject optional on the consent banner dismisses and persists the choice
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { NotificationPanelPage } from '../pages/notification-panel.page';
import { PetListPage } from '../pages/pet-list.page';
import { signupUser, type TestUser } from '../support/api';
import { clearBrowserSessionState } from '../support/session';
import {
  enableFlutterAccessibility,
  flutterGotoUrl,
  refreshFlutterAccessibility,
} from '../support/flutter';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

let sharedUser: TestUser;

test.beforeAll(async () => {
  sharedUser = await signupUser(baseURL());
});

test.describe('Trust surfaces', () => {
  test('bell panel opens notification settings from the shell', async ({ page }) => {
    await loginAs(page, sharedUser);
    const petList = new PetListPage(page);
    await petList.expectLoaded();

    const panel = new NotificationPanelPage(page);
    await panel.openFromBell();
    await panel.openSettingsFromPanel();
    await panel.expectNotificationSettingsScreen();
  });

  test('bell panel opens the full inbox from the shell', async ({ page }) => {
    await loginAs(page, sharedUser);
    const petList = new PetListPage(page);
    await petList.expectLoaded();

    const panel = new NotificationPanelPage(page);
    await panel.openFromBell();
    await panel.openFullInboxFromPanel();
    await panel.expectFullInboxScreen();
  });

  test('reject optional on the consent banner dismisses and persists the choice', async ({
    browser,
  }) => {
    const context = await browser.newContext({
      viewport: { width: 360, height: 740 },
    });
    const page = await context.newPage();
    try {
      await page.addInitScript(() => {
        for (const key of Object.keys(localStorage)) {
          if (key.toLowerCase().includes('consent')) {
            localStorage.removeItem(key);
          }
        }
      });
      await clearBrowserSessionState(page);
      await page.goto(flutterGotoUrl('/landing'));
      await page.waitForSelector('flutter-view, flt-glass-pane', {
        state: 'attached',
        timeout: 60_000,
      });
      await enableFlutterAccessibility(page);
      await page.waitForTimeout(750);
      const panel = new NotificationPanelPage(page);
      await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
      await panel.expectConsentBannerVisible();
      await panel.tapRejectOptionalConsent();
      await panel.expectConsentBannerHidden();

      await page.reload({ waitUntil: 'domcontentloaded' });
      await page.waitForSelector('flutter-view, flt-glass-pane', {
        state: 'attached',
        timeout: 60_000,
      });
      await refreshFlutterAccessibility(page);
      await panel.expectConsentBannerHidden();
      await panel.signInWithoutConsentDismiss(sharedUser.email, sharedUser.password);
      const petList = new PetListPage(page);
      await petList.expectLoaded();
      await panel.expectConsentBannerHidden();
      expect(
        await page
          .getByRole('button', { name: /Reject Optional|Refuser l'optionnel/i })
          .count(),
      ).toBe(0);
    } finally {
      await context.close();
    }
  });
});
