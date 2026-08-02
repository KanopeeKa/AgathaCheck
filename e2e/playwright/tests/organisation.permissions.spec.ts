/**
 * @bdd organisation_permissions.feature
 * Scenario: Super Admin applies the Pet Admin bundle preset
 * Scenario: Only Super Admin can manage permissions
 */
import { test, expect } from '../fixtures/auth.fixture';
import {
  addMemberToOrg,
  applyOrgPermissionBundle,
  createOrganization,
  getOrgAuditEvents,
  getOrgPermissionsMe,
  signupUser,
  tryGrantOrgPermission,
} from '../support/api';

const ORG_NAME = 'Rescue Hearts';

test.describe('Organisation permissions', () => {
  test('@P1 super admin applies Pet Admin bundle to associate', async () => {
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
    const bob = await signupUser(baseURL, {
      firstName: 'Bob',
      lastName: 'Associate',
      email: `bob-${Date.now()}@example.com`,
    });
    await addMemberToOrg(baseURL, alice.accessToken, org.id, bob, 'associate');

    const result = await applyOrgPermissionBundle(
      baseURL,
      alice.accessToken,
      org.id,
      bob.userId,
      'pet_admin',
    );
    expect(result.preset).toBe('pet_admin');
    expect(result.granted_count).toBeGreaterThan(0);
    expect(result.effective_permissions).toContain('manage_pets');

    const bobPerms = await getOrgPermissionsMe(baseURL, bob.accessToken, org.id);
    expect(bobPerms.effective_permissions).toContain('manage_pets');

    const audit = await getOrgAuditEvents(baseURL, alice.accessToken, org.id);
    expect(audit.some((e) => e.action === 'bundle_preset_applied')).toBe(true);
  });

  test('@P1 only super admin can grant individual permissions', async () => {
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
    const carol = await signupUser(baseURL, {
      firstName: 'Carol',
      lastName: 'Admin',
      email: `carol-${Date.now()}@example.com`,
    });
    const dave = await signupUser(baseURL, {
      firstName: 'Dave',
      lastName: 'Foster',
      email: `dave-${Date.now()}@example.com`,
    });
    await addMemberToOrg(baseURL, zara.accessToken, org.id, carol, 'admin');
    await addMemberToOrg(baseURL, zara.accessToken, org.id, dave, 'foster');

    const denied = await tryGrantOrgPermission(
      baseURL,
      carol.accessToken,
      org.id,
      dave.userId,
      'manage_pets',
    );
    expect(denied.ok).toBe(false);
    expect(denied.status).toBe(403);

    const carolPerms = await getOrgPermissionsMe(baseURL, carol.accessToken, org.id);
    expect(carolPerms.effective_permissions).not.toContain('manage_permissions');
  });
});
