/**
 * @bdd notifications.feature
 * Scenario: Viewing the notification list
 * Scenario: Empty notifications shows message
 * Scenario: Unread notification badge on app bar
 * Scenario: Badge updates when notifications are read
 * Scenario: No badge when all notifications are read
 * Scenario: Marking a single notification as read
 * Scenario: Marking all notifications as read
 * Scenario: Accessing notification settings
 * Scenario: Tapping a pet notification without health entry navigates to pet detail
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  getNotifications,
  getUnreadNotificationCount,
  markNotificationRead,
  markAllNotificationsRead,
  markHealthEntryTaken,
  seedOverdueNotification,
  signupUser,
  type TestNotification,
} from '../support/api';
import { checkA11y } from '../support/axe';
import { refreshFlutterAccessibility } from '../support/flutter';
import { NotificationsPage } from '../pages/notifications.page';
import { PetListPage } from '../pages/pet-list.page';

test.describe('Notifications', () => {
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

  test('tapping a pet notification navigates to the pet detail screen', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const user = await signupUser(baseURL, { firstName: 'Faye', lastName: 'Fwd' });

    const { notification, pet } = await seedOverdueNotification(baseURL, user.accessToken, {
      petName: 'Pepper',
      entryName: 'Annual Checkup',
    });

    await loginAs(page, user);
    const petList = new PetListPage(page);
    await petList.expectLoaded();

    const notificationsPage = new NotificationsPage(page);
    await notificationsPage.openFromPetList();
    await notificationsPage.clickNotification(notification.title);

    // After tapping a pet notification the app navigates to /pet/:petId
    await page
      .getByRole('banner', { name: new RegExp(pet.name, 'i') })
      .or(page.getByRole('button', { name: new RegExp(`Edit Pet.*${pet.name}`, 'i') }))
      .or(page.getByText(pet.name, { exact: false }))
      .first()
      .waitFor({ timeout: 30_000 });
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
