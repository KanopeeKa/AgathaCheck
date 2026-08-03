/**
 * @bdd organisation_discovery.feature
 * Scenario: Discover Organisations is visible without signing in
 * Scenario: An organisation can opt out of discovery
 * Scenario: Discover API returns display_locality from postcode when set
 * Scenario: Discover API includes photo_url for hero imagery
 * Scenario: Discover API falls back display_locality to town then administrative area
 */
import { test, expect } from '../fixtures/auth.fixture';
import {
  createOrganization,
  discoverOrganizations,
  setOrganizationDiscoverability,
  setOrganizationDiscoveryProfile,
  signupUser,
  updateOrganization,
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
    expect(match?.display_locality).toBe('Springfield');
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

  test('@P1 discover API returns display_locality from postcode when set', async () => {
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
    await updateOrganization(baseURL, owner.accessToken, org.id, {
      name: org.name,
      type: org.type,
      bio: org.bio ?? '',
      town: 'Springfield',
      administrative_area: 'IL',
      postcode: '62701',
    });

    const discovery = await discoverOrganizations(baseURL);
    const match = discovery.items.find((item) => item.id === org.id);
    expect(match?.display_locality).toBe('62701');
  });

  test('@P1 discover API includes photo_url for hero imagery', async () => {
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
      photo_url: '/uploads/org_photos/rescue-hearts-cover.jpg',
    });

    const discovery = await discoverOrganizations(baseURL);
    const match = discovery.items.find((item) => item.id === org.id);
    expect(match?.photo_url).toBe('/uploads/org_photos/rescue-hearts-cover.jpg');
  });

  test('@P1 discover API falls back display_locality to town then administrative area', async () => {
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

    const discovery = await discoverOrganizations(baseURL);
    const match = discovery.items.find((item) => item.id === org.id);
    expect(match?.display_locality).toBe('Springfield');
  });
});
