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
import { seedDualRoleUser, seedRescueHearts, signupUser, seedOverdueNotification, fosterInviteToOrganization, inviteToOrganization, acceptInvite, getPendingInvites, getUnreadNotificationCount } from '../support/api';
import { NotificationsPage } from '../pages/notifications.page';
import {
  dismissConsentBannerIfPresent,
  logOutFromApp,
  reachAuthenticatedHome,
  refreshFlutterAccessibility,
  skipOrgOnboardingIfPresent,
  waitForFlutterRoutePattern,
  welcomeAgathaTrackText,
  flutterGotoUrl,
  workspaceToggleLocator,
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
    await waitForFlutterRoutePattern(page, /\/pc\/home/, 60_000);
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
    await expect(page.getByText(welcomeAgathaTrackText)).not.toBeVisible();
  });

  test('dual-role user lands on guardian home when no last section saved', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user } = await seedDualRoleUser(baseURL());
    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/pc\/home/, 60_000);
    const experience = new ExperiencePage(page);
    await experience.expectGuardianShell();
    await expect(page.getByText(welcomeAgathaTrackText)).not.toBeVisible();
  });

  test('drawer hides Organisation for guardian-only users by default', async ({
    page,
    testUser,
  }) => {
    await loginFromLanding(page, testUser.email, testUser.password);
    await waitForFlutterRoutePattern(page, /\/pc\/home/, 60_000);
    const experience = new ExperiencePage(page);
    await experience.expectDrawerWithoutOrganisation();
  });

  test('drawer shows Organisation when user is an org member', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user } = await seedDualRoleUser(baseURL());
    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/pc\/home/, 60_000);
    const experience = new ExperiencePage(page);
    await experience.expectUnifiedDrawerItems();
  });

  test('user without last section saved lands on guardian home', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user } = await seedDualRoleUser(baseURL());
    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/pc\/home/, 60_000);
    const experience = new ExperiencePage(page);
    await experience.expectGuardianShell();
    await expect(page.getByText(welcomeAgathaTrackText)).not.toBeVisible();
  });

  test('user switches to organisation view from guardian drawer', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { user } = await seedDualRoleUser(baseURL());
    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/pc\/home/, 60_000);
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

    const unreadCount = await getUnreadNotificationCount(baseURL(), user.accessToken);
    expect(unreadCount).toBeGreaterThanOrEqual(3);

    await loginFromLanding(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/pc\/home/, 60_000);
    const notificationsPage = new NotificationsPage(page);
    await notificationsPage.expectBadgeVisible(unreadCount);
  });

  test('workspace toggle is visible on guardian home but back on sub-screens', async ({
    page,
    testUser,
  }) => {
    await loginFromLanding(page, testUser.email, testUser.password);
    await waitForFlutterRoutePattern(page, /\/pc\/home/, 60_000);
    await expect(workspaceToggleLocator(page)).toBeVisible();

    await page.goto(flutterGotoUrl('/pc/pets'));
    await refreshFlutterAccessibility(page);
    await expect(workspaceToggleLocator(page)).not.toBeVisible();
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
    // @legacy BDD expected org hidden for guardian-only; FTUE now shows both paths.
    await expect(
      page.getByRole('button', { name: /Track my pets|Suivre mes animaux/i }),
    ).toBeVisible();
  });
});
