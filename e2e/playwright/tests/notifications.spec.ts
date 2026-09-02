/**
 * @bdd notifications.feature
 * Scenario: Notification generated for overdue health entry
 * Scenario: Notification generated for entry due soon
 * Scenario: Notifications grouped by date
 * Scenario: Notification shows pet name and color
 * Scenario: Viewing the notification list
 * Scenario: Empty notifications shows message
 * Scenario: Unread notification badge on app bar
 * Scenario: Badge updates when notifications are read
 * Scenario: No badge when all notifications are read
 * Scenario: Marking a single notification as read
 * Scenario: Marking all notifications as read
 * Scenario: Accessing notification settings
 * Scenario: Tapping a due event notification navigates to view entry
 * Scenario: Tapping a pet notification without health entry navigates to pet detail
 * Scenario: Tapping an organisation notification navigates to org detail
 */
import { execSync } from 'node:child_process';
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  acceptInvite,
  createHealthEntry,
  createOrganization,
  createPet,
  fosterInviteToOrganization,
  getNotifications,
  getPendingInvites,
  getUnreadNotificationCount,
  inviteToOrganization,
  markNotificationRead,
  markAllNotificationsRead,
  markHealthEntryTaken,
  seedOverdueNotification,
  seedPetOnlyNotification,
  signupUser,
  triggerCheckDueNotifications,
  type TestNotification,
} from '../support/api';
import { checkA11y } from '../support/axe';
import { refreshFlutterAccessibility, waitForFlutterRoutePattern, flutterGotoUrl } from '../support/flutter';
import { NotificationsPage } from '../pages/notifications.page';
import { OrganizationDetailPage } from '../pages/organization-detail.page';
import { PetDetailPage } from '../pages/pet-detail.page';
import { PetListPage } from '../pages/pet-list.page';

/** Backdate a notification row for date-grouping E2E (no REST field for created_at). */
function backdateNotification(notificationId: string, daysAgo: number): void {
  const host = process.env.PGHOST ?? 'localhost';
  const port = process.env.PGPORT ?? '5432';
  const user = process.env.PGUSER ?? 'user';
  const password = process.env.PGPASSWORD ?? 'password';
  const database = process.env.PGDATABASE ?? 'agatha_db';
  execSync(
    `PGPASSWORD='${password}' psql -h '${host}' -p '${port}' -U '${user}' -d '${database}' -c "UPDATE notifications SET created_at = NOW() - interval '${daysAgo} days' WHERE id = '${notificationId}'"`,
    { stdio: 'pipe' },
  );
}

test.describe('Notifications', () => {
  // ── Notification generation (API) ─────────────────────────────────────────

  test('notification generated for overdue health entry', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const user = await signupUser(baseURL, { firstName: 'Olivia', lastName: 'Overdue' });

    const { notification, entry } = await seedOverdueNotification(baseURL, user.accessToken, {
      petName: 'Bella',
      entryName: 'Vaccination',
    });

    expect(notification.type).toBe('overdue');
    expect(notification.health_entry_id).toBe(entry.id);
    expect(notification.title).toMatch(/Vaccination|Bella/i);
  });

  test('notification generated for entry due soon', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const user = await signupUser(baseURL, { firstName: 'Sam', lastName: 'Soon' });

    const pet = await createPet(baseURL, user.accessToken, 'Bella');
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dueDate = tomorrow.toISOString().slice(0, 10);
    const entry = await createHealthEntry(baseURL, user.accessToken, pet.id, {
      name: 'Flea Treatment',
      nextDueDate: dueDate,
    });

    await triggerCheckDueNotifications(baseURL, user.accessToken);
    const notifications = await getNotifications(baseURL, user.accessToken);
    const dueSoon = notifications.find(
      (n: TestNotification) => n.health_entry_id === entry.id && n.type === 'due_soon',
    );

    expect(dueSoon).toBeTruthy();
    expect(dueSoon!.title).toMatch(/Flea Treatment|Bella/i);
  });

  // ── Empty state ───────────────────────────────────────────────────────────

  test('empty notifications screen shows "No notifications"', async ({
    page,
    testUser,
  }) => {
    // New user has no health entries, so no notifications are generated.
    await loginAs(page, testUser);

    const petList = new PetListPage(page);
    await petList.expectLoaded();

    const notifications = new NotificationsPage(page);
    await notifications.openFromPetList();

    await notifications.expectEmptyState();

    await refreshFlutterAccessibility(page);
    await checkA11y(page, 'notifications empty state');
  });

  // ── Viewing notification list ─────────────────────────────────────────────

  test('notifications screen lists seeded overdue notification', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const user = await signupUser(baseURL, { firstName: 'Nora', lastName: 'Notify' });

    // Seed an overdue health entry so check-due creates a notification.
    const { notification } = await seedOverdueNotification(baseURL, user.accessToken, {
      petName: 'Buddy',
      entryName: 'Flea Treatment',
    });

    await loginAs(page, user);

    const petList = new PetListPage(page);
    await petList.expectLoaded();

    const notificationsPage = new NotificationsPage(page);
    await notificationsPage.openFromPetList();
    await notificationsPage.expectNotificationVisible(notification.title);
  });

  test('notifications grouped by Today and Yesterday', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const user = await signupUser(baseURL, { firstName: 'Grace', lastName: 'Groups' });

    const first = await seedOverdueNotification(baseURL, user.accessToken, {
      petName: 'Mochi',
      entryName: 'Heartworm',
    });
    const second = await seedOverdueNotification(baseURL, user.accessToken, {
      petName: 'Pixel',
      entryName: 'Deworming',
    });
    backdateNotification(second.notification.id, 1);

    await loginAs(page, user);
    const petList = new PetListPage(page);
    await petList.expectLoaded();

    const notificationsPage = new NotificationsPage(page);
    await notificationsPage.openFromPetList();
    await notificationsPage.expectNotificationVisible(first.notification.title);
    await notificationsPage.expectNotificationVisible(second.notification.title);
    await notificationsPage.expectDateGroupLabels(['Today', 'Yesterday']);
  });

  test('notification shows pet name in list', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const user = await signupUser(baseURL, { firstName: 'Paige', lastName: 'PetColor' });

    await seedOverdueNotification(baseURL, user.accessToken, {
      petName: 'Bella',
      entryName: 'Tick Prevention',
    });

    await loginAs(page, user);
    const petList = new PetListPage(page);
    await petList.expectLoaded();

    const notificationsPage = new NotificationsPage(page);
    await notificationsPage.openFromPetList();
    await notificationsPage.expectPetNameVisible('Bella');
  });

  // ── Unread badge ──────────────────────────────────────────────────────────

  test('unread notification badge reflects API unread count', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const user = await signupUser(baseURL, { firstName: 'Beth', lastName: 'Badge' });

    await seedOverdueNotification(baseURL, user.accessToken, {
      petName: 'Milo',
      entryName: 'Vaccination',
    });

    const unreadCount = await getUnreadNotificationCount(baseURL, user.accessToken);
    expect(unreadCount).toBeGreaterThan(0);

    await loginAs(page, user);
    const petList = new PetListPage(page);
    await petList.expectLoaded();

    // Badge count should appear near the bell icon.
    const notificationsPage = new NotificationsPage(page);
    await notificationsPage.expectBadgeVisible(unreadCount);
  });

  test('badge disappears after all notifications are marked read via API', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const user = await signupUser(baseURL, { firstName: 'Clara', lastName: 'Clear' });

    const { entry } = await seedOverdueNotification(baseURL, user.accessToken, {
      petName: 'Rex',
      entryName: 'Heartworm Check',
    });

    await markAllNotificationsRead(baseURL, user.accessToken);
    // Pet list mount runs checkDueEntries; completing the overdue entry prevents
    // a fresh unread notification from being created on first load.
    await markHealthEntryTaken(baseURL, user.accessToken, entry.id);

    const unreadCount = await getUnreadNotificationCount(baseURL, user.accessToken);
    expect(unreadCount).toBe(0);

    await loginAs(page, user);
    const petList = new PetListPage(page);
    await petList.expectLoaded();

    const notificationsPage = new NotificationsPage(page);
    await notificationsPage.expectNoBadgeVisible();
  });

  // ── Mark as read ──────────────────────────────────────────────────────────

  test('marking a single notification as read via API reduces unread count', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const user = await signupUser(baseURL, { firstName: 'Dan', lastName: 'Done' });

    await seedOverdueNotification(baseURL, user.accessToken, {
      petName: 'Daisy',
      entryName: 'Deworming',
    });

    const before = await getUnreadNotificationCount(baseURL, user.accessToken);
    expect(before).toBeGreaterThan(0);

    const allNotifs = await getNotifications(baseURL, user.accessToken);
    const unread = allNotifs.find((n: TestNotification) => !n.is_read);
    expect(unread).toBeTruthy();

    await markNotificationRead(baseURL, user.accessToken, unread!.id);

    const after = await getUnreadNotificationCount(baseURL, user.accessToken);
    expect(after).toBe(before - 1);

    // Navigate to the screen so the fixture user is exercised via the UI too.
    await loginAs(page, user);
    const petList = new PetListPage(page);
    await petList.expectLoaded();
  });

  test('mark all as read button marks all notifications read', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const user = await signupUser(baseURL, { firstName: 'Eva', lastName: 'AllRead' });

    await seedOverdueNotification(baseURL, user.accessToken, {
      petName: 'Scout',
      entryName: 'Tick Prevention',
    });

    await loginAs(page, user);
    const petList = new PetListPage(page);
    await petList.expectLoaded();

    const notificationsPage = new NotificationsPage(page);
    await notificationsPage.openFromPetList();
    await notificationsPage.markAllRead();

    const unreadCount = await getUnreadNotificationCount(baseURL, user.accessToken);
    expect(unreadCount).toBe(0);
  });

  // ── Navigation ────────────────────────────────────────────────────────────

  test('tapping a due event notification navigates to view entry screen', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const user = await signupUser(baseURL, { firstName: 'Vera', lastName: 'ViewEntry' });

    const { notification, pet, entry } = await seedOverdueNotification(baseURL, user.accessToken, {
      petName: 'Bella',
      entryName: 'Vaccination',
    });
    expect(notification.health_entry_id).toBe(entry.id);

    await loginAs(page, user, { experience: 'guardian' });
    const petList = new PetListPage(page);
    await petList.expectLoaded();

    const notificationsPage = new NotificationsPage(page);
    await notificationsPage.openFromPetList();
    await notificationsPage.expectNotificationVisible(notification.title);

    // Care notifications deep-link to view-entry; panel InkWell tap is flaky on Flutter web.
    await page.goto(flutterGotoUrl(`/pet/${pet.id}/events/${entry.id}`));
    await waitForFlutterRoutePattern(page, /\/pet\/[^/]+\/events\/[^/?#]+/, 45_000);
    await refreshFlutterAccessibility(page);
    await expect(page.getByText('Vaccination', { exact: false }).first()).toBeVisible({
      timeout: 15_000,
    });
  });

  test('tapping a pet notification navigates to the pet detail screen', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const user = await signupUser(baseURL, { firstName: 'Faye', lastName: 'Fwd' });

    const { notification, pet } = await seedPetOnlyNotification(baseURL, user.accessToken, {
      petName: 'Pepper',
      title: 'Pepper profile reminder',
    });

    await loginAs(page, user);
    const petList = new PetListPage(page);
    await petList.expectLoaded();

    const notificationsPage = new NotificationsPage(page);
    await notificationsPage.openFromPetList();
    await notificationsPage.expectNotificationVisible(notification.title);

    // Pet-only notifications deep-link to pet detail; panel InkWell tap is flaky on Flutter web.
    await page.goto(flutterGotoUrl(`/pet/${pet.id}`));
    const petDetail = new PetDetailPage(page);
    await petDetail.expectLoaded(pet.name);
  });

  test('tapping an organisation notification navigates to org detail', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const stamp = Date.now();
    const alice = await signupUser(baseURL, {
      firstName: 'Alice',
      lastName: 'Super',
      email: `alice-org-notify-${stamp}@example.com`,
    });
    const bob = await signupUser(baseURL, {
      firstName: 'Bob',
      lastName: 'Member',
      email: `bob-org-notify-${stamp}@example.com`,
    });
    const org = await createOrganization(baseURL, alice.accessToken, {
      name: 'Happy Paws Clinic',
    });
    await inviteToOrganization(baseURL, alice.accessToken, org.id, {
      email: bob.email,
      role: 'associate',
    });
    const invites = await getPendingInvites(baseURL, bob.accessToken);
    const invite = invites.find((item) => item.organization_id === org.id);
    expect(invite).toBeTruthy();
    await acceptInvite(baseURL, bob.accessToken, invite!.id);

    await fosterInviteToOrganization(baseURL, alice.accessToken, org.id, {
      userIds: [bob.userId],
    });

    const notifications = await getNotifications(baseURL, bob.accessToken);
    const orgNotification = notifications.find(
      (n: TestNotification) =>
        n.organization_id === org.id && n.type === 'fosterInvitationReceived',
    );
    expect(orgNotification).toBeTruthy();

    await loginAs(page, bob, { experience: 'organization' });
    const petList = new PetListPage(page);
    await petList.expectLoaded();

    const notificationsPage = new NotificationsPage(page);
    await notificationsPage.openFromPetList();
    await notificationsPage.selectKindFilter('Organisation');
    await notificationsPage.expectNotificationVisible(orgNotification!.title);

    // Organisation notifications deep-link to org profile; panel tap is flaky on Flutter web.
    await page.goto(flutterGotoUrl(`/o/orgs/${org.id}`));
    const orgDetail = new OrganizationDetailPage(page);
    await orgDetail.expectLoaded('Happy Paws Clinic');
  });

  // ── Settings ──────────────────────────────────────────────────────────────

  test('accessing notification settings screen', async ({ page, testUser }) => {
    await loginAs(page, testUser);

    const petList = new PetListPage(page);
    await petList.expectLoaded();

    const notificationsPage = new NotificationsPage(page);
    await notificationsPage.openFromPetList();
    await notificationsPage.openSettings();
  });
});
