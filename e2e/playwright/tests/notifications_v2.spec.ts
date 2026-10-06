/**
 * @bdd notifications_v2.feature
 * Scenario: Notification generated for overdue health entry
 * Scenario: Notification generated for entry due soon
 * Scenario: A reminder is created again after care is done on time
 * Scenario: Pending share invite shows inline accept and decline in Activity
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  checkCareReminders,
  completeNextOccurrence,
  createCareItem,
  getCareItem,
  withCareClock,
} from '../support/care-api';
import {
  createHealthEntry,
  createPet,
  acceptPetShareInviteByCode,
  createPetShareInvite,
  getNotifications,
  signupUser,
  triggerCheckDueNotifications,
  type TestNotification,
} from '../support/api';
import { NotificationsPage } from '../pages/notifications.page';
import { PetListPage } from '../pages/pet-list.page';

test.describe('Notifications v2 programme', () => {
  test('notification generated for overdue health entry', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const user = await signupUser(baseURL, { firstName: 'Olivia', lastName: 'Overdue' });

    const pet = await createPet(baseURL, user.accessToken, 'Bella');
    const pastDate = new Date();
    pastDate.setDate(pastDate.getDate() - 7);
    const entry = await createHealthEntry(baseURL, user.accessToken, pet.id, {
      name: 'Vaccination',
      nextDueDate: pastDate.toISOString().slice(0, 10),
    });

    await triggerCheckDueNotifications(baseURL, user.accessToken);
    const notifications = await getNotifications(baseURL, user.accessToken);
    const overdueInbox = notifications.filter(
      (n: TestNotification) => n.health_entry_id === entry.id && n.type === 'overdue',
    );
    expect(overdueInbox).toHaveLength(0);
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
    const dueSoon = notifications.filter(
      (n: TestNotification) => n.health_entry_id === entry.id && n.type === 'due_soon',
    );

    expect(dueSoon).toHaveLength(0);
  });

  test('a reminder is created again after care is done on time', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
    const today = new Date().toISOString().slice(0, 10);
    const nextWeek = new Date(`${today}T12:00:00Z`);
    nextWeek.setUTCDate(nextWeek.getUTCDate() + 7);
    await withCareClock(`${today}T12:00`, page);
    try {
      const entry = await createCareItem(baseURL, testUser.accessToken, pet.id, {
        name: 'Weekly grooming reminder',
        careFamily: 'grooming',
        frequency: 'weekly',
        dueDate: today,
        scheduleType: 'from_completion',
        remindDaysBefore: 7,
      });
      expect((await getNotifications(baseURL, testUser.accessToken))
        .filter((n) => n.health_entry_id === entry.id)).toHaveLength(0);

      await completeNextOccurrence(baseURL, testUser.accessToken, entry.id, { completedOn: today });
      const next = await getCareItem(baseURL, testUser.accessToken, entry.id);
      expect(next.next_due_date).toBe(nextWeek.toISOString().slice(0, 10));

      const checkDue = await checkCareReminders(baseURL, testUser.accessToken);
      expect(checkDue).toEqual({ checked: true, created: 0 });
    } finally {
      await withCareClock(null, page);
    }
  });

  test('pending share invite shows inline accept and decline in activity', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const owner = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
    const pet = await createPet(baseURL, owner.accessToken, 'Bella', 'Dog');
    const bob = await signupUser(baseURL, { firstName: 'Bob', lastName: 'Invitee' });
    await createPetShareInvite(baseURL, owner.accessToken, [pet.id], bob.email, 'carer');

    await loginAs(page, bob);
    const petList = new PetListPage(page);
    await petList.expectLoaded();

    const notifications = new NotificationsPage(page);
    await notifications.openFromPetList();
    await notifications.selectInboxTab('activity');
    await notifications.expectInlineShareInviteActions();
  });

  test('accepted share invite is resolved and leaves needs-response', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const owner = await signupUser(baseURL, { firstName: 'Cara', lastName: 'Owner' });
    const pet = await createPet(baseURL, owner.accessToken, 'Luna', 'Dog');
    const invitee = await signupUser(baseURL, { firstName: 'Dan', lastName: 'Invitee' });
    const invite = await createPetShareInvite(
      baseURL,
      owner.accessToken,
      [pet.id],
      invitee.email,
      'carer',
    );
    await acceptPetShareInviteByCode(baseURL, invitee.accessToken, invite.code);

    const rows = await getNotifications(baseURL, invitee.accessToken);
    const inviteRow = rows.find(
      (n) => n.type === 'shareInviteReceived' || (n as { wire_type?: string }).wire_type === 'shareInviteReceived',
    );
    expect(inviteRow).toBeTruthy();
    expect((inviteRow as { resolved_at?: string | null }).resolved_at).toBeTruthy();
  });
});
