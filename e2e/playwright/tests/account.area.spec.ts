/**
 * @bdd account_area.feature
 * Scenario: Guardian-only user can enable show organisation section
 * Scenario: Org member cannot disable show organisation section
 * Scenario: Login restores last active organisation section
 * Scenario: Login restores last active guardian section
 */
import { test, expect } from '../fixtures/auth.fixture';
import { AccountPage } from '../pages/account.page';
import { LandingPage } from '../pages/landing.page';
import { ExperiencePage } from '../pages/experience.page';
import { seedDualRoleUser } from '../support/api';
import {
  logOutFromApp,
  openExperienceDrawer,
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
  test('guardian-only user can enable show organisation section', async ({
    page,
    testUser,
  }) => {
    await loginFromLanding(page, testUser.email, testUser.password);
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);

    const experience = new ExperiencePage(page);
    await experience.gotoAccountFromDrawer();
    await experience.enableShowOrganisationSection();

    await openExperienceDrawer(page);
    await refreshFlutterAccessibility(page);
    await expect(
      page
        .getByRole('button', { name: /^Shelters\b/i })
        .or(page.locator('[flt-semantics-identifier="drawer_organisation"]'))
        .first(),
    ).toBeVisible({ timeout: 15_000 });
  });

  test('org member sees show organisation toggle locked on', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user } = await seedDualRoleUser(baseURL());
    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);

    const experience = new ExperiencePage(page);
    await experience.gotoAccountFromDrawer();
    await experience.expectShowOrganisationToggleLockedOn();
  });
});

test.describe('Account area login section restore', () => {
  test('login restores last active organisation section', async ({ page }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user } = await seedDualRoleUser(baseURL());

    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);
    const experience = new ExperiencePage(page);
    await experience.openDrawerOrgView();

    await logOutFromApp(page);
    await loginFromLanding(page, user.email, user.password);

    const account = new AccountPage(page);
    await account.expectOrganisationHomeScreen();
  });

  test('login restores last active guardian section', async ({ page }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user } = await seedDualRoleUser(baseURL());

    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);
    const experience = new ExperiencePage(page);
    await experience.openDrawerOrgView();
    await openExperienceDrawer(page);
    await page
      .getByRole('button', { name: /^My Pets\b/i })
      .or(page.locator('[flt-semantics-identifier="drawer_guardian"]'))
      .first()
      .click();
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);

    await logOutFromApp(page);
    await loginFromLanding(page, user.email, user.password);

    const account = new AccountPage(page);
    await account.expectGuardianHomeScreen();
  });
});
