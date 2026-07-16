/**
 * @bdd experience_navigation.feature
 * Scenario: Guardian-only user lands on guardian home after login
 * Scenario: Organisation-only user lands on organisation home after login
 * Scenario: Dual-role user sees experience chooser after login
 * Scenario: Dual-role user remembers guardian choice
 * Scenario: Remembered guardian choice skips chooser on next login
 * Scenario: Dual-role user sets default experience to organisation in settings
 * Scenario: User switches to organisation view from guardian drawer
 * Scenario: Guardian chooser hides organisation option for guardian-only users
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
  waitForPostLoginRoute,
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
  await refreshFlutterAccessibility(page);
}

test.describe('Experience navigation', () => {
  test('guardian-only user lands on guardian home after login', async ({
    page,
    testUser,
  }) => {
    await loginFromLanding(page, testUser.email, testUser.password);
    await page.waitForURL(/\/g\/home/, { timeout: 60_000 });
    const experience = new ExperiencePage(page);
    await experience.expectGuardianShell();
  });

  test('organisation-only user lands on organisation home after login', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { alice } = await seedRescueHearts(baseURL());
    await loginFromLanding(page, alice.email, alice.password);
    await page.waitForURL(/\/o\/home/, { timeout: 60_000 });
    const experience = new ExperiencePage(page);
    await experience.expectOrgShell();
    await expect(page.getByText(/How will you use Agatha Track/i)).not.toBeVisible();
  });

  test('dual-role user sees experience chooser after login', async ({ page }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user } = await seedDualRoleUser(baseURL());
    await loginFromLanding(page, user.email, user.password);
    await page.waitForURL(/\/app\/choose/, { timeout: 60_000 });
    const experience = new ExperiencePage(page);
    await experience.expectChooserVisible();
  });

  test('dual-role user remembers guardian choice', async ({ page }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user } = await seedDualRoleUser(baseURL());
    await loginFromLanding(page, user.email, user.password);
    await page.waitForURL(/\/app\/choose/, { timeout: 60_000 });
    const experience = new ExperiencePage(page);
    await experience.chooseGuardian(true);
    await experience.expectGuardianShell();
  });

  test('remembered guardian choice skips chooser on next login', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user } = await seedDualRoleUser(baseURL());
    await loginFromLanding(page, user.email, user.password);
    await page.waitForURL(/\/app\/choose/, { timeout: 60_000 });
    const experience = new ExperiencePage(page);
    await experience.chooseGuardian(true);

    await page.context().clearCookies();
    await loginFromLanding(page, user.email, user.password);
    await page.waitForURL(/\/g\/home/, { timeout: 60_000 });
    await experience.expectGuardianShell();
  });

  test('dual-role user sets default experience to organisation in settings', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user } = await seedDualRoleUser(baseURL());
    await loginFromLanding(page, user.email, user.password);
    await page.waitForURL(/\/app\/choose/, { timeout: 60_000 });
    const experience = new ExperiencePage(page);
    await experience.chooseGuardian(false);
    await experience.expectGuardianShell();
    await experience.openGuardianSettingsFromDrawer();
    await experience.setDefaultExperience('organization');
    await logOutFromApp(page);

    await page.context().clearCookies();
    await loginFromLanding(page, user.email, user.password);
    await page.waitForURL(/\/o\/home/, { timeout: 60_000 });
    await experience.expectOrgShell();
    await expect(page.getByText(/How will you use Agatha Track/i)).not.toBeVisible();
  });

  test('user switches to organisation view from guardian drawer', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user } = await seedDualRoleUser(baseURL());
    await loginFromLanding(page, user.email, user.password);
    await page.waitForURL(/\/app\/choose/, { timeout: 60_000 });
    const experience = new ExperiencePage(page);
    await experience.chooseGuardian(false);
    await experience.openDrawerOrgView();
    await expect(page.getByRole('button', { name: 'Home' })).toBeVisible();
  });

  test('guardian chooser hides organisation option for guardian-only users', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL());
    await createPet(baseURL, user.accessToken, 'Solo Pet');
    await loginFromLanding(page, user.email, user.password);
    await page.waitForURL(/\/g\/home/, { timeout: 60_000 });

    const experience = new ExperiencePage(page);
    await experience.gotoChooser();
    await expect(
      page.getByText('Shelter / Organisation'),
    ).not.toBeVisible();
    await expect(
      page.getByText('Individual Pet Guardian'),
    ).toBeVisible();
  });
});
