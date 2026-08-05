/**
 * @bdd organisation_edit.feature
 * Scenario: Super admin can update structured address and postcode
 * Scenario: Super admin can upload cover and logo images
 * Scenario: Profile edit icon opens edit form for manage_permissions users
 * Scenario: Super admin can delete organisation from edit screen only
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  createOrganization,
  getOrgPublicProfile,
  getOrgPermissionsMe,
  signupUser,
  updateOrganization,
} from '../support/api';
import { enableFlutterAccessibility } from '../support/flutter';
import { OrganizationDetailPage } from '../pages/organization-detail.page';
import { OrganizationListPage } from '../pages/organization-list.page';

const ORG_NAME = 'Rescue Hearts';

test.describe('Organisation edit', () => {
  test('@P1 super admin persists postcode in public profile metadata', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const alice = await signupUser(baseURL, {
      firstName: 'Alice',
      lastName: 'Super',
      email: `alice-${Date.now()}@example.com`,
    });
    const org = await createOrganization(baseURL, alice.accessToken, {
      name: ORG_NAME,
      type: 'charity',
    });

    await updateOrganization(baseURL, alice.accessToken, org.id, {
      name: org.name,
      type: org.type,
      bio: org.bio ?? '',
      town: 'Springfield',
      postcode: '62701',
    });

    const profile = await getOrgPublicProfile(baseURL, org.id);
    expect(profile.town).toBe('Springfield');
    expect(profile.public_profile_metadata).toEqual({ postcode: '62701' });
  });

  test('@P1 super admin sees cover and logo upload controls with guidance', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const alice = await signupUser(baseURL, {
      firstName: 'Alice',
      lastName: 'Super',
      email: `alice-${Date.now()}@example.com`,
    });
    const org = await createOrganization(baseURL, alice.accessToken, {
      name: ORG_NAME,
      type: 'charity',
    });

    await loginAs(page, alice, { experience: 'organization' });
    const orgList = new OrganizationListPage(page);
    await orgList.openOrganizations();
    await orgList.openOrg(ORG_NAME, org.id);

    const detail = new OrganizationDetailPage(page);
    await detail.expectLoaded(ORG_NAME);
    await detail.openEdit();
    await enableFlutterAccessibility(page);

    await expect(page.getByRole('button', { name: 'Upload logo' }).first()).toBeVisible();
    await expect(page.getByRole('button', { name: 'Upload cover' }).first()).toBeVisible();
    // v3 edit form exposes guidance as plain text nodes inside the branding group.
    await expect(page.getByText(/Square logo, at least 256×256 px/i)).toBeVisible();
    await expect(page.getByText(/Landscape image.*1200×450 px/i)).toBeVisible();
  });

  test('@P1 manage_permissions user sees edit control that opens edit form', async ({
    page,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const alice = await signupUser(baseURL, {
      firstName: 'Alice',
      lastName: 'Super',
      email: `alice-${Date.now()}@example.com`,
    });
    const org = await createOrganization(baseURL, alice.accessToken, {
      name: ORG_NAME,
      type: 'charity',
    });

    const perms = await getOrgPermissionsMe(baseURL, alice.accessToken, org.id);
    expect(perms.effective_permissions).toContain('manage_permissions');

    await loginAs(page, alice, { experience: 'organization' });
    const orgList = new OrganizationListPage(page);
    await orgList.openOrganizations();
    await orgList.openOrg(ORG_NAME, org.id);

    const detail = new OrganizationDetailPage(page);
    await detail.expectLoaded(ORG_NAME);
    await enableFlutterAccessibility(page);

    await page.getByRole('button', { name: 'Edit organisation' }).click();
    await expect(page.getByRole('button', { name: 'Edit Organisation' })).toBeVisible();
  });

  test('@P1 super admin sees delete organisation control on edit screen only', async ({
    page,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const alice = await signupUser(baseURL, {
      firstName: 'Alice',
      lastName: 'Super',
      email: `alice-${Date.now()}@example.com`,
    });
    const org = await createOrganization(baseURL, alice.accessToken, {
      name: ORG_NAME,
      type: 'charity',
    });

    await loginAs(page, alice, { experience: 'organization' });
    const orgList = new OrganizationListPage(page);
    await orgList.openOrganizations();
    await orgList.openOrg(ORG_NAME, org.id);

    const detail = new OrganizationDetailPage(page);
    await detail.expectLoaded(ORG_NAME);
    await detail.openMenu();
    await expect(page.getByRole('menuitem', { name: /Delete Organisation/i })).toHaveCount(0);
    await page.keyboard.press('Escape');

    await detail.openEdit();
    await enableFlutterAccessibility(page);
    await expect(page.getByRole('button', { name: /Delete Organisation/i })).toBeVisible();
  });
});
