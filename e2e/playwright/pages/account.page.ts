import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';

export type AppSection = 'guardian' | 'organization';

const LAST_APP_SECTION_KEY = 'flutter.last_app_section';

/**
 * Account preferences and post-login section routing helpers.
 * Maps to: flutter_app/test/bdd/features/account_area.feature
 */
export class AccountPage {
  constructor(private readonly page: Page) {}

  /** BDD Given: the user has last app section "guardian" | "organization". */
  static async seedLastAppSection(page: Page, section: AppSection): Promise<void> {
    await page.goto('/', { waitUntil: 'domcontentloaded' });
    await page.evaluate(
      ({ key, value }) => {
        // SharedPreferences stores plain wire strings (not JSON-encoded).
        window.localStorage.setItem(key, value);
      },
      { key: LAST_APP_SECTION_KEY, value: section },
    );
  }

  /** BDD Then: the user should be navigated to the organisation home screen. */
  async expectOrganisationHomeScreen(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/o\/home/, 60_000);
    await expect(
      this.page.getByRole('button', { name: /open notifications/i }),
    ).toBeVisible({ timeout: 15_000 });
  }

  /** BDD Then: the user should be navigated to the guardian home screen. */
  async expectGuardianHomeScreen(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/pc\/home/, 60_000);
    await expect(
      this.page.getByRole('button', { name: /open notifications/i }),
    ).toBeVisible({ timeout: 15_000 });
  }
}
