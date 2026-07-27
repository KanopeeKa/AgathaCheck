/**
 * @bdd foster_onboarding.feature
 * Scenario: Opening Manage Fosters from organisation menu
 * Scenario: Viewing fosters currently fostering
 * Scenario: Adding a foster manually
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { ManageFostersPage } from '../pages/manage-fosters.page';
import { OrganizationDetailPage } from '../pages/organization-detail.page';
import { OrganizationListPage } from '../pages/organization-list.page';
import {
  acceptFosterPlacement,
  createFosterPlacement,
  createOrgPet,
  seedRescueHearts,
  type TestUser,
} from '../support/api';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

async function openRescueHearts(
  page: import('@playwright/test').Page,
  user: TestUser,
  orgId: string,
) {
  const petList = await loginAs(page, user);
  await petList.openOrganizations();
  const orgList = new OrganizationListPage(page);
  await orgList.openOrg('Rescue Hearts', orgId);
  const detail = new OrganizationDetailPage(page);
  await detail.expectLoaded('Rescue Hearts');
  return detail;
}

test.describe('Foster onboarding and approval', () => {
  test('opening manage fosters from organisation menu', async ({ page }) => {
    const { alice, org } = await seedRescueHearts(baseURL());
    const detail = await openRescueHearts(page, alice, org.id);
    await detail.openManageFosters();
    const fosters = new ManageFostersPage(page);
    await fosters.expectLoaded();
  });

  test('viewing fosters currently fostering', async ({ page }) => {
    const { alice, eve, org } = await seedRescueHearts(baseURL());
    const pet = await createOrgPet(baseURL(), alice.accessToken, org.id, {
      name: 'Max',
      species: 'dog',
    });
    const placement = await createFosterPlacement(
      baseURL(),
      alice.accessToken,
      org.id,
      pet.id,
      eve.userId,
    );
    await acceptFosterPlacement(baseURL(), eve.accessToken, placement.id);

    const detail = await openRescueHearts(page, alice, org.id);
    await detail.openManageFosters();
    const fosters = new ManageFostersPage(page);
    await fosters.expectLoaded();
    await fosters.selectTab('Fostering');
    await fosters.expectFosterVisible('Eve');
  });

  test('adding a foster manually', async ({ page }) => {
    const { alice, org } = await seedRescueHearts(baseURL());
    const detail = await openRescueHearts(page, alice, org.id);
    await detail.openManageFosters();
    const fosters = new ManageFostersPage(page);
    await fosters.expectLoaded();
    const email = `bob-${Date.now()}@example.com`;
    await fosters.addManualFoster('Bob', email);
    await fosters.expectFosterVisible('Bob');
  });
});
