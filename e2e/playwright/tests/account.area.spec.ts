/**
 * @bdd account_area.feature
 * Scenario: Guardian-only user always sees Shelter in workspace menu (D-v5-WORKSPACE-1)
 * Scenario: Org member always sees Shelter in workspace menu
 * Scenario: Login always lands on Pet Care home (D-v5-WORKSPACE-2)
 */
import { test, expect } from '../fixtures/auth.fixture';
import { AccountPage } from '../pages/account.page';
import { LandingPage } from '../pages/landing.page';
import { ExperiencePage } from '../pages/experience.page';
import { GuardianDashboardPage } from '../pages/guardian-dashboard.page';
import { seedDualRoleUser } from '../support/api';
import {
  logOutFromApp,
  refreshFlutterAccessibility,
  reachAuthenticatedHome,
  skipOrgOnboardingIfPresent,
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
  await reachAuthenticatedHome(page);
  await skipOrgOnboardingIfPresent(page);
}

test.describe('Account area organisation visibility', () => {
  test('guardian-only user always sees Shelter in workspace menu', async ({
    page,
    testUser,
  }) => {
    await loginFromLanding(page, testUser.email, testUser.password);
    await waitForFlutterRoutePattern(page, /\/pc\/home/, 60_000);

    const dashboard = new GuardianDashboardPage(page);
    await dashboard.openWorkspaceMenu();
    await refreshFlutterAccessibility(page);
    await expect(
      page
        .getByRole('menuitem', { name: /^Shelter$|^Refuge$/i })
        .or(page.getByRole('button', { name: /^Shelter$|^Refuge$/i }))
        .first(),
    ).toBeVisible({ timeout: 15_000 });
  });

  test('org member always sees Shelter in workspace menu', async ({ page }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user } = await seedDualRoleUser(baseURL());
    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/pc\/home/, 60_000);

    const dashboard = new GuardianDashboardPage(page);
    await dashboard.openWorkspaceMenu();
    await refreshFlutterAccessibility(page);
    await expect(
      page
        .getByRole('menuitem', { name: /^Shelter$|^Refuge$/i })
        .or(page.getByRole('button', { name: /^Shelter$|^Refuge$/i }))
        .first(),
    ).toBeVisible({ timeout: 15_000 });
  });
});

test.describe('Account area login landing', () => {
  test('dual-role user always lands on Pet Care home after login', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user } = await seedDualRoleUser(baseURL());

    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/pc\/home/, 60_000);
    const experience = new ExperiencePage(page);
    await experience.openDrawerOrgView();

    await logOutFromApp(page);
    await loginFromLanding(page, user.email, user.password);

    const account = new AccountPage(page);
    await account.expectGuardianHomeScreen();
  });

  test('dual-role user lands on Pet Care home even after visiting Shelter', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user } = await seedDualRoleUser(baseURL());

    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/pc\/home/, 60_000);
    const experience = new ExperiencePage(page);
    await experience.openDrawerOrgView();
    const dashboard = new GuardianDashboardPage(page);
    await dashboard.openWorkspaceMenu();
    await dashboard.selectWorkspaceMenuItem(/^Pet Care$|^Suivi$/i);
    await waitForFlutterRoutePattern(page, /\/pc\/home/, 60_000);

    await logOutFromApp(page);
    await loginFromLanding(page, user.email, user.password);

    const account = new AccountPage(page);
    await account.expectGuardianHomeScreen();
  });
});
