import {
  G0_PERMISSION_DEFAULTS,
  PERMISSION_BUNDLE_PET_ADMIN,
  VIEW_PERMISSION_KEYS,
  applyBundlePreset,
  grantPermission,
  revokePermission,
  hasEffectivePermission,
  hasPermission,
  hasPermissionForUser,
  permissionKeysForRole,
} from '../lib/orgPermissions.js';
import {
  ORG_ROLE_ADMIN,
  ORG_ROLE_ASSOCIATE,
  ORG_ROLE_FOSTER,
  ORG_ROLE_SUPER_ADMIN,
} from '../lib/orgRoles.js';

/** Pre-Phase-3 G0 keys only — regression baseline for existing admin capability. */
const LEGACY_G0_KEYS = Object.freeze([
  'manage_fosters',
  'review_foster_onboarding',
  'contact_fosters',
  'confirm_foster_competencies',
  'manage_fostering_sessions',
  'home_visits',
  'adopter_screening',
  'manage_adoption_visits',
  'start_adoption_journey',
  'confirm_return_to_shelter',
  'manage_document_templates',
]);

function createMockPool(handlers) {
  return {
    query: jest.fn(async (sql, params) => {
      for (const handler of handlers) {
        const result = handler(sql, params);
        if (result != null) return result;
      }
      throw new Error(`Unexpected query: ${sql}`);
    }),
  };
}

describe('orgPermissions', () => {
  describe('G0 default grants', () => {
    it('grants every G0 key to the documented default roles', () => {
      for (const [key, roles] of Object.entries(G0_PERMISSION_DEFAULTS)) {
        for (const role of roles) {
          expect(hasPermission(role, null, key)).toBe(true);
        }
        expect(hasPermission(ORG_ROLE_FOSTER, null, key)).toBe(
          roles.includes(ORG_ROLE_ASSOCIATE)
        );
        expect(hasPermission(ORG_ROLE_ASSOCIATE, null, key)).toBe(
          roles.includes(ORG_ROLE_ASSOCIATE)
        );
      }
    });

    it('manage_document_templates and manage_permissions are super_admin only', () => {
      expect(hasPermission(ORG_ROLE_SUPER_ADMIN, null, 'manage_document_templates')).toBe(
        true
      );
      expect(hasPermission(ORG_ROLE_ADMIN, null, 'manage_document_templates')).toBe(false);
      expect(hasPermission(ORG_ROLE_SUPER_ADMIN, null, 'manage_permissions')).toBe(true);
      expect(hasPermission(ORG_ROLE_ADMIN, null, 'manage_permissions')).toBe(false);
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

  describe('three wire roles', () => {
    it('super_admin retains full G0 admin capability', () => {
      for (const key of LEGACY_G0_KEYS) {
        expect(hasPermission(ORG_ROLE_SUPER_ADMIN, null, key)).toBe(true);
      }
    });

    it('admin retains legacy G0 admin keys except super_admin-only keys', () => {
      for (const key of LEGACY_G0_KEYS) {
        const expected = G0_PERMISSION_DEFAULTS[key].includes(ORG_ROLE_ADMIN);
        expect(hasPermission(ORG_ROLE_ADMIN, null, key)).toBe(expected);
      }
    });

    it('foster wire normalises to associate for admin grant checks', () => {
      expect(hasPermission(ORG_ROLE_FOSTER, null, 'manage_fosters')).toBe(false);
      expect(hasPermission(ORG_ROLE_ASSOCIATE, null, 'manage_fosters')).toBe(false);
      expect(hasPermission(ORG_ROLE_FOSTER, null, 'manage_pets')).toBe(false);
      expect(hasPermission(ORG_ROLE_ASSOCIATE, null, 'manage_members')).toBe(false);
    });
  });

  describe('view permission defaults (Organisation v2)', () => {
    const VIEW_MATRIX = {
      view_org_internal: [
        ORG_ROLE_SUPER_ADMIN,
        ORG_ROLE_ADMIN,
        ORG_ROLE_ASSOCIATE,
      ],
      view_admin_contacts: [
        ORG_ROLE_SUPER_ADMIN,
        ORG_ROLE_ADMIN,
        ORG_ROLE_ASSOCIATE,
      ],
      view_org_pets: [
        ORG_ROLE_SUPER_ADMIN,
        ORG_ROLE_ADMIN,
        ORG_ROLE_ASSOCIATE,
      ],
      view_connections: [
        ORG_ROLE_SUPER_ADMIN,
        ORG_ROLE_ADMIN,
        ORG_ROLE_ASSOCIATE,
      ],
      view_fostering_sessions: [ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN],
    };

    it('documents every view key in VIEW_PERMISSION_KEYS', () => {
      expect([...VIEW_PERMISSION_KEYS].sort()).toEqual(
        Object.keys(VIEW_MATRIX).sort()
      );
    });

    for (const [key, grantedRoles] of Object.entries(VIEW_MATRIX)) {
      for (const role of [
        ORG_ROLE_SUPER_ADMIN,
        ORG_ROLE_ADMIN,
        ORG_ROLE_ASSOCIATE,
      ]) {
        it(`${role} ${grantedRoles.includes(role) ? 'has' : 'lacks'} ${key}`, () => {
          expect(hasPermission(role, null, key)).toBe(grantedRoles.includes(role));
        });
      }
    }

    it('bundle override can grant view_fostering_sessions to associate', () => {
      expect(
        hasEffectivePermission(ORG_ROLE_ASSOCIATE, ['view_fostering_sessions'], 'view_fostering_sessions')
      ).toBe(true);
    });
  });

  describe('bundle preset union', () => {
    it('grants pet admin bundle keys via active override rows', () => {
      const overrides = [
        'manage_pets',
        'manage_fostering_sessions',
        'transfer_pet_ownership',
      ];
      expect(
        hasEffectivePermission(ORG_ROLE_ASSOCIATE, overrides, 'manage_pets')
      ).toBe(true);
      expect(
        hasEffectivePermission(ORG_ROLE_ASSOCIATE, overrides, 'manage_fosters')
      ).toBe(false);
    });
  });

  describe('individual override', () => {
    it('grants a single key not in role defaults', () => {
      expect(
        hasPermission(ORG_ROLE_FOSTER, { activePermissionKeys: ['manage_pets'] }, 'manage_pets')
      ).toBe(true);
    });
  });

  describe('hasPermissionForUser', () => {
    const orgId = 'org-1';
    const userId = 'user-1';

    it('returns false for pending membership', async () => {
      const pool = createMockPool([
        (sql) => {
          if (sql.includes('FROM organization_users')) {
            return { rows: [{ role: 'pending_admin' }] };
          }
          return null;
        },
      ]);

      await expect(
        hasPermissionForUser(pool, userId, orgId, 'manage_fosters')
      ).resolves.toBe(false);
    });

    it('unions active organization_permissions rows with role defaults', async () => {
      const pool = createMockPool([
        (sql) => {
          if (sql.includes('FROM organization_users')) {
            return { rows: [{ role: ORG_ROLE_ASSOCIATE }] };
          }
          if (sql.includes('FROM organization_permissions')) {
            return { rows: [{ permission_key: 'manage_pets' }] };
          }
          return null;
        },
      ]);

      await expect(
        hasPermissionForUser(pool, userId, orgId, 'manage_pets')
      ).resolves.toBe(true);
      await expect(
        hasPermissionForUser(pool, userId, orgId, 'manage_fosters')
      ).resolves.toBe(false);
    });
  });

  describe('grant and bundle helpers', () => {
    it('applyBundlePreset writes one row per bundle key', async () => {
      const inserts = [];
      const audits = [];
      const pool = {
        query: jest.fn(async (sql, params) => {
          if (sql.includes('INSERT INTO organization_permissions')) {
            inserts.push(params);
            return { rowCount: 1 };
          }
          if (sql.includes('INSERT INTO audit_events')) {
            audits.push(params);
            return { rows: [{ id: 'audit-1' }] };
          }
          return { rows: [] };
        }),
      };

      const count = await applyBundlePreset(pool, {
        organizationId: 'org-1',
        userId: 'user-2',
        presetName: PERMISSION_BUNDLE_PET_ADMIN,
        grantedBy: 'admin-1',
      });

      expect(count).toBe(3);
      expect(inserts).toHaveLength(3);
      expect(inserts[0][3]).toBe('manage_pets');
      expect(inserts[0][4]).toBe('bundle:pet_admin');
      expect(audits.some((params) => params.includes('bundle_preset_applied'))).toBe(true);
    });

    it('grantPermission skips duplicate active rows', async () => {
      const pool = {
        query: jest.fn(async () => ({ rowCount: 0 })),
      };

      const id = await grantPermission(pool, {
        organizationId: 'org-1',
        userId: 'user-2',
        permissionKey: 'manage_pets',
        grantedBy: 'admin-1',
      });

      expect(id).toBeNull();
    });

    it('grantPermission records permission_granted audit event', async () => {
      const audits = [];
      const pool = {
        query: jest.fn(async (sql, params) => {
          if (sql.includes('INSERT INTO audit_events')) {
            audits.push(params);
            return { rows: [{ id: 'audit-grant' }] };
          }
          return { rowCount: 1 };
        }),
      };

      const id = await grantPermission(pool, {
        organizationId: 'org-1',
        userId: 'user-2',
        permissionKey: 'manage_pets',
        grantedBy: 'admin-1',
      });

      expect(id).toBeTruthy();
      expect(audits.some((params) => params.includes('permission_granted'))).toBe(true);
    });

    it('revokePermission records permission_revoked audit event', async () => {
      const audits = [];
      const pool = {
        query: jest.fn(async (sql, params) => {
          if (sql.includes('UPDATE organization_permissions')) {
            return { rowCount: 1, rows: [{ id: 'perm-1' }] };
          }
          if (sql.includes('INSERT INTO audit_events')) {
            audits.push(params);
            return { rows: [{ id: 'audit-revoke' }] };
          }
          return { rows: [] };
        }),
      };

      const revoked = await revokePermission(pool, {
        organizationId: 'org-1',
        userId: 'user-2',
        permissionKey: 'manage_pets',
        revokedBy: 'admin-1',
      });

      expect(revoked).toBe(true);
      expect(audits.some((params) => params.includes('permission_revoked'))).toBe(true);
    });
  });
});
