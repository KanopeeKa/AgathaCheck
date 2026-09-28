/**
 * @bdd people.feature
 */
import { test, expect } from '../fixtures/auth.fixture';
import { LandingPage } from '../pages/landing.page';
import { GuardianDashboardPage } from '../pages/guardian-dashboard.page';
import { createPet, signupUser } from '../support/api';
import {
  reachAuthenticatedHome,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';
import { prepareLiveApiAccess } from '../support/waf';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

async function loginGuardian(
  page: import('@playwright/test').Page,
  email: string,
  password: string,
): Promise<void> {
  const landing = new LandingPage(page);
  await landing.goto();
  await landing.login(email, password);
  await reachAuthenticatedHome(page);
}

test.describe('People hub remodel @people', () => {
  test('@P2 desk module labels Vet team sub-block', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL());
    await createPet(baseURL(), user.accessToken, 'DeskPet');
    await loginGuardian(page, user.email, user.password);

    const dashboard = new GuardianDashboardPage(page);
    await dashboard.expectLoaded();
    await refreshFlutterAccessibility(page);
    await expect(page.getByText(/^Vet team$/i).first()).toBeVisible({
      timeout: 30_000,
    });
  });

  test('@P2 bottom nav opens People hub', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL());
    await createPet(baseURL(), user.accessToken, 'PeoplePet');
    await loginGuardian(page, user.email, user.password);

    const dashboard = new GuardianDashboardPage(page);
    await dashboard.openBottomNavTab('People');
    await waitForFlutterRoutePattern(page, /\/pc\/people(?:\?|$)/, 30_000);
    await expect(page.getByText(/^People$|^Autour de vos animaux$/i).first()).toBeVisible();
  });
});
