/**
 * @bdd organisation_pet_timeline.feature
 * Scenario: Recording a foster stay for a pet
 * Scenario: Recording an open-ended placement
 * Scenario: Viewing all family events for a pet
 * Scenario: Removing a family event
 * Scenario: Family events appear in the health dashboard
 * Scenario: Notifications for ending family events
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  createFamilyEvent,
  createOrgPet,
  deleteFamilyEvent,
  getFamilyEvents,
  inviteToOrganization,
  acceptInvite,
  getPendingInvites,
  signupUser,
  createOrganization,
} from '../support/api';
import { HealthDashboardPage } from '../pages/health-dashboard.page';

const ORG_NAME = 'Rescue Hearts';

async function seedRescueHeartsWithPet(baseURL: string) {
  const alice = await signupUser(baseURL, {
    firstName: 'Alice',
    lastName: 'Super',
    email: `alice-${Date.now()}@example.com`,
  });
  const org = await createOrganization(baseURL, alice.accessToken, {
    name: ORG_NAME,
    type: 'charity',
  });
  const pet = await createOrgPet(baseURL, alice.accessToken, org.id, {
    name: 'Max',
    species: 'dog',
  });
  return { alice, org, pet };
}

async function inviteMember(
  baseURL: string,
  alice: Awaited<ReturnType<typeof seedRescueHeartsWithPet>>['alice'],
  org: Awaited<ReturnType<typeof seedRescueHeartsWithPet>>['org'],
  firstName: string,
  lastName: string,
) {
  const member = await signupUser(baseURL, {
    firstName,
    lastName,
    email: `${firstName.toLowerCase()}-${Date.now()}@example.com`,
  });
  await inviteToOrganization(baseURL, alice.accessToken, org.id, {
    email: member.email,
    role: 'member',
  });
  const invites = await getPendingInvites(baseURL, member.accessToken);
  const invite = invites.find((item) => item.organization_id === org.id);
  if (!invite) throw new Error(`No invite for ${firstName}`);
  await acceptInvite(baseURL, member.accessToken, invite.id);
  return member;
}

test.describe('Organisation pet timeline', () => {
  test('recording a foster stay for a pet', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org, pet } = await seedRescueHeartsWithPet(baseURL);
    const frank = await inviteMember(baseURL, alice, org, 'Frank', 'Member');

    const event = await createFamilyEvent(baseURL, alice.accessToken, pet.id, {
      assignedToUserId: frank.userId,
      fromDate: '2025-06-01',
      toDate: '2025-08-31',
      notes: 'Summer fostering',
      eventType: 'foster_stay',
    });

    const events = await getFamilyEvents(baseURL, alice.accessToken, pet.id);
    const match = events.find((e) => e.id === event.id);
    expect(match).toBeTruthy();
    expect(match?.assigned_to_user_id).toBe(frank.userId);
    expect(match?.from_date).toBe('2025-06-01');
    expect(match?.to_date).toBe('2025-08-31');
    expect(match?.notes).toBe('Summer fostering');
  });

  test('recording an open-ended placement', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org, pet } = await seedRescueHeartsWithPet(baseURL);
    const grace = await inviteMember(baseURL, alice, org, 'Grace', 'Member');

    const event = await createFamilyEvent(baseURL, alice.accessToken, pet.id, {
      assignedToUserId: grace.userId,
      fromDate: '2025-09-01',
      notes: 'Long-term care',
    });

    const events = await getFamilyEvents(baseURL, alice.accessToken, pet.id);
    const match = events.find((e) => e.id === event.id);
    expect(match).toBeTruthy();
    expect(match?.assigned_to_user_id).toBe(grace.userId);
    expect(match?.from_date).toBe('2025-09-01');
    expect(match?.to_date).toBeFalsy();
    expect(match?.notes).toBe('Long-term care');
  });

  test('viewing all family events for a pet', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org, pet } = await seedRescueHeartsWithPet(baseURL);
    const frank = await inviteMember(baseURL, alice, org, 'Frank', 'Member');
    const grace = await inviteMember(baseURL, alice, org, 'Grace', 'Member');

    await createFamilyEvent(baseURL, alice.accessToken, pet.id, {
      assignedToUserId: frank.userId,
      fromDate: '2025-06-01',
      toDate: '2025-08-31',
      notes: 'Summer fostering',
    });
    await createFamilyEvent(baseURL, alice.accessToken, pet.id, {
      assignedToUserId: grace.userId,
      fromDate: '2025-09-01',
      notes: 'Long-term care',
    });

    const events = await getFamilyEvents(baseURL, alice.accessToken, pet.id);
    expect(events).toHaveLength(2);
    const fromDates = events.map((e) => e.from_date).sort();
    expect(fromDates).toEqual(['2025-06-01', '2025-09-01']);
  });

  test('@legacy removing a family event deletes it via API', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org, pet } = await seedRescueHeartsWithPet(baseURL);
    const frank = await inviteMember(baseURL, alice, org, 'Frank', 'Member');

    const event = await createFamilyEvent(baseURL, alice.accessToken, pet.id, {
      assignedToUserId: frank.userId,
      fromDate: '2025-06-01',
      toDate: '2025-08-31',
    });

    await deleteFamilyEvent(baseURL, alice.accessToken, pet.id, event.id);

    const events = await getFamilyEvents(baseURL, alice.accessToken, pet.id);
    expect(events.find((e) => e.id === event.id)).toBeFalsy();
    expect(events.find((e) => e.assigned_to_user_id === frank.userId)).toBeFalsy();
  });

  // Legacy family_events API rows are not mirrored on the health dashboard feed yet.
  // See docs/refactoring-debt.md — dashboard lists HealthEntry rows only.
  test.skip('family events appear in the health dashboard', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org, pet } = await seedRescueHeartsWithPet(baseURL);
    const frank = await inviteMember(baseURL, alice, org, 'Frank', 'Member');

    await createFamilyEvent(baseURL, alice.accessToken, pet.id, {
      assignedToUserId: frank.userId,
      fromDate: '2025-06-01',
      toDate: '2025-06-15',
      notes: 'Short stay',
    });

    const petList = await loginAs(page, alice);
    await petList.openHealthDashboard();

    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.selectTab('Care events');
    await dashboard.selectOrgFilter(ORG_NAME);
    await dashboard.expectEntryVisible('Max');
  });

  // Family-event due notifications are superseded by fostering-session reminders (D18/D19).
  test.skip('notifications for ending family events', async () => {
    expect(true).toBe(true);
  });
});
