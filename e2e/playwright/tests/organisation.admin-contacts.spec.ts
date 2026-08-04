/**
 * @bdd admin_contacts.feature
 * Scenario: Admin contacts directory lists admins alphabetically
 * Scenario: Team admin can add an admin contact
 * Scenario: Super admin can edit another admin contact
 * Scenario: Members can message an admin when contact details allow
 * Scenario: Member sees admin contacts preview on organisation profile
 * Scenario: Member sees connected organisation tiles on profile
 * Scenario: Team admin sees manage connections entry on profile
 */
import { test, expect } from '../fixtures/auth.fixture';
import {
  addMemberToOrg,
  connectOrganizations,
  createOrganization,
  getOrgConnections,
  getOrgPeople,
  getOrgPermissionsMe,
  getPendingInvites,
  inviteToOrganization,
  signupUser,
  updateOrgPersonContact,
} from '../support/api';

const ORG_NAME = 'Rescue Hearts';

async function seedRescueHearts(baseURL: string) {
  const alice = await signupUser(baseURL, {
    firstName: 'Alice',
    lastName: 'Alpha',
    email: `alice-${Date.now()}@example.com`,
  });
  const org = await createOrganization(baseURL, alice.accessToken, {
    name: ORG_NAME,
    type: 'charity',
  });
  return { alice, org };
}

test.describe('Admin contacts', () => {
  test('@P1 people directory lists admins with self-card first then alphabetical', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org } = await seedRescueHearts(baseURL);
    const bob = await signupUser(baseURL, {
      firstName: 'Bob',
      lastName: 'Bravo',
      email: `bob-${Date.now()}@example.com`,
    });
    const carol = await signupUser(baseURL, {
      firstName: 'Carol',
      lastName: 'Charlie',
      email: `carol-${Date.now()}@example.com`,
    });
    await addMemberToOrg(baseURL, alice.accessToken, org.id, bob, 'admin');
    await addMemberToOrg(baseURL, alice.accessToken, org.id, carol, 'admin');

    const people = await getOrgPeople(baseURL, alice.accessToken, org.id);
    const admins = people.filter(
      (p) =>
        p.kind === 'member' &&
        (p.role === 'admin' || p.role === 'super_admin'),
    );
    expect(admins.length).toBeGreaterThanOrEqual(3);
    expect(admins[0].display_name).toContain('Alice');
    const afterSelf = admins.slice(1).map((p) => p.display_name);
    const sorted = [...afterSelf].sort((a, b) => a.localeCompare(b));
    expect(afterSelf).toEqual(sorted);
  });

  test('@P1 team admin invite creates pending admin membership', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org } = await seedRescueHearts(baseURL);
    const dave = await signupUser(baseURL, {
      firstName: 'Dave',
      lastName: 'Delta',
      email: `dave-${Date.now()}@example.com`,
    });

    await inviteToOrganization(baseURL, alice.accessToken, org.id, {
      email: dave.email,
      role: 'admin',
    });

    const invites = await getPendingInvites(baseURL, dave.accessToken);
    const invite = invites.find((item) => item.organization_id === org.id);
    expect(invite).toBeTruthy();
    expect(invite?.desired_role).toMatch(/admin/);
  });

  test('@P1 super admin can update another admin contact details', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org } = await seedRescueHearts(baseURL);
    const eve = await signupUser(baseURL, {
      firstName: 'Eve',
      lastName: 'Echo',
      email: `eve-${Date.now()}@example.com`,
    });
    await addMemberToOrg(baseURL, alice.accessToken, org.id, eve, 'admin');

    const people = await getOrgPeople(baseURL, alice.accessToken, org.id);
    const eveRow = people.find((p) => p.user_id === eve.userId);
    expect(eveRow).toBeTruthy();

    const updated = await updateOrgPersonContact(
      baseURL,
      alice.accessToken,
      org.id,
      'member',
      eveRow!.record_id,
      { phone: '555-0100', notes: 'On-call admin' },
    );
    expect(String(updated.foster_phone ?? '')).toBe('555-0100');
  });

  test('@P1 foster member sees message affordance for admin with contact details', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org } = await seedRescueHearts(baseURL);
    const frank = await signupUser(baseURL, {
      firstName: 'Frank',
      lastName: 'Fox',
      email: `frank-${Date.now()}@example.com`,
    });
    const grace = await signupUser(baseURL, {
      firstName: 'Grace',
      lastName: 'Golf',
      email: `grace-${Date.now()}@example.com`,
    });
    await addMemberToOrg(baseURL, alice.accessToken, org.id, frank, 'foster');
    await addMemberToOrg(baseURL, alice.accessToken, org.id, grace, 'admin');

    const gracePeople = await getOrgPeople(baseURL, alice.accessToken, org.id);
    const graceRow = gracePeople.find((p) => p.user_id === grace.userId);
    expect(graceRow).toBeTruthy();
    await updateOrgPersonContact(
      baseURL,
      alice.accessToken,
      org.id,
      'member',
      graceRow!.record_id,
      { phone: '555-0200' },
    );

    const fosterView = await getOrgPeople(baseURL, frank.accessToken, org.id);
    const graceSummary = fosterView.find((p) => p.display_name.includes('Grace'));
    expect(graceSummary).toBeTruthy();
    expect(graceSummary?.email || graceSummary?.phone).toBeTruthy();
  });

  test('@P1 member can load admin contacts preview data for profile section', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org } = await seedRescueHearts(baseURL);
    const hank = await signupUser(baseURL, {
      firstName: 'Hank',
      lastName: 'Hotel',
      email: `hank-${Date.now()}@example.com`,
    });
    const ivy = await signupUser(baseURL, {
      firstName: 'Ivy',
      lastName: 'India',
      email: `ivy-${Date.now()}@example.com`,
    });
    await addMemberToOrg(baseURL, alice.accessToken, org.id, hank, 'foster');
    await addMemberToOrg(baseURL, alice.accessToken, org.id, ivy, 'admin');

    const preview = await getOrgPeople(baseURL, hank.accessToken, org.id);
    const ivyCard = preview.find((p) => p.display_name.includes('Ivy'));
    expect(ivyCard).toBeTruthy();
    expect(ivyCard?.role).toBe('admin');
  });

  test('@P1 member sees connected organisation in connections API', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org } = await seedRescueHearts(baseURL);
    const jill = await signupUser(baseURL, {
      firstName: 'Jill',
      lastName: 'Juliet',
      email: `jill-${Date.now()}@example.com`,
    });
    await addMemberToOrg(baseURL, alice.accessToken, org.id, jill, 'admin');

    const partnerOwner = await signupUser(baseURL, {
      firstName: 'Partner',
      lastName: 'Admin',
      email: `partner-${Date.now()}@example.com`,
    });
    const partnerOrg = await createOrganization(baseURL, partnerOwner.accessToken, {
      name: 'Partner Paws',
      type: 'charity',
    });
    await connectOrganizations(
      baseURL,
      alice.accessToken,
      org.id,
      partnerOrg.id,
      partnerOwner.accessToken,
    );

    const connections = await getOrgConnections(baseURL, jill.accessToken, org.id);
    expect(connections.some((c) => c.peer_org_name === 'Partner Paws')).toBe(true);
  });

  test('@P1 team admin has manage_members for connections entry on profile', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org } = await seedRescueHearts(baseURL);
    const ken = await signupUser(baseURL, {
      firstName: 'Ken',
      lastName: 'Kilo',
      email: `ken-${Date.now()}@example.com`,
    });
    await addMemberToOrg(baseURL, alice.accessToken, org.id, ken, 'admin');

    const perms = await getOrgPermissionsMe(baseURL, ken.accessToken, org.id);
    expect(perms.effective_permissions).toContain('manage_members');
    expect(perms.effective_permissions).toContain('view_connections');
  });
});
