/**
 * @bdd organisation_management.feature
 * Scenario: Creating a Professional organisation
 * Scenario: Creating a Charity organisation
 * Scenario: Organisation requires a name
 * Scenario: Inviting a volunteer as a member
 * Scenario: Accepting an organisation invite
 * Scenario: Declining an organisation invite
 * Scenario: Inviting a user as a super user
 * Scenario: Only super users can invite new members
 * Scenario: Viewing organisation details
 * Scenario: Viewing organisation members from the dashboard
 * Scenario: Updating organisation information
 * Scenario: Leaving an organisation
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  acceptInvite,
  createOrganization,
  declineInvite,
  getOrgMembers,
  getOrganizations,
  getPendingInvites,
  inviteToOrganization,
  seedOrgWithMember,
  signupUser,
} from '../support/api';
import { checkA11y } from '../support/axe';
import { OrganizationDetailPage } from '../pages/organization-detail.page';
import { OrganizationFormPage } from '../pages/organization-form.page';
import { OrganizationListPage } from '../pages/organization-list.page';
import { PetListPage } from '../pages/pet-list.page';

test.describe('Organisation management', () => {
  test('user can create a Professional organisation', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const petList = await loginAs(page, testUser);
    await petList.openOrganizations();

    const orgList = new OrganizationListPage(page);
    await orgList.expectLoaded();
    await orgList.openCreateForm();

    const form = new OrganizationFormPage(page);
    await form.createOrganization('Happy Paws Clinic', 'Professional');

    const detail = new OrganizationDetailPage(page);
    await detail.expectLoaded('Happy Paws Clinic');

    const orgs = await getOrganizations(baseURL, testUser.accessToken);
    const created = orgs.find((org) => org.name === 'Happy Paws Clinic');
    expect(created).toBeTruthy();
    expect(created?.type).toBe('professional');
    expect(created?.role).toBe('super_admin');

    await checkA11y(page, 'organization detail');
  });

  test('user can create a Charity organisation', async ({ page, testUser }) => {
    const petList = await loginAs(page, testUser);
    await petList.openOrganizations();

    const orgList = new OrganizationListPage(page);
    await orgList.openCreateForm();

    const form = new OrganizationFormPage(page);
    await form.createOrganization('Rescue Hearts', 'Charity');

    const detail = new OrganizationDetailPage(page);
    await detail.expectLoaded('Rescue Hearts');
  });

  test('organisation form requires a name', async ({ page, testUser }) => {
    const petList = await loginAs(page, testUser);
    await petList.openOrganizations();

    const orgList = new OrganizationListPage(page);
    await orgList.openCreateForm();

    const form = new OrganizationFormPage(page);
    await form.attemptSaveWithoutName();
    await form.expectNameRequiredError();
  });

  test('super user can invite and member can accept an organisation invite', async ({
    page,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const alice = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
    const bob = await signupUser(baseURL, { firstName: 'Bob', lastName: 'Member' });
    const org = await createOrganization(baseURL, alice.accessToken, {
      name: 'Happy Paws Clinic',
    });

    await loginAs(page, alice);
    const petList = new PetListPage(page);
    await petList.openOrganizations();

    const orgList = new OrganizationListPage(page);
    await orgList.openOrg('Happy Paws Clinic', org.id);

    const detail = new OrganizationDetailPage(page);
    await detail.inviteMember(bob.email, 'Admin');

    const invites = await getPendingInvites(baseURL, bob.accessToken);
    expect(invites.some((invite) => invite.organization_id === org.id)).toBe(true);

    await loginAs(page, bob);
    await petList.openOrganizations();
    await orgList.acceptInviteForOrg('Happy Paws Clinic');
    await orgList.expectOrgVisible('Happy Paws Clinic');
    await orgList.expectNoPendingInvite('Happy Paws Clinic');
  });

  test('user can decline an organisation invite', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const alice = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
    const bob = await signupUser(baseURL, { firstName: 'Bob', lastName: 'Member' });
    const org = await createOrganization(baseURL, alice.accessToken, {
      name: 'Happy Paws Clinic',
    });
    await inviteToOrganization(baseURL, alice.accessToken, org.id, {
      email: bob.email,
      role: 'member',
    });

    const petList = await loginAs(page, bob);
    await petList.openOrganizations();

    const orgList = new OrganizationListPage(page);
    await orgList.declineInviteForOrg('Happy Paws Clinic');
    await orgList.expectNoPendingInvite('Happy Paws Clinic');

    const orgs = await getOrganizations(baseURL, bob.accessToken);
    expect(orgs.some((item) => item.id === org.id)).toBe(false);
  });

  test('super user can invite another super user', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const alice = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
    const carol = await signupUser(baseURL, { firstName: 'Carol', lastName: 'Admin' });
    const org = await createOrganization(baseURL, alice.accessToken, { name: 'Happy Paws Clinic' });

    await loginAs(page, alice);
    const petList = new PetListPage(page);
    await petList.openOrganizations();

    const orgList = new OrganizationListPage(page);
    await orgList.openOrg('Happy Paws Clinic', org.id);

    const detail = new OrganizationDetailPage(page);
    await detail.inviteMember(carol.email, 'Super admin');

    const invites = await getPendingInvites(baseURL, carol.accessToken);
    const invite = invites.find((item) => item.organization_name === 'Happy Paws Clinic');
    expect(invite).toBeTruthy();
    await acceptInvite(baseURL, carol.accessToken, invite!.id);

    const orgs = await getOrganizations(baseURL, carol.accessToken);
    expect(orgs.find((item) => item.name === 'Happy Paws Clinic')?.role).toBe('super_admin');
  });

  test('non-admin members cannot invite new members', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const alice = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
    const bob = await signupUser(baseURL, { firstName: 'Bob', lastName: 'Foster' });
    const org = await createOrganization(baseURL, alice.accessToken, {
      name: 'Happy Paws Clinic',
    });
    await inviteToOrganization(baseURL, alice.accessToken, org.id, {
      email: bob.email,
      role: 'foster',
    });
    const invites = await getPendingInvites(baseURL, bob.accessToken);
    await acceptInvite(baseURL, bob.accessToken, invites[0].id);

    await loginAs(page, bob);
    const petList = new PetListPage(page);
    await petList.openOrganizations();

    const orgList = new OrganizationListPage(page);
    await orgList.openOrg('Happy Paws Clinic', org.id);

    const detail = new OrganizationDetailPage(page);
    await detail.expectInviteMenuHidden();
  });

  test('super user can view organisation details with members', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const alice = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
    const bob = await signupUser(baseURL, { firstName: 'Bob', lastName: 'Member' });
    const org = await seedOrgWithMember(baseURL, alice, bob, 'Happy Paws Clinic');

    await loginAs(page, alice);
    const petList = new PetListPage(page);
    await petList.openOrganizations();

    const orgList = new OrganizationListPage(page);
    await orgList.openOrg('Happy Paws Clinic', org.id);

    const detail = new OrganizationDetailPage(page);
    await detail.expectLoaded('Happy Paws Clinic');
    await detail.expectMemberVisible('Bob');
  });

  test('@legacy @P1 super user can list organisation members from API', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const alice = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
    const bob = await signupUser(baseURL, { firstName: 'Bob', lastName: 'Member' });
    const org = await seedOrgWithMember(baseURL, alice, bob, 'Happy Paws Clinic');

    const members = await getOrgMembers(baseURL, alice.accessToken, org.id);
    expect(members.length).toBe(2);
    expect(members.some((m) => m.email === bob.email)).toBe(true);
  });

  test('super user can update organisation bio', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const alice = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
    const org = await createOrganization(baseURL, alice.accessToken, { name: 'Happy Paws Clinic' });

    await loginAs(page, alice);
    const petList = new PetListPage(page);
    await petList.openOrganizations();

    const orgList = new OrganizationListPage(page);
    await orgList.openOrg('Happy Paws Clinic', org.id);

    const detail = new OrganizationDetailPage(page);
    await detail.openEdit();

    const form = new OrganizationFormPage(page);
    await form.updateBio('Full-service veterinary clinic');

    await detail.expectLoaded('Happy Paws Clinic');
    await detail.expectBio('Full-service veterinary clinic');
  });

  test('member can leave an organisation', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const alice = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
    const bob = await signupUser(baseURL, { firstName: 'Bob', lastName: 'Member' });
    const org = await seedOrgWithMember(baseURL, alice, bob, 'Happy Paws Clinic');

    await loginAs(page, bob);
    const petList = new PetListPage(page);
    await petList.openOrganizations();

    const orgList = new OrganizationListPage(page);
    await orgList.openOrg('Happy Paws Clinic', org.id);

    const detail = new OrganizationDetailPage(page);
    await detail.leaveOrganization();

    await orgList.expectLoaded();
    const orgs = await getOrganizations(baseURL, bob.accessToken);
    expect(orgs.some((org) => org.name === 'Happy Paws Clinic')).toBe(false);
  });
});
