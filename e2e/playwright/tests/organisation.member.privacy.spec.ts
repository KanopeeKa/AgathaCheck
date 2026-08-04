/**
 * @bdd organisation_member_privacy.feature
 * Scenario: Member updates privacy settings from Account
 * Scenario: Profile Leave navigates to Account org settings
 */
import { test, expect } from '../fixtures/auth.fixture';
import { LandingPage } from '../pages/landing.page';
import { ExperiencePage } from '../pages/experience.page';
import { seedDualRoleUser } from '../support/api';
import {
  dismissConsentBannerIfPresent,
  refreshFlutterAccessibility,
  waitForPostLoginRoute,
  waitForFlutterRoutePattern,
} from '../support/flutter';
import { prepareLiveApiAccess } from '../support/waf';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

async function loginFromLanding(
  page: import('@playwright/test').Page,
  email: string,
  password: string,
): Promise<void> {
  const landing = new LandingPage(page);
  await landing.goto();
  await landing.login(email, password);
  await dismissConsentBannerIfPresent(page);
  await waitForPostLoginRoute(page);
  await refreshFlutterAccessibility(page);
}

test.describe('Organisation member privacy', () => {
  test('member updates privacy settings from Account', async ({ page }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user, org } = await seedDualRoleUser(baseURL());
    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);

    const experience = new ExperiencePage(page);
    await experience.gotoAccountFromDrawer();
    await page.locator(`[flt-semantics-identifier="account_org_settings_${org.id}"]`).click();
    await waitForFlutterRoutePattern(page, new RegExp(`/account/orgs/${org.id}`), 30_000);
    await refreshFlutterAccessibility(page);

    await page.locator('[flt-semantics-identifier="account_org_card_visibility"]').click();
    await page.getByRole('option', { name: /Admins only/i }).click();
    await page.locator('[flt-semantics-identifier="account_org_privacy_save"]').click();
    await expect(page.getByText(/privacy settings saved/i)).toBeVisible({
      timeout: 15_000,
    });
  });

  test('profile Leave navigates to Account org settings', async ({ page }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user, org } = await seedDualRoleUser(baseURL());
    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);

    await page.goto(`/o/orgs/${org.id}/profile`);
    await waitForFlutterRoutePattern(page, new RegExp(`/o/orgs/${org.id}/profile`), 30_000);
    await refreshFlutterAccessibility(page);

    await page.getByRole('button', { name: /more/i }).click();
    await page.getByText(/Leave Organization/i).click();
    await waitForFlutterRoutePattern(
      page,
      new RegExp(`/account/orgs/${org.id}.*highlight=leave`),
      30_000,
    );
    await expect(page.locator('[flt-semantics-identifier="account_org_leave"]')).toBeVisible();
  });
});
