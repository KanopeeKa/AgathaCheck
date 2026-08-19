/**
 * @bdd guardian_dashboard.feature
 * Scenario: Dashboard shows exactly three sections
 * Scenario: My Pets shows all personal pets with Manage pets link
 * Scenario: Global events screen shows unified list without tabs
 * Scenario: Global events screen supports pet and cohort filters
 */
import { test, expect } from '../fixtures/auth.fixture';
import { LandingPage } from '../pages/landing.page';
import { ExperiencePage } from '../pages/experience.page';
import { createPet, createHealthEntry, signupUser } from '../support/api';
import {
  dismissConsentBannerIfPresent,
  dashboardSectionGroup,
  flutterGotoUrl,
  reachAuthenticatedHome,
  refreshFlutterAccessibility,
  semanticsByName,
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

test.describe('Guardian dashboard', () => {
  test('dashboard shows exactly three sections', async ({ page, testUser }) => {
    await loginGuardian(page, testUser.email, testUser.password);
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);

    await expect(dashboardSectionGroup(page, 'myPets')).toBeVisible();
    await expect(dashboardSectionGroup(page, 'dueAndOverdue')).toBeVisible();
    await expect(dashboardSectionGroup(page, 'myVets')).toBeVisible();

    await expect(page.getByText('Pending foster placements')).not.toBeVisible();
    await expect(page.getByText('Pending Shares')).not.toBeVisible();
  });

  test('My Pets shows all personal pets with Manage pets link', async ({ page }) => {
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL());
    for (let i = 0; i < 6; i += 1) {
      await createPet(baseURL(), user.accessToken, `DashPet${i}`);
    }

    await loginGuardian(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);
    await refreshFlutterAccessibility(page);

    const experience = new ExperiencePage(page);
    await experience.expectGuardianShell();

    for (let i = 0; i < 6; i += 1) {
      await expect(
        semanticsByName(page, new RegExp(`Pet:\\s*DashPet${i}`, 'i')).first(),
      ).toBeVisible();
    }
    await expect(
      page
        .getByRole('button', { name: /Manage pets/i })
        .or(page.getByText('Manage pets', { exact: true }))
        .first(),
    ).toBeVisible();
  });

  test('global events screen shows unified list without tabs', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'EventsPet');
    await createHealthEntry(baseURL, testUser.accessToken, pet.id, {
      name: 'Due Med',
      nextDueDate: new Date().toISOString().slice(0, 10),
    });

    await loginGuardian(page, testUser.email, testUser.password);
    await page.goto(flutterGotoUrl('/g/events'));
    await refreshFlutterAccessibility(page);
    await waitForFlutterRoutePattern(page, /^\/g\/events(?:\?|$)/, 60_000);

    await expect(page.getByText('Events', { exact: true }).first()).toBeVisible();
    await expect(page.getByRole('tab')).toHaveCount(0);
    await expect(page.getByRole('button', { name: /Add an event/i })).toBeVisible();
    await expect(semanticsByName(page, /Due Med/i).first()).toBeVisible();
  });

  test('global events screen supports pet and cohort filters', async ({ page }) => {
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL());
    const owned = await createPet(baseURL(), user.accessToken, 'OwnedPet');
    const foster = await createPet(baseURL(), user.accessToken, 'FosterPet');
    await createHealthEntry(baseURL(), user.accessToken, owned.id, {
      name: 'Owned Entry',
      nextDueDate: new Date().toISOString().slice(0, 10),
    });
    await createHealthEntry(baseURL(), user.accessToken, foster.id, {
      name: 'Foster Entry',
      nextDueDate: new Date().toISOString().slice(0, 10),
    });

    await loginGuardian(page, user.email, user.password);
    await page.goto(flutterGotoUrl('/g/events'));
    await refreshFlutterAccessibility(page);
    await waitForFlutterRoutePattern(page, /^\/g\/events(?:\?|$)/, 60_000);

    await expect(page.getByRole('checkbox', { name: 'My Pets', exact: true })).toBeVisible();
    await expect(
      page.getByRole('checkbox', { name: 'My Fostered Pets', exact: true }),
    ).toBeVisible();
    await expect(page.getByRole('checkbox', { name: 'All Pets', exact: true })).toBeVisible();
    await expect(page.getByRole('checkbox', { name: 'OwnedPet', exact: true })).toBeVisible();
    await expect(page.getByRole('checkbox', { name: 'FosterPet', exact: true })).toBeVisible();
  });
});
