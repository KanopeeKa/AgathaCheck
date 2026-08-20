/**
 * @bdd experience_navigation.feature
 * Scenario: Guardian-only user lands on guardian home after login
 * Scenario: Organisation-only user lands on organisation home after login
 * Scenario: Dual-role user lands on guardian home when no last section saved
 * Scenario: Drawer hides Organisation for guardian-only users by default
 * Scenario: Drawer shows Organisation when user is an org member
 * Scenario: User switches to organisation view from guardian drawer
 * Scenario: Bell shows a single combined unread badge across both notification kinds
 * Scenario: Hamburger is shown only on section root screens
 * Scenario: Guardian chooser hides organisation option for guardian-only users
 */
import { test, expect } from '../fixtures/auth.fixture';
import { LandingPage } from '../pages/landing.page';
import { ExperiencePage } from '../pages/experience.page';
import { createPet, seedDualRoleUser, seedRescueHearts, signupUser, seedOverdueNotification, fosterInviteToOrganization, createOrganization, inviteToOrganization, acceptInvite, getPendingInvites, createOrgPet, createFosterPlacement, getUnreadNotificationCount } from '../support/api';
import {
  dismissConsentBannerIfPresent,
  logOutFromApp,
  reachAuthenticatedHome,
  refreshFlutterAccessibility,
  skipOrgOnboardingIfPresent,
  waitForFlutterRoutePattern,
  flutterGotoUrl,
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

  test('bell badge shows combined unread count across notification kinds', async ({ page }) => {
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL(), {
      firstName: 'Badge',
      lastName: 'Bell',
      email: `bell-${Date.now()}@example.com`,
    });
    await seedOverdueNotification(baseURL(), user.accessToken, {
      petName: 'Milo',
      entryName: 'Vaccine',
    });
    await seedOverdueNotification(baseURL(), user.accessToken, {
      petName: 'Luna',
      entryName: 'Heartworm',
    });

    const { alice, org } = await seedRescueHearts(baseURL());
    await inviteToOrganization(baseURL(), alice.accessToken, org.id, {
      email: user.email,
      role: 'associate',
    });
    const invites = await getPendingInvites(baseURL(), user.accessToken);
    const invite = invites.find((item) => item.organization_id === org.id);
    expect(invite).toBeTruthy();
    await acceptInvite(baseURL(), user.accessToken, invite!.id);
    await fosterInviteToOrganization(baseURL(), alice.accessToken, org.id, {
      userIds: [user.userId],
    });
    const pet = await createOrgPet(baseURL(), alice.accessToken, org.id, {
      name: 'BadgePet',
      species: 'dog',
    });
    await createFosterPlacement(baseURL(), alice.accessToken, org.id, pet.id, user.userId, {
      startDate: new Date().toISOString().slice(0, 10),
    });

    const unreadCount = await getUnreadNotificationCount(baseURL(), user.accessToken);
    expect(unreadCount).toBeGreaterThanOrEqual(3);

    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);
    const experience = new ExperiencePage(page);
    await experience.expectBellBadge(Math.min(unreadCount, 99));
  });

  test('hamburger is visible on guardian home but not on sub-screens', async ({
    page,
    testUser,
  }) => {
    await loginFromLanding(page, testUser.email, testUser.password);
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);
    await expect(page.getByRole('button', { name: /open menu/i })).toBeVisible();

    await page.goto(flutterGotoUrl('/g/pets'));
    await refreshFlutterAccessibility(page);
    await expect(page.getByRole('button', { name: /open menu/i })).not.toBeVisible();
    await expect(page.getByRole('button', { name: /back/i })).toBeVisible();
  });

  test('guardian chooser hides organisation option for guardian-only users', async ({
    page,
    testUser,
  }) => {
    await loginFromLanding(page, testUser.email, testUser.password);
    const experience = new ExperiencePage(page);
    await experience.gotoChooser();
    await experience.expectChooserVisible();
    await expect(
      page.getByRole('button', { name: /Run a shelter|Gérer un refuge/i }),
    ).not.toBeVisible();
    await expect(
      page.getByRole('button', { name: /Track my pets|Suivre mes animaux/i }),
    ).toBeVisible();
  });
});
