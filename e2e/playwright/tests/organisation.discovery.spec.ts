/**
 * @bdd organisation_discovery.feature
 * Scenario: Discover Organisations is visible without signing in
 * Scenario: An organisation can opt out of discovery
 * Scenario: Discover API returns display_locality from postcode when set
 * Scenario: Discover API includes photo_url for hero imagery
 * Scenario: Discover API falls back display_locality to town then administrative area
 * Scenario: Discover API filters organisations by name when q is provided
 * Scenario: Discover API search preserves pagination metadata
 */
import { test, expect } from '../fixtures/auth.fixture';
import {
  createOrganization,
  findDiscoverableOrganization,
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

    const match = await findDiscoverableOrganization(baseURL, org.id);

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

    expect(await findDiscoverableOrganization(baseURL, org.id)).toBeUndefined();
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

    const match = await findDiscoverableOrganization(baseURL, org.id);
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

    const match = await findDiscoverableOrganization(baseURL, org.id);
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

    const match = await findDiscoverableOrganization(baseURL, org.id);
    expect(match?.display_locality).toBe('Springfield');
  });

  test('@P1 discover API filters organisations by name when q is provided', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const owner = await signupUser(baseURL, { firstName: 'Rescue', lastName: 'Admin' });
    const hearts = await createOrganization(baseURL, owner.accessToken, {
      name: 'Rescue Hearts',
      type: 'charity',
    });
    const tails = await createOrganization(baseURL, owner.accessToken, {
      name: 'Happy Tails Rescue',
      type: 'charity',
    });
    await setOrganizationDiscoveryProfile(baseURL, owner.accessToken, hearts, {
      town: 'Springfield',
      administrative_area: 'IL',
      description: 'A caring rescue shelter',
    });
    await setOrganizationDiscoveryProfile(baseURL, owner.accessToken, tails, {
      town: 'Shelbyville',
      administrative_area: 'IL',
      description: 'Another rescue',
    });

    const discovery = await discoverOrganizations(baseURL, { query: 'Hearts' });
    const names = discovery.items.map((item) => item.name);
    expect(names).toContain('Rescue Hearts');
    expect(names).not.toContain('Happy Tails Rescue');
  });

  test('@P1 discover API search preserves pagination metadata', async () => {
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

    const discovery = await discoverOrganizations(baseURL, {
      query: 'Hearts',
      page: 2,
      pageSize: 5,
    });
    expect(discovery.page).toBe(2);
    expect(discovery.page_size).toBe(5);
  });
});
