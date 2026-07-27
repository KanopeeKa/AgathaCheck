/**
 * @bdd org_foster_and_adoption.feature
 * @bdd org_to_org_transfer.feature
 * @bdd org_pet_return.feature
 * @bdd pet_ownership_and_adoption.feature
 * Scenario: Foster placement gives Eve care while Rescue Hearts keeps guardianship
 * Scenario: Direct adoption requires foster confirmation
 * Scenario: Org admin hides a fostered pet from their home list only
 * Scenario: Fosterer hides a fostered pet from notifications and health dashboard
 * Scenario: Hide is cleared when foster ends
 * Scenario: Connected orgs can transfer a pet with recipient acceptance
 * Scenario: Org transfer requires an active connection
 * Scenario: Disconnecting orgs cancels pending transfers between them
 * Scenario: Individual guardian returns an adopted pet to Rescue Hearts
 * Scenario: Receiving org returns a transferred pet to the sending org
 * Scenario: Sharing an organisation pet with a prospective adopter
 * Scenario: Viewing frozen shadow after adoption leaves the org
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  acceptFosterPlacement,
  acceptCustodyTransfer,
  confirmAdoption,
  connectOrganizations,
  createFosterPlacement,
  createHealthEntry,
  createOrgPet,
  createOrganization,
  createShareLink,
  disconnectOrgs,
  endFosterPlacement,
  getAllPets,
  getHealthEntries,
  getOrgArchivedPets,
  getPendingAdoptions,
  getPendingCustodyTransfers,
  getPendingFosterPlacements,
  getPet,
  getUnreadNotificationCount,
  hideFosteredPet,
  hideOrgPetFromHome,
  initiateDirectAdoption,
  requestOrgToOrgTransfer,
  requestPetReturn,
  seedActiveFosterPlacement,
  seedRescueHearts,
  signupUser,
  type TestOrganization,
  type TestUser,
  triggerCheckDueNotifications,
  tryRequestCustodyTransfer,
} from '../support/api';
import { HealthDashboardPage } from '../pages/health-dashboard.page';
import { OrganizationDetailPage } from '../pages/organization-detail.page';
import { OrganizationListPage } from '../pages/organization-list.page';
import { PetListPage } from '../pages/pet-list.page';
import { SharedPetPage } from '../pages/shared-pet.page';
import { reachAuthenticatedHome } from '../support/flutter';

const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';

function isoDay(offsetDays: number): string {
  const date = new Date();
  date.setDate(date.getDate() + offsetDays);
  return date.toISOString().slice(0, 10);
}

async function openOrganization(
  page: import('@playwright/test').Page,
  user: TestUser,
  orgName: string,
  orgId: string,
) {
  const petList = await loginAs(page, user);
  await petList.openOrganizations();
  const orgList = new OrganizationListPage(page);
  await orgList.openOrg(orgName, orgId);
  const detail = new OrganizationDetailPage(page);
  await detail.expectLoaded(orgName);
  return detail;
}

async function seedConnectedOrganizations() {
  const alice = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Rescue' });
  const bob = await signupUser(baseURL, { firstName: 'Bob', lastName: 'Partner' });
  const rescue = await createOrganization(baseURL, alice.accessToken, {
    name: 'Rescue Hearts',
    type: 'charity',
  });
  const partner = await createOrganization(baseURL, bob.accessToken, {
    name: 'Partner Shelter',
    type: 'charity',
  });
  await connectOrganizations(baseURL, alice.accessToken, rescue.id, partner.id, bob.accessToken);
  return { alice, bob, rescue, partner };
}

async function adoptToUser(
  alice: TestUser,
  eve: TestUser,
  org: Pick<TestOrganization, 'id'>,
  petName = 'Max',
) {
  const pet = await createOrgPet(baseURL, alice.accessToken, org.id, {
    name: petName,
    species: 'dog',
  });
  const placement = await initiateDirectAdoption(
    baseURL,
    alice.accessToken,
    org.id,
    pet.id,
    eve.userId,
  );
  await confirmAdoption(baseURL, eve.accessToken, placement.id);
  return { pet, placement };
}

test.describe('Organisation custody', () => {
  test('foster placement gives Eve care while Rescue Hearts keeps guardianship', async ({ page }) => {
    const { alice, eve, org } = await seedRescueHearts(baseURL);
    const pet = await createOrgPet(baseURL, alice.accessToken, org.id, {
      name: 'Max',
      species: 'dog',
    });
    const placement = await createFosterPlacement(
      baseURL,
      alice.accessToken,
      org.id,
      pet.id,
      eve.userId,
    );

    const pending = await getPendingFosterPlacements(baseURL, eve.accessToken);
    expect(pending.some((row) => row.id === placement.id)).toBe(true);
    await acceptFosterPlacement(baseURL, eve.accessToken, placement.id);

    const fosteredPet = await getPet(baseURL, eve.accessToken, pet.id);
    expect(fosteredPet.organization_id).toBe(org.id);
    expect(fosteredPet.organization_name).toBe('Rescue Hearts');
    expect(fosteredPet.is_foster).toBe(true);

    const eveList = await loginAs(page, eve);
    await eveList.expectPetVisible('Max');
    const aliceList = await loginAs(page, alice);
    await aliceList.expectPetUnderOrganization('Max', 'Rescue Hearts');
  });

  test('direct adoption requires foster confirmation', async ({ page }) => {
    const { alice, eve, org } = await seedRescueHearts(baseURL);
    const pet = await createOrgPet(baseURL, alice.accessToken, org.id, {
      name: 'Max',
      species: 'dog',
    });
    const placement = await initiateDirectAdoption(
      baseURL,
      alice.accessToken,
      org.id,
      pet.id,
      eve.userId,
    );

    const pending = await getPendingAdoptions(baseURL, eve.accessToken);
    expect(pending.some((row) => row.id === placement.id)).toBe(true);

    await confirmAdoption(baseURL, eve.accessToken, placement.id);

    const eveList = await loginAs(page, eve);
    await eveList.expectPetVisible('Max');

    const adoptedPet = await getPet(baseURL, eve.accessToken, pet.id);
    expect(adoptedPet.organization_id).toBeNull();
    expect(adoptedPet.user_id).toBe(eve.userId);

    const rescuePets = await getAllPets(baseURL, alice.accessToken);
    expect(rescuePets.some((row) => row.id === pet.id)).toBe(false);

    const archived = await getOrgArchivedPets(baseURL, alice.accessToken, org.id);
    expect(archived.some((row) => row.pet_name === 'Max' && row.shadow_snapshot)).toBe(true);
  });

  test('org admin hides a fostered pet from their home list only', async ({ page, request }) => {
    const { alice, eve, org } = await seedRescueHearts(baseURL);
    const { pet } = await seedActiveFosterPlacement(baseURL, alice, eve, org, 'Max');

    const petList = await loginAs(page, alice, { experience: 'organization' });
    await petList.expectPetUnderOrganization('Max', 'Rescue Hearts');
    await hideOrgPetFromHome(baseURL, alice.accessToken, org.id, pet.id);

    // API hide does not invalidate in-memory petListProvider — reload like fosterer hide test.
    await page.reload();
    await reachAuthenticatedHome(page, { experience: 'organization' });
    await petList.expectLoaded();
    await petList.expectPetHidden('Max');

    const detail = await openOrganization(page, alice, 'Rescue Hearts', org.id);
    await detail.expectPetVisible('Max');

    const hiddenResponse = await request.get(`/backend/api/organizations/${org.id}/home-hidden`, {
      headers: { Authorization: `Bearer ${alice.accessToken}` },
    });
    expect(hiddenResponse.ok()).toBe(true);
    const hiddenPets = await hiddenResponse.json();
    expect(hiddenPets.some((row: { pet_id: string }) => row.pet_id === pet.id)).toBe(true);
  });

  test('fosterer hides a fostered pet from notifications and health dashboard', async ({ page }) => {
    const { alice, eve, org } = await seedRescueHearts(baseURL);
    const { pet } = await seedActiveFosterPlacement(baseURL, alice, eve, org, 'Max');
    const visibleEntry = 'Foster Follow-up';

    await createHealthEntry(baseURL, eve.accessToken, pet.id, {
      name: visibleEntry,
      type: 'preventive',
      nextDueDate: isoDay(-1),
    });

    const petList = await loginAs(page, eve, { experience: 'guardian' });
    await petList.openHealthDashboard({ experience: 'guardian' });
    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.expectEntryVisible(visibleEntry);

    await hideFosteredPet(baseURL, eve.accessToken, pet.id);
    await page.reload();
    await reachAuthenticatedHome(page, { experience: 'guardian' });
    await petList.expectLoaded();
    await petList.expectPetHidden('Max');

    await petList.openHealthDashboard({ experience: 'guardian' });
    await dashboard.expectLoaded();
    await dashboard.expectEntryNotVisible(visibleEntry);

    const unreadBefore = await getUnreadNotificationCount(baseURL, eve.accessToken);
    await triggerCheckDueNotifications(baseURL, eve.accessToken);
    expect(await getUnreadNotificationCount(baseURL, eve.accessToken)).toBe(unreadBefore);
  });

  test('hide is cleared when foster ends', async ({ page, request }) => {
    const { alice, eve, org } = await seedRescueHearts(baseURL);
    const { pet, placement } = await seedActiveFosterPlacement(baseURL, alice, eve, org, 'Max');

    const petList = await loginAs(page, alice);
    await petList.expectPetUnderOrganization('Max', 'Rescue Hearts');
    await hideOrgPetFromHome(baseURL, alice.accessToken, org.id, pet.id);

    const hiddenBefore = await request.get(`/backend/api/organizations/${org.id}/home-hidden`, {
      headers: { Authorization: `Bearer ${alice.accessToken}` },
    });
    expect(hiddenBefore.ok()).toBe(true);
    expect((await hiddenBefore.json()).some((row: { pet_id: string }) => row.pet_id === pet.id)).toBe(
      true,
    );

    await endFosterPlacement(baseURL, alice.accessToken, org.id, placement.id);
    await petList.goHome();
    await petList.expectPetUnderOrganization('Max', 'Rescue Hearts');

    const hiddenAfter = await request.get(`/backend/api/organizations/${org.id}/home-hidden`, {
      headers: { Authorization: `Bearer ${alice.accessToken}` },
    });
    expect(hiddenAfter.ok()).toBe(true);
    expect((await hiddenAfter.json()).some((row: { pet_id: string }) => row.pet_id === pet.id)).toBe(
      false,
    );

    const restoredPet = await getPet(baseURL, alice.accessToken, pet.id);
    expect(restoredPet.is_foster).toBe(false);
  });

  test('connected orgs can transfer a pet with recipient acceptance', async ({ page }) => {
    const { alice, bob, rescue, partner } = await seedConnectedOrganizations();
    const pet = await createOrgPet(baseURL, alice.accessToken, rescue.id, {
      name: 'Max',
      species: 'dog',
    });
    await requestOrgToOrgTransfer(baseURL, alice.accessToken, rescue.id, pet.id, partner.id);

    const pending = await getPendingCustodyTransfers(baseURL, bob.accessToken);
    expect(pending.some((row) => row.pet_name === 'Max')).toBe(true);

    const transfer = pending.find((row) => row.pet_name === 'Max');
    expect(transfer).toBeTruthy();
    await acceptCustodyTransfer(baseURL, bob.accessToken, transfer!.id);

    const bobList = await loginAs(page, bob);
    await bobList.expectPetUnderOrganization('Max', 'Partner Shelter');

    const transferredPet = await getPet(baseURL, bob.accessToken, pet.id);
    expect(transferredPet.organization_id).toBe(partner.id);
    expect(transferredPet.organization_name).toBe('Partner Shelter');

    const archived = await getOrgArchivedPets(baseURL, alice.accessToken, rescue.id);
    expect(archived.some((row) => row.pet_name === 'Max' && row.shadow_snapshot)).toBe(true);
  });

  test('org transfer requires an active connection', async () => {
    const alice = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Rescue' });
    const bob = await signupUser(baseURL, { firstName: 'Bob', lastName: 'Partner' });
    const rescue = await createOrganization(baseURL, alice.accessToken, {
      name: 'Rescue Hearts',
      type: 'charity',
    });
    const partner = await createOrganization(baseURL, bob.accessToken, {
      name: 'Partner Shelter',
      type: 'charity',
    });
    const pet = await createOrgPet(baseURL, alice.accessToken, rescue.id, {
      name: 'Max',
      species: 'dog',
    });

    const result = await tryRequestCustodyTransfer(baseURL, alice.accessToken, rescue.id, pet.id, {
      transfer_kind: 'org_to_org',
      to_org_id: partner.id,
    });

    expect(result.ok).toBe(false);
    expect(result.status).toBeGreaterThanOrEqual(400);
    expect(JSON.stringify(result.body).toLowerCase()).toMatch(/connect/);

    const pending = await getPendingCustodyTransfers(baseURL, bob.accessToken);
    expect(pending.some((row) => row.pet_name === 'Max')).toBe(false);
  });

  test('disconnecting orgs cancels pending transfers between them', async () => {
    const { alice, bob, rescue, partner } = await seedConnectedOrganizations();
    const pet = await createOrgPet(baseURL, alice.accessToken, rescue.id, {
      name: 'Max',
      species: 'dog',
    });
    const transfer = await requestOrgToOrgTransfer(
      baseURL,
      alice.accessToken,
      rescue.id,
      pet.id,
      partner.id,
    );

    const pendingBefore = await getPendingCustodyTransfers(baseURL, bob.accessToken);
    expect(pendingBefore.some((row) => row.id === transfer.id)).toBe(true);

    await disconnectOrgs(baseURL, alice.accessToken, rescue.id, partner.id);

    const pendingAfter = await getPendingCustodyTransfers(baseURL, bob.accessToken);
    expect(pendingAfter.some((row) => row.id === transfer.id)).toBe(false);
  });

  test('individual guardian returns an adopted pet to Rescue Hearts', async ({ page }) => {
    const { alice, eve, org } = await seedRescueHearts(baseURL);
    const { pet } = await adoptToUser(alice, eve, org, 'Max');
    const entryName = 'Return Check';

    await createHealthEntry(baseURL, eve.accessToken, pet.id, {
      name: entryName,
      type: 'vet_visit',
      nextDueDate: isoDay(0),
    });
    await requestPetReturn(baseURL, eve.accessToken, pet.id, org.id);

    const pending = await getPendingCustodyTransfers(baseURL, alice.accessToken);
    expect(pending.some((row) => row.pet_name === 'Max')).toBe(true);

    const transfer = pending.find((row) => row.pet_name === 'Max');
    expect(transfer).toBeTruthy();
    await acceptCustodyTransfer(baseURL, alice.accessToken, transfer!.id);

    const aliceList = await loginAs(page, alice);
    await aliceList.expectPetUnderOrganization('Max', 'Rescue Hearts');

    const returnedPet = await getPet(baseURL, alice.accessToken, pet.id);
    expect(returnedPet.organization_id).toBe(org.id);

    const archived = await getOrgArchivedPets(baseURL, alice.accessToken, org.id);
    expect(archived.some((row) => row.pet_name === 'Max')).toBe(false);

    const healthEntries = await getHealthEntries(baseURL, alice.accessToken);
    expect(healthEntries.some((row) => row.name === entryName)).toBe(true);
  });

  test('receiving org returns a transferred pet to the sending org', async ({ page }) => {
    const { alice, bob, rescue, partner } = await seedConnectedOrganizations();
    const pet = await createOrgPet(baseURL, alice.accessToken, rescue.id, {
      name: 'Max',
      species: 'dog',
    });
    await requestOrgToOrgTransfer(baseURL, alice.accessToken, rescue.id, pet.id, partner.id);
    const pendingForBob = await getPendingCustodyTransfers(baseURL, bob.accessToken);
    const transfer = pendingForBob.find((row) => row.pet_name === 'Max');
    expect(transfer).toBeTruthy();
    await acceptCustodyTransfer(baseURL, bob.accessToken, transfer!.id);

    await requestPetReturn(baseURL, bob.accessToken, pet.id, rescue.id);

    const pendingReturn = await getPendingCustodyTransfers(baseURL, alice.accessToken);
    const returnTransfer = pendingReturn.find((row) => row.pet_name === 'Max');
    expect(returnTransfer).toBeTruthy();
    await acceptCustodyTransfer(baseURL, alice.accessToken, returnTransfer!.id);

    const aliceList = await loginAs(page, alice);
    await aliceList.expectPetUnderOrganization('Max', 'Rescue Hearts');

    const returnedPet = await getPet(baseURL, alice.accessToken, pet.id);
    expect(returnedPet.organization_id).toBe(rescue.id);

    const archived = await getOrgArchivedPets(baseURL, alice.accessToken, rescue.id);
    expect(archived.some((row) => row.pet_name === 'Max')).toBe(false);
  });

  test('sharing an organisation pet with a prospective adopter', async ({ page }) => {
    const alice = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Sharer' });
    const eve = await signupUser(baseURL, { firstName: 'Eve', lastName: 'Adopter' });
    const org = await createOrganization(baseURL, alice.accessToken, {
      name: 'Rescue Hearts',
      type: 'charity',
    });
    const pet = await createOrgPet(baseURL, alice.accessToken, org.id, {
      name: 'Max',
      species: 'dog',
    });
    const share = await createShareLink(baseURL, alice.accessToken, pet.id);

    await loginAs(page, eve);
    const shared = new SharedPetPage(page);
    await shared.goto(share.share_code);
    await shared.expectLoaded('Max');
    await shared.acceptShare();

    const petList = new PetListPage(page);
    await petList.expectLoaded();
    await petList.expectPetVisible('Max');
    await expect(page.getByText('Share accepted')).toBeVisible();

    const sharedPet = await getPet(baseURL, alice.accessToken, pet.id);
    expect(sharedPet.organization_id).toBe(org.id);

    const entryName = 'Shared Check';
    await createHealthEntry(baseURL, eve.accessToken, pet.id, {
      name: entryName,
      type: 'preventive',
      nextDueDate: isoDay(2),
    });
    const eveEntries = await getHealthEntries(baseURL, eve.accessToken);
    expect(eveEntries.some((row) => row.name === entryName)).toBe(true);
  });

  test('viewing frozen shadow after adoption leaves the org', async ({ page }) => {
    const { alice, eve, org } = await seedRescueHearts(baseURL);
    const { pet } = await adoptToUser(alice, eve, org, 'Max');

    const archivedBefore = await getOrgArchivedPets(baseURL, alice.accessToken, org.id);
    const shadowBefore = archivedBefore.find((row) => row.pet_name === 'Max');
    expect(shadowBefore?.shadow_snapshot).toBeTruthy();

    await createHealthEntry(baseURL, eve.accessToken, pet.id, {
      name: 'Post Adoption Check',
      type: 'preventive',
      nextDueDate: isoDay(1),
    });

    const archivedAfter = await getOrgArchivedPets(baseURL, alice.accessToken, org.id);
    const shadowAfter = archivedAfter.find((row) => row.pet_name === 'Max');
    expect(shadowAfter?.shadow_snapshot).toEqual(shadowBefore?.shadow_snapshot);

    const detail = await openOrganization(page, alice, 'Rescue Hearts', org.id);
    await detail.openArchivedPets();
    await expect(page.locator('body')).toContainText(/Max,\s*dog,\s*Adoption/i);
    await expect(page.locator('body')).not.toContainText('Post Adoption Check');
  });
});
