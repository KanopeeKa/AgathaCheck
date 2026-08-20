/**
 * @bdd redacted_org_pet.feature
 * Scenario: Associate sees pet preview on organisation profile
 * Scenario: Associate tap opens redacted pet profile with summary fields only
 * Scenario: Redacted pet API exposes allowlisted fields only
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  addMemberToOrg,
  createOrgPet,
  createOrganization,
  getRedactedOrgPet,
  signupUser,
} from '../support/api';
import { enableFlutterAccessibility, refreshFlutterAccessibility, waitForFlutterRoute } from '../support/flutter';
import { OrganizationDetailPage } from '../pages/organization-detail.page';
import { OrganizationListPage } from '../pages/organization-list.page';

const ORG_NAME = 'Rescue Hearts';
const PET_NAME = 'Buddy';

const REDACTED_ALLOWLIST = [
  'id',
  'name',
  'species',
  'breed',
  'photo_path',
  'date_of_birth',
  'age',
  'organization_id',
];

async function seedAssociatePetView(baseURL: string) {
  const alice = await signupUser(baseURL, {
    firstName: 'Alice',
    lastName: 'Super',
    email: `alice-${Date.now()}@example.com`,
  });
  const org = await createOrganization(baseURL, alice.accessToken, {
    name: ORG_NAME,
    type: 'charity',
  });
  const bob = await signupUser(baseURL, {
    firstName: 'Bob',
    lastName: 'Associate',
    email: `bob-${Date.now()}@example.com`,
  });
  await addMemberToOrg(baseURL, alice.accessToken, org.id, bob, 'associate');
  const pet = await createOrgPet(baseURL, alice.accessToken, org.id, {
    name: PET_NAME,
    species: 'dog',
  });
  return { alice, bob, org, pet };
}

test.describe('Redacted organisation pet profile', () => {
  test('@P1 associate sees pet preview on organisation profile', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { bob, org } = await seedAssociatePetView(baseURL);

    await loginAs(page, bob, { experience: 'organization' });
    const orgList = new OrganizationListPage(page);
    await orgList.openOrganizations();
    await orgList.openOrg(ORG_NAME, org.id);

    const detail = new OrganizationDetailPage(page);
    await detail.expectLoaded(ORG_NAME);
    await enableFlutterAccessibility(page);
    await refreshFlutterAccessibility(page);

    // v3: associates see pet count on profile section nav (full pets list is permission-gated).
    await expect(
      page.getByRole('button', { name: /Pets.*\b1\b.*pet/i }).first(),
    ).toBeVisible();
  });

  test('@P1 associate opens redacted pet profile with summary fields only', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { bob, org, pet } = await seedAssociatePetView(baseURL);

    await loginAs(page, bob, { experience: 'organization' });
    await waitForFlutterRoute(page, `/o/orgs/${org.id}/pets/${pet.id}/redacted`);
    await enableFlutterAccessibility(page);
    await refreshFlutterAccessibility(page);

    // Redacted profile: pet name in shell title; species is covered by API allowlist test below.
    await expect(page.getByRole('heading', { name: PET_NAME })).toBeVisible();
    await expect(page.getByText(/timeline|health|foster session|document/i)).toHaveCount(0);
  });

  test('@P1 redacted pet API exposes allowlisted fields only', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { bob, org, pet } = await seedAssociatePetView(baseURL);

    const redacted = await getRedactedOrgPet(baseURL, bob.accessToken, org.id, pet.id);
    expect(Object.keys(redacted).sort()).toEqual(REDACTED_ALLOWLIST.sort());
    expect(redacted.name).toBe(PET_NAME);
    expect(redacted.species).toBe('dog');
    expect(redacted.organization_id).toBe(org.id);
    expect(redacted).not.toHaveProperty('bio');
    expect(redacted).not.toHaveProperty('chip_id');
  });
});
