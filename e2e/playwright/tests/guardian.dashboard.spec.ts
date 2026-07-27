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
import { createPet, signupUser } from '../support/api';
import {
  dismissConsentBannerIfPresent,
<<<<<<< HEAD
  dashboardSectionGroup,
=======
  flutterGotoUrl,
>>>>>>> 93facf74 (phase(14/15): Global /g/events rework (#452))
  refreshFlutterAccessibility,
  skipGuardianOnboardingIfPresent,
  waitForPostLoginRoute,
  waitForFlutterRoutePattern,
} from '../support/flutter';
import { prepareLiveApiAccess } from '../support/waf';
import { createHealthEntry, createPet, signupUser } from '../support/api';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

async function loginGuardian(
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
      await createPet(baseURL(), user.token, { name: `DashPet${i}` });
    }

    await loginGuardian(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);
    await refreshFlutterAccessibility(page);

    const experience = new ExperiencePage(page);
    await experience.expectGuardianShell();

    for (let i = 0; i < 6; i += 1) {
      await expect(page.getByText(`DashPet${i}`, { exact: true })).toBeVisible();
    }
    await expect(page.getByText('Manage pets', { exact: true })).toBeVisible();
  });

  test('global events screen shows unified list without tabs', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, { name: 'EventsPet' });
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
    await expect(page.getByText('Add an event', { exact: true })).toBeVisible();
    await expect(page.getByText('Due Med', { exact: true })).toBeVisible();
  });

  test('global events screen supports pet and cohort filters', async ({ page }) => {
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL());
    const owned = await createPet(baseURL(), user.token, { name: 'OwnedPet' });
    const foster = await createPet(baseURL(), user.token, { name: 'FosterPet' });
    await createHealthEntry(baseURL(), user.token, owned.id, {
      name: 'Owned Entry',
      nextDueDate: new Date().toISOString().slice(0, 10),
    });
    await createHealthEntry(baseURL(), user.token, foster.id, {
      name: 'Foster Entry',
      nextDueDate: new Date().toISOString().slice(0, 10),
    });

    await loginGuardian(page, user.email, user.password);
    await page.goto(flutterGotoUrl('/g/events'));
    await refreshFlutterAccessibility(page);
    await waitForFlutterRoutePattern(page, /^\/g\/events(?:\?|$)/, 60_000);

    await expect(page.getByText('My Pets', { exact: true })).toBeVisible();
    await expect(page.getByText('My Fostered Pets', { exact: true })).toBeVisible();
    await expect(page.getByText('All Pets', { exact: true })).toBeVisible();
    await expect(page.getByText('OwnedPet', { exact: true })).toBeVisible();
    await expect(page.getByText('FosterPet', { exact: true })).toBeVisible();
  });
});
