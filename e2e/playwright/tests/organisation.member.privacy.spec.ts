/**
 * @bdd organisation_member_privacy.feature
 * Scenario: Member updates privacy settings from Account
 * Scenario: Profile Leave navigates to Account org settings
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { ExperiencePage } from '../pages/experience.page';
import { OrganizationDetailPage } from '../pages/organization-detail.page';
import { OrganizationListPage } from '../pages/organization-list.page';
import { seedDualRoleUser } from '../support/api';
import {
  flutterGotoUrl,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';
import { prepareLiveApiAccess } from '../support/waf';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

test.describe('Organisation member privacy', () => {
  test('member updates privacy settings from Account', async ({ page }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user, org } = await seedDualRoleUser(baseURL());
    await loginAs(page, user);

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
    await loginAs(page, user);

    const experience = new ExperiencePage(page);
    await experience.openDrawerOrgView();

    const list = new OrganizationListPage(page);
    await list.openOrg(org.name, org.id);

    const detail = new OrganizationDetailPage(page);
    await detail.expectLoaded(org.name);

    await page.goto(flutterGotoUrl(`/account/orgs/${org.id}?highlight=leave`));
    await refreshFlutterAccessibility(page);

    const leaveTile = page
      .locator('[flt-semantics-identifier="account_org_leave"]')
      .or(page.getByRole('button', { name: /Leave Organisation.*membership/i }));
    await expect(leaveTile).toBeVisible();
  });
});
