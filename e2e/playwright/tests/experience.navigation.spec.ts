/**
 * @bdd experience_navigation.feature
 * Scenario: Guardian-only user lands on guardian home after login
 * Scenario: Organisation-only user lands on organisation home after login
 * Scenario: Dual-role user lands on guardian home when no last section saved
 * Scenario: Drawer hides Organisation for guardian-only users by default
 * Scenario: Drawer shows Organisation when user is an org member
 * Scenario: User switches to organisation view from guardian drawer
 */
import { test, expect } from '../fixtures/auth.fixture';
import { LandingPage } from '../pages/landing.page';
import { ExperiencePage } from '../pages/experience.page';
import { createPet, seedDualRoleUser, seedRescueHearts, signupUser } from '../support/api';
import {
  dismissConsentBannerIfPresent,
  logOutFromApp,
  refreshFlutterAccessibility,
  skipGuardianOnboardingIfPresent,
  skipOrgOnboardingIfPresent,
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
  await skipGuardianOnboardingIfPresent(page);
  await skipOrgOnboardingIfPresent(page);
  await refreshFlutterAccessibility(page);
}

test.describe('Experience navigation', () => {
  test('guardian-only user lands on guardian home after login', async ({
    page,
    testUser,
  }) => {
    await loginFromLanding(page, testUser.email, testUser.password);
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);
    const experience = new ExperiencePage(page);
    await experience.expectGuardianShell();
  });

  test('organisation-only user lands on organisation home after login', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { alice } = await seedRescueHearts(baseURL());
    await loginFromLanding(page, alice.email, alice.password);
    await waitForFlutterRoutePattern(page, /\/o\/home/, 60_000);
    const experience = new ExperiencePage(page);
    await experience.expectOrgShell();
    await expect(page.getByText(/Welcome to Agatha Track|Bienvenue sur Agatha Track/i)).not.toBeVisible();
  });

  test('dual-role user lands on guardian home when no last section saved', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user } = await seedDualRoleUser(baseURL());
    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);
    const experience = new ExperiencePage(page);
    await experience.expectGuardianShell();
    await expect(page.getByText(/Welcome to Agatha Track|Bienvenue sur Agatha Track/i)).not.toBeVisible();
  });

  test('drawer hides Organisation for guardian-only users by default', async ({
    page,
    testUser,
  }) => {
    await loginFromLanding(page, testUser.email, testUser.password);
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);
    const experience = new ExperiencePage(page);
    await experience.expectDrawerWithoutOrganisation();
  });

  test('drawer shows Organisation when user is an org member', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user } = await seedDualRoleUser(baseURL());
    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);
    const experience = new ExperiencePage(page);
    await experience.expectUnifiedDrawerItems();
  });

  test('user without last section saved lands on guardian home', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user } = await seedDualRoleUser(baseURL());
    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);
    const experience = new ExperiencePage(page);
    await experience.expectGuardianShell();
    await expect(page.getByText(/Welcome to Agatha Track|Bienvenue sur Agatha Track/i)).not.toBeVisible();
  });

  test('user switches to organisation view from guardian drawer', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user } = await seedDualRoleUser(baseURL());
    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);
    const experience = new ExperiencePage(page);
    await experience.openDrawerOrgView();
    await expect(
      page.getByRole('button', { name: /open notifications/i }),
    ).toBeVisible({ timeout: 15_000 });
  });
});
