/**
 * @bdd org_foster_and_adoption.feature
 * @bdd org_to_org_transfer.feature
 * @bdd pet_ownership_and_adoption.feature
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  acceptOrgConnectionRequest,
  createOrgConnectionRequest,
  createOrgPet,
  createOrganization,
  getOrgArchivedPets,
  getPendingCustodyTransfers,
  signupUser,
  transferOrgPetToUser,
} from '../support/api';
import { OrganizationDetailPage } from '../pages/organization-detail.page';
import { PetListPage } from '../pages/pet-list.page';

test.describe('Organisation custody', () => {
  test('org admin sees connected organisations section', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const org = await createOrganization(baseURL, testUser.accessToken, {
      name: 'Rescue Hearts',
      type: 'charity',
    });

    const petList = await loginAs(page, testUser);
    await petList.openOrganizations();
    await page.getByText('Rescue Hearts', { exact: true }).first().click();

    const detail = new OrganizationDetailPage(page);
    await detail.expectLoaded('Rescue Hearts');
    await page.getByText('Connected organisations').waitFor({ timeout: 30_000 });
  });

  test('recipient accepts pending individual custody transfer', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const recipient = await signupUser(baseURL, {
      firstName: 'Eve',
      lastName: 'Adopter',
      email: `eve-${Date.now()}@example.com`,
    });
    const org = await createOrganization(baseURL, testUser.accessToken, {
      name: 'Rescue Hearts Custody',
      type: 'charity',
    });
    const pet = await createOrgPet(baseURL, testUser.accessToken, org.id, {
      name: 'Max',
      species: 'dog',
    });
    await transferOrgPetToUser(
      baseURL,
      testUser.accessToken,
      org.id,
      pet.id,
      recipient.email,
    );

    const pending = await getPendingCustodyTransfers(baseURL, recipient.accessToken);
    expect(pending.length).toBeGreaterThan(0);

    const petList = await loginAs(page, recipient);
    await petList.expectLoaded();
    await page.getByText('Pending custody transfers').waitFor({ timeout: 30_000 });
    await page.getByRole('button', { name: 'Accept transfer' }).first().click();
    await page.getByText('Custody transfer accepted').waitFor({ timeout: 30_000 });

    const archived = await getOrgArchivedPets(baseURL, testUser.accessToken, org.id);
    expect(archived.some((row) => row.pet_name === 'Max')).toBeTruthy();
  });

  test('orgs connect via token and admin sees peer', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const partnerAdmin = await signupUser(baseURL, {
      firstName: 'Bob',
      lastName: 'Partner',
      email: `bob-${Date.now()}@example.com`,
    });
    const rescue = await createOrganization(baseURL, testUser.accessToken, {
      name: 'Rescue Hearts Link',
      type: 'charity',
    });
    const partner = await createOrganization(baseURL, partnerAdmin.accessToken, {
      name: 'Partner Shelter',
      type: 'charity',
    });

    const { token } = await createOrgConnectionRequest(
      baseURL,
      testUser.accessToken,
      rescue.id,
      partner.id,
    );
    await acceptOrgConnectionRequest(baseURL, partnerAdmin.accessToken, token);

    const petList = await loginAs(page, testUser);
    await petList.openOrganizations();
    await page.getByText('Rescue Hearts Link', { exact: true }).first().click();
    await page.getByText('Connected organisations').click();
    await page.getByText('Partner Shelter').waitFor({ timeout: 30_000 });
  });
});
