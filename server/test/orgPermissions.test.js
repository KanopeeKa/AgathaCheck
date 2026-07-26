import {
  G0_PERMISSION_DEFAULTS,
  hasPermission,
  permissionKeysForRole,
} from '../lib/orgPermissions.js';
import {
  ORG_ROLE_ADMIN,
  ORG_ROLE_FOSTER,
  ORG_ROLE_SUPER_ADMIN,
} from '../lib/orgRoles.js';

describe('orgPermissions (G0 defaults)', () => {
  it('grants every G0 §7 key to the documented default roles', () => {
    for (const [key, roles] of Object.entries(G0_PERMISSION_DEFAULTS)) {
      for (const role of roles) {
        expect(hasPermission(role, null, key)).toBe(true);
      }
      expect(hasPermission(ORG_ROLE_FOSTER, null, key)).toBe(
        roles.includes(ORG_ROLE_FOSTER)
      );
    }
  });

  it('manage_document_templates is super_admin only', () => {
    expect(hasPermission(ORG_ROLE_SUPER_ADMIN, null, 'manage_document_templates')).toBe(
      true
    );
    expect(hasPermission(ORG_ROLE_ADMIN, null, 'manage_document_templates')).toBe(false);
  });

  it('returns false for unknown permission keys', () => {
    expect(hasPermission(ORG_ROLE_SUPER_ADMIN, null, 'not_a_real_key')).toBe(false);
  });

  it('permissionKeysForRole lists admin grants', () => {
    const keys = permissionKeysForRole(ORG_ROLE_ADMIN);
    expect(keys).toContain('manage_fosters');
    expect(keys).not.toContain('manage_document_templates');
  });
});
