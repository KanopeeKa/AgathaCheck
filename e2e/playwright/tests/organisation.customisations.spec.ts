/**
 * @bdd organisation_customisations.feature
 * Scenario: Only Super Admin sees the Administration entry on profile
 * Scenario: Audit log viewer shows a permission grant
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  addMemberToOrg,
  applyOrgPermissionBundle,
  createOrganization,
  getOrgAuditEvents,
  getOrgPermissionsMe,
  signupUser,
} from '../support/api';
import { OrganizationDetailPage } from '../pages/organization-detail.page';
import { waitForFlutterRoute } from '../support/flutter';

const ORG_NAME = 'Rescue Hearts';

test.describe('Organisation Administration', () => {
  test('@P1 only super admin sees Administration nav row on profile', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const zara = await signupUser(baseURL, {
      firstName: 'Zara',
      lastName: 'Super',
      email: `zara-${Date.now()}@example.com`,
    });
    const org = await createOrganization(baseURL, zara.accessToken, {
      name: ORG_NAME,
      type: 'charity',
    });
    const alice = await signupUser(baseURL, {
      firstName: 'Alice',
      lastName: 'Admin',
      email: `alice-${Date.now()}@example.com`,
    });
    await addMemberToOrg(baseURL, zara.accessToken, org.id, alice, 'admin');

    const fosterAdminPerms = await getOrgPermissionsMe(baseURL, alice.accessToken, org.id);
    expect(fosterAdminPerms.effective_permissions).not.toContain('manage_permissions');

    await loginAs(page, alice, { experience: 'organization' });
    await waitForFlutterRoute(page, `/o/orgs/${org.id}`);
    const detail = new OrganizationDetailPage(page);
    await detail.expectLoaded(ORG_NAME);
    await detail.expectProfileNavRowHidden(/Organisation Administration/i);

    await loginAs(page, zara, { experience: 'organization' });
    await waitForFlutterRoute(page, `/o/orgs/${org.id}`);
    await detail.expectLoaded(ORG_NAME);
    await detail.expectProfileNavRow(/Organisation Administration/i);

    const superPerms = await getOrgPermissionsMe(baseURL, zara.accessToken, org.id);
    expect(superPerms.effective_permissions).toContain('manage_permissions');
    expect(superPerms.effective_permissions).toContain('manage_document_templates');
  });

  test('@P1 audit log records bundle preset application', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const zara = await signupUser(baseURL, {
      firstName: 'Zara',
      lastName: 'Super',
      email: `zara-${Date.now()}@example.com`,
    });
    const org = await createOrganization(baseURL, zara.accessToken, {
      name: ORG_NAME,
      type: 'charity',
    });
    const alice = await signupUser(baseURL, {
      firstName: 'Alice',
      lastName: 'Member',
      email: `alice-${Date.now()}@example.com`,
    });
    await addMemberToOrg(baseURL, zara.accessToken, org.id, alice, 'associate');

    await applyOrgPermissionBundle(
      baseURL,
      zara.accessToken,
      org.id,
      alice.userId,
      'pet_admin',
    );

    const audit = await getOrgAuditEvents(baseURL, zara.accessToken, org.id);
    const grant = audit.find((e) => e.action === 'bundle_preset_applied');
    expect(grant).toBeTruthy();
    expect(grant?.metadata?.preset_name ?? grant?.metadata?.preset).toBeTruthy();
  });
});
