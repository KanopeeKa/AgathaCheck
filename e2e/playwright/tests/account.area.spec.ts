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
import { createPet, signupUser } from '../support/api';
import {
  logOutFromApp,
  reachAuthenticatedHome,
  refreshFlutterAccessibility,
  skipOrgOnboardingIfPresent,
  waitForFlutterRoutePattern,
  workspaceToggleLocator,
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
  await refreshFlutterAccessibility(page);
}

test.describe('Account area organisation visibility', () => {
  test('guardian-only user does not see workspace toggle in Pet Care MVP', async ({
    page,
    testUser,
  }) => {
    await loginFromLanding(page, testUser.email, testUser.password);
    await waitForFlutterRoutePattern(page, /\/pc\/home/, 60_000);
    await expect(workspaceToggleLocator(page)).not.toBeVisible();
  });

  test.skip('org member always sees Shelter in workspace menu', async ({ page }) => {
    // Frozen Shelter domain — org workspace toggle not available in Pet Care MVP.
  });
});

test.describe('Account area login landing', () => {
  test('user with pets always lands on Pet Care home after login', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL());
    await createPet(baseURL(), user.accessToken, 'Relogin Pet');

    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/pc\/home/, 60_000);

    await logOutFromApp(page);
    await loginFromLanding(page, user.email, user.password);

    const account = new AccountPage(page);
    await account.expectGuardianHomeScreen();
  });

  test('user lands on Pet Care home after visiting account', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL());
    await createPet(baseURL(), user.accessToken, 'Account Pet');

    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/pc\/home/, 60_000);
    const experience = new ExperiencePage(page);
    await experience.gotoAccountFromDrawer();

    await logOutFromApp(page);
    await loginFromLanding(page, user.email, user.password);

    const account = new AccountPage(page);
    await account.expectGuardianHomeScreen();
  });
});
