/**
 * @bdd guardian_dashboard.feature
 * Scenario: Guardian compact bottom nav reaches Pets, Care, Fostering destinations
 * Scenario: Workspace toggle switches between Guardian and Shelter when available
 */
import { test, expect } from '../fixtures/auth.fixture';
import { LandingPage } from '../pages/landing.page';
import { GuardianDashboardPage } from '../pages/guardian-dashboard.page';
import { OrganizationListPage } from '../pages/organization-list.page';
import { HealthDashboardPage } from '../pages/health-dashboard.page';
import { createOrganization, createPet, signupUser } from '../support/api';
import {
  reachAuthenticatedHome,
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

test.describe('Guardian navigation', () => {
  test('Guardian compact bottom nav reaches Pets, Care, Fostering destinations', async ({
    page,
  }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL());
    await createPet(baseURL(), user.accessToken, 'NavPet');
    await loginGuardian(page, user.email, user.password);

    const dashboard = new GuardianDashboardPage(page);
    await dashboard.open();

    await dashboard.openBottomNavTab('Pets');
    await waitForFlutterRoutePattern(page, /\/g\/pets(?:\?|$)/, 30_000);
    await expect(page.getByText(/All Pets|Tous les animaux/i).first()).toBeVisible();

    await dashboard.openBottomNavTab('Care');
    await waitForFlutterRoutePattern(page, /\/g\/events(?:\?|$)/, 30_000);
    await new HealthDashboardPage(page).expectLoaded();

    await dashboard.openFosteringViaBottomNav();
    await expect(page).toHaveURL(/#\/g\/fostering/);
  });

  test('Workspace toggle switches between Guardian and Shelter when available', async ({
    page,
  }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL());
    await createOrganization(baseURL(), user.accessToken, { name: 'Harbour Shelter' });
    await loginGuardian(page, user.email, user.password);

    const dashboard = new GuardianDashboardPage(page);
    await dashboard.open();
    await dashboard.expectWorkspaceToggleVisible();

    await dashboard.openWorkspaceMenu();
    await dashboard.selectWorkspaceMenuItem(/^Shelter$|^Refuge$/i);
    await waitForFlutterRoutePattern(page, /\/o\/orgs(?:\?|$)/, 30_000);
    await new OrganizationListPage(page).expectLoaded();

    await dashboard.openWorkspaceMenu();
    await dashboard.selectWorkspaceMenuItem(/^My Pets$|^Mes animaux$/i);
    await waitForFlutterRoutePattern(page, /\/g\/home(?:\?|$)/, 30_000);
    await expect(dashboard.careRegion()).toBeVisible();
  });
});
