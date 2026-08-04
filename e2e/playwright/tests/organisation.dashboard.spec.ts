/**
 * @bdd organisation_management.feature
 * Scenario: Dashboard shows Discover nav row instead of inline grid
 * Scenario: Discover nav row opens discover screen
 */
import { test, loginAs } from '../fixtures/auth.fixture';
import {
  createOrganization,
  setOrganizationDiscoveryProfile,
  signupUser,
} from '../support/api';
import { OrganizationDiscoverPage } from '../pages/organization-discover.page';
import { OrganizationListPage } from '../pages/organization-list.page';
import { PetListPage } from '../pages/pet-list.page';

test.describe('Organisation dashboard IA', () => {
  test('@P1 dashboard shows Discover nav row instead of inline grid', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await createOrganization(baseURL, testUser.accessToken, {
      name: 'Happy Paws Clinic',
      type: 'professional',
    });

    const petList = await loginAs(page, testUser);
    await petList.openOrganizations();

    const orgList = new OrganizationListPage(page);
    await orgList.expectLoaded();
    await orgList.expectDiscoverNavRowVisible();
    await orgList.expectNoInlineDiscoverTiles();
  });

  test('@P1 @smoke-ci @smoke-uat discover nav row opens discover screen', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const owner = await signupUser(baseURL, { firstName: 'Rescue', lastName: 'Admin' });
    const org = await createOrganization(baseURL, owner.accessToken, {
      name: 'Rescue Hearts',
      type: 'charity',
    });
    await setOrganizationDiscoveryProfile(baseURL, owner.accessToken, org, {
      town: 'Springfield',
      administrative_area: 'IL',
      description: 'A caring rescue shelter',
    });

    const alice = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Walker' });
    const petList = await loginAs(page, alice);
    await petList.openOrganizations();

    const orgList = new OrganizationListPage(page);
    await orgList.expectLoaded();
    await orgList.openDiscoverScreen();

    const discover = new OrganizationDiscoverPage(page);
    await discover.expectLoaded();
    await discover.expectOrgVisible('Rescue Hearts');
  });
});
