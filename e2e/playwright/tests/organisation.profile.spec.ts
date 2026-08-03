/**
 * @bdd organisation_profile.feature
 * Scenario: Anonymous visitor can view a discoverable organisation profile
 * Scenario: Opted-out organisation profile is hidden from anonymous visitors
 * Scenario: Active member can view opted-out organisation public profile
 * Scenario: Public profile API exposes only public-tier fields
 */
import { test, expect } from '../fixtures/auth.fixture';
import {
  createOrganization,
  getOrgPublicProfile,
  setOrganizationDiscoveryProfile,
  signupUser,
  tryGetOrgPublicProfile,
  updateOrganization,
  addMemberToOrg,
} from '../support/api';
import { clearLiveApiAccess, prepareLiveApiAccess } from '../support/waf';
import { clearBrowserSessionState } from '../support/session';
import { OrganizationDetailPage } from '../pages/organization-detail.page';

const PUBLIC_ALLOWLIST = [
  'id',
  'name',
  'type',
  'logo_url',
  'photo_url',
  'description',
  'bio',
  'town',
  'administrative_area',
  'public_profile_metadata',
  'legal_identifier_1',
  'legal_identifier_2',
  'legal_identifier_3',
  'email',
  'phone',
  'website',
  'primary_contact',
];

const ORG_NAME = 'Rescue Hearts';
const DESCRIPTION = 'A caring rescue shelter';

test.describe('Organisation profile', () => {
  test('@P1 @smoke-ci @smoke-uat anonymous visitor can view discoverable organisation profile', async ({
    page,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await prepareLiveApiAccess(page, baseURL);
    try {
      const owner = await signupUser(baseURL, {
        firstName: 'Rescue',
        lastName: 'Admin',
      });
      const org = await createOrganization(baseURL, owner.accessToken, {
        name: ORG_NAME,
        type: 'charity',
      });
      await setOrganizationDiscoveryProfile(baseURL, owner.accessToken, org, {
        town: 'Springfield',
        administrative_area: 'IL',
        description: DESCRIPTION,
      });

      await clearBrowserSessionState(page);
      await prepareLiveApiAccess(page, baseURL);
      await page.goto(`${baseURL}/o/orgs/${org.id}`);

      const detail = new OrganizationDetailPage(page);
      await detail.expectLoaded(ORG_NAME);
      await expect(page.getByText(DESCRIPTION).first()).toBeVisible();
      await expect(page.getByRole('button', { name: /^Pets$|^Animaux$/i })).toHaveCount(0);
      await expect(page.getByText('Fostering sessions')).toHaveCount(0);
      await expect(page.getByText('Admin contacts')).toHaveCount(0);
    } finally {
      clearLiveApiAccess();
    }
  });

  test('@P1 opted-out organisation profile is hidden from anonymous visitors', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const owner = await signupUser(baseURL, { firstName: 'Quiet', lastName: 'Admin' });
    const org = await createOrganization(baseURL, owner.accessToken, {
      name: 'Quiet Shelter',
      type: 'charity',
    });
    await updateOrganization(baseURL, owner.accessToken, org.id, {
      name: org.name,
      type: org.type,
      bio: org.bio ?? '',
      is_discoverable: false,
    });

    const result = await tryGetOrgPublicProfile(baseURL, org.id);
    expect(result.ok).toBe(false);
    expect(result.status).toBe(404);
  });

  test('@P1 active member can view opted-out organisation public profile', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const owner = await signupUser(baseURL, { firstName: 'Quiet', lastName: 'Owner' });
    const org = await createOrganization(baseURL, owner.accessToken, {
      name: 'Quiet Shelter',
      type: 'charity',
    });
    await updateOrganization(baseURL, owner.accessToken, org.id, {
      name: org.name,
      type: org.type,
      bio: org.bio ?? '',
      is_discoverable: false,
    });
    const alice = await signupUser(baseURL, {
      firstName: 'Alice',
      lastName: 'Member',
      email: `alice-${Date.now()}@example.com`,
    });
    await addMemberToOrg(baseURL, owner.accessToken, org.id, alice, 'admin');

    const profile = await getOrgPublicProfile(baseURL, org.id, alice.accessToken);
    expect(profile.name).toBe('Quiet Shelter');
    expect(profile.id).toBe(org.id);
  });

  test('@P1 public profile API exposes only public-tier fields', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const owner = await signupUser(baseURL, { firstName: 'Rescue', lastName: 'Admin' });
    const org = await createOrganization(baseURL, owner.accessToken, {
      name: ORG_NAME,
      type: 'charity',
    });
    await updateOrganization(baseURL, owner.accessToken, org.id, {
      name: org.name,
      type: org.type,
      bio: 'Public bio',
      town: 'Springfield',
      administrative_area: 'IL',
      description: DESCRIPTION,
      email: 'contact@rescue.example',
      phone: '555-0100',
      postcode: '62701',
    });

    const profile = await getOrgPublicProfile(baseURL, org.id);
    expect(Object.keys(profile).sort()).toEqual(PUBLIC_ALLOWLIST.sort());
    expect(profile.name).toBe(ORG_NAME);
    expect(profile.town).toBe('Springfield');
    expect(profile.public_profile_metadata).toEqual({ postcode: '62701' });
    expect(profile).not.toHaveProperty('address');
    expect(profile).not.toHaveProperty('role');
    expect(profile).not.toHaveProperty('member_count');
  });
});
