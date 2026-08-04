/**
 * @bdd account_area.feature
 * Scenario: Guardian-only user can enable show organisation section
 * Scenario: Org member cannot disable show organisation section
 */
import { test, expect } from '../fixtures/auth.fixture';
import { LandingPage } from '../pages/landing.page';
import { ExperiencePage } from '../pages/experience.page';
import { seedDualRoleUser } from '../support/api';
import {
  openExperienceDrawer,
  refreshFlutterAccessibility,
  skipGuardianOnboardingIfPresent,
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
  // waitForPostLoginRoute + skipGuardianOnboardingIfPresent already dismiss consent
  // and refresh semantics — avoid stacking redundant ~800ms refreshes (Copilot #584).
  await waitForPostLoginRoute(page);
  await skipGuardianOnboardingIfPresent(page);
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
        .getByRole('button', { name: /^Organisation\b/i })
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
