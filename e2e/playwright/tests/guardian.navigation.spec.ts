/**
 * @bdd guardian_dashboard.feature
 * Scenario: Pet Care compact bottom nav reaches Pets, Actions, and Fostering destinations
 * Scenario: Pet Care leading navigation rail reaches primary destinations at medium width
 * Scenario: Pet Care expanded sidebar reaches primary destinations at wide width
 * Scenario: Workspace toggle switches between Pet Care and Shelter when available
 */
import { test, expect } from '../fixtures/auth.fixture';
import { LandingPage } from '../pages/landing.page';
import { GuardianDashboardPage } from '../pages/guardian-dashboard.page';
import { OrganizationListPage } from '../pages/organization-list.page';
import { HealthDashboardPage } from '../pages/health-dashboard.page';
import { PetListPage } from '../pages/pet-list.page';
import {
  createOrganization,
  createPet,
  signupUser,
} from '../support/api';
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
  test('Pet Care compact bottom nav reaches Pets, Actions, and Fostering destinations', async ({
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
    const petList = new PetListPage(page);
    await petList.expectManagePetsLoaded();
    await petList.expectPetVisible('NavPet');

    await dashboard.openBottomNavTab('Actions');
    await waitForFlutterRoutePattern(page, /\/pc\/events(?:\?|$)/, 30_000);
    await new HealthDashboardPage(page).expectLoaded();

    await dashboard.openFosteringViaBottomNav();
    await expect(page).toHaveURL(/#\/pc\/fostering/);
  });

  test('Guardian leading navigation rail reaches primary destinations at medium width', async ({
    page,
  }) => {
    await page.setViewportSize({ width: 720, height: 900 });
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL());
    await createPet(baseURL(), user.accessToken, 'RailPet');
    await loginGuardian(page, user.email, user.password);

    const dashboard = new GuardianDashboardPage(page);
    await dashboard.open();
    await dashboard.expectLeadingNavRailVisible();

    await dashboard.openLeadingNavDestination('Pets');
    const petList = new PetListPage(page);
    await petList.expectManagePetsLoaded();
    await petList.expectPetVisible('RailPet');

    await dashboard.openLeadingNavDestination('Actions');
    await waitForFlutterRoutePattern(page, /\/pc\/events(?:\?|$)/, 30_000);
    await new HealthDashboardPage(page).expectLoaded();

    await dashboard.openLeadingNavDestination('Fostering');
    await waitForFlutterRoutePattern(page, /\/pc\/fostering(?:\?|$)/, 30_000);
    await expect(page.getByText(/Fostering Sessions|Sessions d'accueil/i).first()).toBeVisible();
  });

  test('Guardian expanded sidebar reaches primary destinations at wide width', async ({
    page,
  }) => {
    await page.setViewportSize({ width: 1024, height: 900 });
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL());
    await createPet(baseURL(), user.accessToken, 'SidebarPet');
    await loginGuardian(page, user.email, user.password);

    const dashboard = new GuardianDashboardPage(page);
    await dashboard.open();
    await dashboard.expectLeadingNavSidebarVisible();

    await dashboard.openLeadingNavDestination('Pets');
    const petList = new PetListPage(page);
    await petList.expectManagePetsLoaded();
    await petList.expectPetVisible('SidebarPet');

    await dashboard.openLeadingNavDestination('Actions');
    await waitForFlutterRoutePattern(page, /\/pc\/events(?:\?|$)/, 30_000);
    await new HealthDashboardPage(page).expectLoaded();

    await dashboard.openLeadingNavDestination('Fostering');
    await waitForFlutterRoutePattern(page, /\/pc\/fostering(?:\?|$)/, 30_000);
    await expect(page.getByText(/Fostering Sessions|Sessions d'accueil/i).first()).toBeVisible();
  });

  test('Workspace toggle switches between Pet Care and Shelter when available', async ({
    page,
  }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL());
    await createOrganization(baseURL(), user.accessToken, { name: 'Harbour Shelter' });
    await createPet(baseURL(), user.accessToken, 'TogglePet');
    await loginGuardian(page, user.email, user.password);

    const dashboard = new GuardianDashboardPage(page);
    await dashboard.open();
    await dashboard.expectWorkspaceToggleVisible();

    await dashboard.openWorkspaceMenu();
    await dashboard.selectWorkspaceMenuItem(/^Shelter$|^Refuge$/i);
    await waitForFlutterRoutePattern(page, /\/o\/orgs(?:\?|$)/, 30_000);
    await new OrganizationListPage(page).expectLoaded();

    await dashboard.openWorkspaceMenu();
    await dashboard.selectWorkspaceMenuItem(/^Pet Care$|^Suivi$/i);
    await waitForFlutterRoutePattern(page, /\/pc\/home(?:\?|$)/, 30_000);
    await expect(dashboard.careRegion()).toBeVisible();
  });
});
