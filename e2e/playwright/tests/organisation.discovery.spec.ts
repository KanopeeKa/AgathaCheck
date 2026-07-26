/**
 * @bdd organisation_discovery.feature
 * Scenario: Discover Organisations is visible without signing in
 * Scenario: An organisation can opt out of discovery
 */
import { test, expect } from '../fixtures/auth.fixture';
import {
  createOrganization,
  discoverOrganizations,
  setOrganizationDiscoverability,
  setOrganizationDiscoveryProfile,
  signupUser,
} from '../support/api';

test.describe('Organisation discovery', () => {
  test('@P1 @smoke-ci @smoke-uat anonymous request returns discoverable organisation', async () => {
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
      logo_url: '/uploads/org_photos/rescue-hearts.png',
    });

    const discovery = await discoverOrganizations(baseURL);
    const match = discovery.items.find((item) => item.id === org.id);

    expect(match).toBeTruthy();
    expect(match?.name).toBe('Rescue Hearts');
    expect(match?.town).toBe('Springfield');
    expect(match?.administrative_area).toBe('IL');
    expect(match?.description).toBe('A caring rescue shelter');
    expect(match?.logo_url).toBe('/uploads/org_photos/rescue-hearts.png');
    expect(match).not.toHaveProperty('email');
    expect(match).not.toHaveProperty('phone');
    expect(match).not.toHaveProperty('legal_identifier_1');
  });

  test('@P1 opted-out organisation is excluded from discovery list', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const owner = await signupUser(baseURL, { firstName: 'Quiet', lastName: 'Admin' });
    const org = await createOrganization(baseURL, owner.accessToken, {
      name: 'Quiet Shelter',
      type: 'charity',
    });
    await setOrganizationDiscoverability(baseURL, owner.accessToken, org, false);

    const discovery = await discoverOrganizations(baseURL);
    expect(discovery.items.some((item) => item.id === org.id)).toBe(false);
  });
});
