/**
 * @bdd organisation_customisations.feature
 * Scenario: Only Super Admin sees the customisations entry point
 * Scenario: Audit log viewer shows a permission grant
 */
import { test, expect } from '../fixtures/auth.fixture';
import {
  addMemberToOrg,
  applyOrgPermissionBundle,
  createOrganization,
  getOrgAuditEvents,
  getOrgPermissionsMe,
  signupUser,
} from '../support/api';

const ORG_NAME = 'Rescue Hearts';

test.describe('Organisation customisations', () => {
  test('@P1 only super admin has manage_permissions for customisations entry', async () => {
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
    expect(fosterAdminPerms.effective_permissions).not.toContain('manage_document_templates');

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
