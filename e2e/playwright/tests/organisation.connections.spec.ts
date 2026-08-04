/**
 * @bdd organisation_discovery.feature
 * Scenario: Connections screen Discover CTA opens discover with org browse-as context
 * Scenario: Connections screen back returns to organisation profile
 */
import { test, loginAs } from '../fixtures/auth.fixture';
import {
  createOrganization,
  setOrganizationDiscoveryProfile,
  signupUser,
} from '../support/api';
import { OrganizationConnectionsPage } from '../pages/organization-connections.page';
import { OrganizationDetailPage } from '../pages/organization-detail.page';
import { OrganizationDiscoverPage } from '../pages/organization-discover.page';
import { OrganizationListPage } from '../pages/organization-list.page';
import { waitForFlutterRoute } from '../support/flutter';

test.describe('Organisation connections discover flow', () => {
  test('@P1 connections screen Discover CTA opens discover with org browse-as context', async ({
    page,
  }) => {
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
    const clinic = await createOrganization(baseURL, alice.accessToken, {
      name: 'Happy Paws Clinic',
      type: 'professional',
    });

    const petList = await loginAs(page, alice, { experience: 'organization' });
    await petList.openOrganizations();

    const orgList = new OrganizationListPage(page);
    await orgList.openOrg('Happy Paws Clinic', clinic.id);

    const detail = new OrganizationDetailPage(page);
    await detail.expectLoaded('Happy Paws Clinic');
    await detail.openConnectionsSection();

    const connections = new OrganizationConnectionsPage(page);
    await connections.expectLoaded();
    await connections.expectNoConnectButton();
    await connections.openDiscover();

    const discover = new OrganizationDiscoverPage(page);
    await discover.expectLoaded();
    await discover.expectBrowseAsOrg('Happy Paws Clinic');
    await discover.expectOrgVisible('Rescue Hearts');
  });

  test('@P1 connections screen back returns to organisation profile', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const alice = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Walker' });
    const clinic = await createOrganization(baseURL, alice.accessToken, {
      name: 'Happy Paws Clinic',
      type: 'professional',
    });

    await loginAs(page, alice, { experience: 'organization' });
    await waitForFlutterRoute(page, `/o/orgs/${clinic.id}/connections`);

    const connections = new OrganizationConnectionsPage(page);
    await connections.expectLoaded();
    await connections.goBack();

    const detail = new OrganizationDetailPage(page);
    await detail.expectLoaded('Happy Paws Clinic');
  });
});
