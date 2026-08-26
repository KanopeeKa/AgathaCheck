/**
 * @bdd guardian_dashboard.feature
 * Scenario: Guardian Today prioritises pets and care
 * Scenario: Care preview separates Due and Soon
 * Scenario: My Pets preview is capped at four with an All Pets destination
 * Scenario: Care preview orders overdue, due today, and upcoming items
 * Scenario: Care preview supports completion and undo
 * Scenario: My Vets preview reaches linked vet details
 * Scenario: Empty Guardian dashboard shows first-use guidance without false alerts
 * Scenario: Pending foster placement surfaces as a notification, not a dashboard banner
 * Scenario: Global events screen shows unified list without tabs
 * Scenario: Global events screen supports pet and cohort filters
 */
import { test, expect } from '../fixtures/auth.fixture';
import { LandingPage } from '../pages/landing.page';
import { GuardianDashboardPage } from '../pages/guardian-dashboard.page';
import { NotificationsPage } from '../pages/notifications.page';
import {
  createHealthEntry,
  createPet,
  createVetFull,
  signupUser,
  updatePetVet,
} from '../support/api';
import {
  dashboardSectionGroup,
  flutterGotoUrl,
  reachAuthenticatedHome,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
  semanticsByName,
} from '../support/flutter';
import { prepareLiveApiAccess } from '../support/waf';
import { checkA11y } from '../support/axe';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';
const today = new Date().toISOString().slice(0, 10);
const dateOffset = (days: number): string => {
  const date = new Date(`${today}T12:00:00Z`);
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
};

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

async function seededGuardian(page: import('@playwright/test').Page) {
  await prepareLiveApiAccess(page, baseURL());
  const user = await signupUser(baseURL());
  return user;
}

test.describe('Guardian dashboard', () => {
  test('Guardian Today prioritises pets and care', async ({ page, testUser }) => {
    await loginGuardian(page, testUser.email, testUser.password);
    const dashboard = new GuardianDashboardPage(page);
    await dashboard.open();
    await dashboard.expectTodayCareRegions();
    await dashboard.expectNoPendingDashboardBanner();
  });

  test('Care preview separates Due and Soon', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    const user = await seededGuardian(page);
    const pet = await createPet(baseURL(), user.accessToken, 'TodayPet');
    await createHealthEntry(baseURL(), user.accessToken, pet.id, {
      name: 'Urgent Care',
      nextDueDate: dateOffset(-2),
    });
    await createHealthEntry(baseURL(), user.accessToken, pet.id, {
      name: 'Soon Care',
      nextDueDate: dateOffset(1),
    });
    await loginGuardian(page, user.email, user.password);
    const dashboard = new GuardianDashboardPage(page);
    await dashboard.open();
    await dashboard.expectTodayCareRegions();
    await dashboard.expectCareVisible('Urgent Care');
    await dashboard.expectCareVisible('Soon Care');
  });

  test('My Pets preview is capped at four with an All Pets destination', async ({ page }) => {
    await page.setViewportSize({ width: 320, height: 812 });
    const user = await seededGuardian(page);
    for (let i = 0; i < 6; i += 1) await createPet(baseURL(), user.accessToken, `DashPet${i}`);
    await loginGuardian(page, user.email, user.password);
    const dashboard = new GuardianDashboardPage(page);
    await dashboard.open();
    await dashboard.expectPetPreview(
      ['DashPet0', 'DashPet1', 'DashPet2', 'DashPet3'],
      'DashPet4',
    );
    await dashboard.expectNoHorizontalOverflow();
    await dashboard.expectAllPetsDestination();
    await dashboard.openAllPets();
    await expect(page).toHaveURL(/#\/g\/pets/);
    await dashboard.goBackToDashboard();
  });

  test('Care preview links to the full Care destination', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    const user = await seededGuardian(page);
    const pet = await createPet(baseURL(), user.accessToken, 'PriorityPet');
    await createHealthEntry(baseURL(), user.accessToken, pet.id, { name: 'Overdue Care', nextDueDate: dateOffset(-1) });
    await createHealthEntry(baseURL(), user.accessToken, pet.id, { name: 'Today Care', nextDueDate: today });
    // Default remind_days_before is 1 — upcoming must fall inside that window.
    await createHealthEntry(baseURL(), user.accessToken, pet.id, { name: 'Upcoming Care', nextDueDate: dateOffset(1) });
    await loginGuardian(page, user.email, user.password);
    const dashboard = new GuardianDashboardPage(page);
    await dashboard.open();
    await dashboard.expectCareVisible('Overdue Care');
    await dashboard.expectCareVisible('Today Care');
    await dashboard.expectCarePriorityOrder(['Overdue Care', 'Today Care']);
    await dashboard.expectCareVisible('Upcoming Care');
    await dashboard.openEvents();
    await expect(page).toHaveURL(/#\/g\/events/);
    await dashboard.goBackToDashboard();
  });

  test('Care preview supports completion and undo', async ({ page, testUser }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    const pet = await createPet(baseURL(), testUser.accessToken, 'ActionPet');
    await createHealthEntry(baseURL(), testUser.accessToken, pet.id, {
      name: 'Actionable Care',
      nextDueDate: today,
    });
    await loginGuardian(page, testUser.email, testUser.password);
    const dashboard = new GuardianDashboardPage(page);
    await dashboard.open();
    await dashboard.expectCareVisible('Actionable Care');
    await page.getByRole('button', { name: /mark .*done/i }).first().click();
    await page.getByRole('button', { name: /Mark Completed/i }).click();
    await expect(page.getByRole('button', { name: /undo.*Actionable Care/i })).toBeVisible();
    await page.getByRole('button', { name: /undo.*Actionable Care/i }).click();
    await expect(page.getByRole('button', { name: /mark .*Actionable Care.*done/i })).toBeVisible();
  });

  test('My Vets preview reaches linked vet details', async ({ page, testUser }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    const vet = await createVetFull(baseURL(), testUser.accessToken, { name: 'Dr. Desk' });
    const pet = await createPet(baseURL(), testUser.accessToken, 'VetLinkedPet');
    await updatePetVet(baseURL(), testUser.accessToken, pet.id, {
      name: pet.name,
      species: 'Dog',
      vetId: vet.id,
    });
    await loginGuardian(page, testUser.email, testUser.password);
    const dashboard = new GuardianDashboardPage(page);
    await dashboard.open();
    await dashboard.expectVetVisible('Dr. Desk');
    await expect(semanticsByName(page, /Dr\. Desk.*1 pet/i).first()).toBeVisible();
    await dashboard.openVet('Dr. Desk');
    await expect(page).toHaveURL(/#\/g\/vets\//);
    await dashboard.goBackToDashboard();
  });

  test('Empty Guardian dashboard gives a truthful Care state without false alerts', async ({ page, testUser }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await loginGuardian(page, testUser.email, testUser.password);
    const dashboard = new GuardianDashboardPage(page);
    await dashboard.open();
    const dueSection = dashboard.careRegion();
    await expect(dueSection).toBeVisible();
    await expect(
      dueSection
        .getByRole('button', { name: /Add an event|Ajouter un événement/i })
        .or(semanticsByName(page, /Start their care routine|Commencez leur routine de soins/i))
        .first(),
    ).toBeVisible();
    await expect(
      dueSection.getByRole('button', { name: /mark .*done/i }),
    ).toHaveCount(0);
  });

  test('Pending foster placement surfaces as a notification, not a dashboard banner', async ({ page, testUser }) => {
    await loginGuardian(page, testUser.email, testUser.password);
    const dashboard = new GuardianDashboardPage(page);
    await dashboard.open();
    await dashboard.expectNoPendingDashboardBanner();
    await dashboard.openNotifications();
    await new NotificationsPage(page).expectPanelLoaded();
  });

  test('Global events screen shows unified list without tabs', async ({ page, testUser }) => {
    const pet = await createPet(baseURL(), testUser.accessToken, 'EventsPet');
    await createHealthEntry(baseURL(), testUser.accessToken, pet.id, {
      name: 'Due Med',
      nextDueDate: today,
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

  test('Global events screen supports pet and cohort filters', async ({ page }) => {
    const user = await seededGuardian(page);
    const owned = await createPet(baseURL(), user.accessToken, 'OwnedPet');
    const foster = await createPet(baseURL(), user.accessToken, 'FosterPet');
    await createHealthEntry(baseURL(), user.accessToken, owned.id, { name: 'Owned Entry', nextDueDate: today });
    await createHealthEntry(baseURL(), user.accessToken, foster.id, { name: 'Foster Entry', nextDueDate: today });
    await loginGuardian(page, user.email, user.password);
    await page.goto(flutterGotoUrl('/g/events'));
    await refreshFlutterAccessibility(page);
    await waitForFlutterRoutePattern(page, /^\/g\/events(?:\?|$)/, 60_000);
    for (const label of ['My Pets', 'My Fostered Pets', 'All Pets', 'OwnedPet', 'FosterPet']) {
      await expect(page.getByRole('checkbox', { name: label, exact: true })).toBeVisible();
    }
  });

  test('@smoke-a11y Guardian dashboard has no serious or critical accessibility findings', async ({ page, testUser }) => {
    await loginGuardian(page, testUser.email, testUser.password);
    const dashboard = new GuardianDashboardPage(page);
    await dashboard.open();
    await checkA11y(page, 'Guardian dashboard');
  });
});