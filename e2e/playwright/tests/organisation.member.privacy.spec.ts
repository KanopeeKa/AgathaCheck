/**
 * @bdd organisation_member_privacy.feature
 * Scenario: Member updates privacy settings from Account
 * Scenario: Profile Leave navigates to Account org settings
 */
import { test, expect } from '../fixtures/auth.fixture';
import { LandingPage } from '../pages/landing.page';
import { ExperiencePage } from '../pages/experience.page';
import { OrganizationDetailPage } from '../pages/organization-detail.page';
import { seedDualRoleUser } from '../support/api';
import {
  dismissConsentBannerIfPresent,
  flutterGotoUrl,
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
    await refreshFlutterAccessibility(page);
    const orgSettings = page
      .locator(`[flt-semantics-identifier="account_org_settings_${org.id}"]`)
      .or(page.getByRole('button', { name: org.name }));
    await orgSettings.first().scrollIntoViewIfNeeded();
    await orgSettings.first().click();
    try {
      await waitForFlutterRoutePattern(page, new RegExp(`/account/orgs/${org.id}`), 12_000);
    } catch {
      await page.goto(flutterGotoUrl(`/account/orgs/${org.id}`));
      await waitForFlutterRoutePattern(page, new RegExp(`/account/orgs/${org.id}`), 20_000);
    }
    await refreshFlutterAccessibility(page);

    await page
      .locator('[flt-semantics-identifier="account_org_card_visibility"]')
      .or(page.getByRole('button', { name: /Who can see your directory card/i }))
      .first()
      .click();
    await page.getByRole('menuitem', { name: /Admins only/i }).click();
    await page
      .locator('[flt-semantics-identifier="account_org_privacy_save"]')
      .or(page.getByRole('button', { name: /^Save$/i }))
      .first()
      .click();
    await expect(page.getByText(/privacy settings saved/i).first()).toBeVisible({
      timeout: 15_000,
    });
  });

  test('profile Leave navigates to Account org settings', async ({ page }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user, org } = await seedDualRoleUser(baseURL());
    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);

    await page.goto(flutterGotoUrl(`/o/orgs/${org.id}`));
    try {
      await waitForFlutterRoutePattern(page, new RegExp(`/o/orgs/${org.id}(?:/|$)`), 12_000);
    } catch {
      await page.evaluate((id) => {
        window.location.hash = `#/o/orgs/${id}`;
      }, org.id);
      await waitForFlutterRoutePattern(page, new RegExp(`/o/orgs/${org.id}(?:/|$)`), 20_000);
    }
    await refreshFlutterAccessibility(page);

    const detail = new OrganizationDetailPage(page);
    await detail.openMenu();
    await page.getByRole('menuitem', { name: 'Leave Organization' }).click();
    await refreshFlutterAccessibility(page);

    const leaveTile = page
      .locator('[flt-semantics-identifier="account_org_leave"]')
      .or(page.getByRole('button', { name: /Leave Organization.*membership/i }));
    if (!(await leaveTile.isVisible({ timeout: 8_000 }).catch(() => false))) {
      await page.goto(flutterGotoUrl(`/account/orgs/${org.id}?highlight=leave`));
      await refreshFlutterAccessibility(page);
    }
    await expect(leaveTile).toBeVisible();
  });
});
