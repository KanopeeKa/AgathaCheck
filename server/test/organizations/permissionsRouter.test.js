import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';
const targetUserId = 'member-user-id';

function buildPermissionsPool({
  viewerRole = 'super_admin',
  targetRole = 'associate',
  permissionRows = [],
  auditRows = [],
  revokeFound = true,
} = {}) {
  const query = async (sql, params) => {
    if (sql.includes('SELECT role') && sql.includes('organization_users')) {
      const queriedUserId = params?.[1];
      if (queriedUserId === targetUserId) {
        return { rows: targetRole ? [{ role: targetRole }] : [] };
      }
      return { rows: viewerRole ? [{ role: viewerRole }] : [] };
    }
    if (sql.includes('SELECT permission_key') && sql.includes('organization_permissions')) {
      if (sql.includes('source')) {
        return { rows: permissionRows };
      }
      return {
        rows: permissionRows.map((row) => ({ permission_key: row.permission_key })),
      };
    }
    if (sql.includes('INSERT INTO organization_permissions')) {
      return { rows: [], rowCount: 1 };
    }
    if (sql.includes('UPDATE organization_permissions') && sql.includes('revoked_at')) {
      return {
        rows: revokeFound ? [{ id: 'perm-1' }] : [],
        rowCount: revokeFound ? 1 : 0,
      };
    }
    if (sql.includes('INSERT INTO audit_events')) {
      return { rows: [{ id: 'audit-1' }] };
    }
    if (sql.includes('FROM audit_events') && sql.includes('org_id')) {
      return { rows: auditRows };
    }
    return { rows: [] };
  };

  return {
    query,
    connect: async () => ({ query, release: () => {} }),
    end: async () => {},
  };
}

describe('Organizations permissions API', () => {
  describe('GET /:orgId/permission-bundles', () => {
    it('returns bundle presets for super admin', async () => {
      const app = createApp(buildPermissionsPool());
      const res = await request(app)
        .get(`/api/organizations/${orgId}/permission-bundles`)
        .set('Authorization', `Bearer ${token}`);

      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body.presets)).toBe(true);
      expect(res.body.presets.some((preset) => preset.name === 'pet_admin')).toBe(true);
      expect(res.body.presets[0]).toHaveProperty('permission_keys');
    });

    it('returns 403 for non-super-admin', async () => {
      const app = createApp(buildPermissionsPool({ viewerRole: 'admin' }));
      const res = await request(app)
        .get(`/api/organizations/${orgId}/permission-bundles`)
        .set('Authorization', `Bearer ${token}`);

      expect(res.statusCode).toBe(403);
    });
  });

  describe('GET /:orgId/members/:targetUserId/permissions', () => {
    it('returns effective permissions and overrides', async () => {
      const app = createApp(
        buildPermissionsPool({
          targetRole: 'associate',
          permissionRows: [
            {
              permission_key: 'manage_pets',
              source: 'bundle:pet_admin',
              granted_at: new Date('2026-07-25T12:00:00Z'),
            },
          ],
        }),
      );
      const res = await request(app)
        .get(`/api/organizations/${orgId}/members/${targetUserId}/permissions`)
        .set('Authorization', `Bearer ${token}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.role).toBe('associate');
      expect(res.body.effective_permissions).toContain('manage_pets');
      expect(res.body.overrides).toHaveLength(1);
      expect(res.body.overrides[0].permission_key).toBe('manage_pets');
    });

    it('returns 404 when target member is missing', async () => {
      const app = createApp(buildPermissionsPool({ targetRole: null }));
      const res = await request(app)
        .get(`/api/organizations/${orgId}/members/${targetUserId}/permissions`)
        .set('Authorization', `Bearer ${token}`);

      expect(res.statusCode).toBe(404);
    });
  });

  describe('POST /:orgId/members/:targetUserId/permissions/bundle', () => {
    it('applies a bundle preset', async () => {
      const app = createApp(buildPermissionsPool({ targetRole: 'associate' }));
      const res = await request(app)
        .post(`/api/organizations/${orgId}/members/${targetUserId}/permissions/bundle`)
        .set('Authorization', `Bearer ${token}`)
        .send({ preset: 'pet_admin' });

      expect(res.statusCode).toBe(200);
      expect(res.body.preset).toBe('pet_admin');
      expect(res.body).toHaveProperty('granted_count');
      expect(Array.isArray(res.body.effective_permissions)).toBe(true);
    });

    it('returns 400 for unknown preset', async () => {
      const app = createApp(buildPermissionsPool());
      const res = await request(app)
        .post(`/api/organizations/${orgId}/members/${targetUserId}/permissions/bundle`)
        .set('Authorization', `Bearer ${token}`)
        .send({ preset: 'unknown_bundle' });

      expect(res.statusCode).toBe(400);
    });
  });

  describe('POST /:orgId/members/:targetUserId/permissions', () => {
    it('grants an individual permission', async () => {
      const app = createApp(buildPermissionsPool({ targetRole: 'foster' }));
      const res = await request(app)
        .post(`/api/organizations/${orgId}/members/${targetUserId}/permissions`)
        .set('Authorization', `Bearer ${token}`)
        .send({ permission_key: 'manage_pets' });

      expect(res.statusCode).toBe(200);
      expect(res.body.permission_key).toBe('manage_pets');
      expect(Array.isArray(res.body.effective_permissions)).toBe(true);
    });

    it('returns 400 for invalid permission key', async () => {
      const app = createApp(buildPermissionsPool());
      const res = await request(app)
        .post(`/api/organizations/${orgId}/members/${targetUserId}/permissions`)
        .set('Authorization', `Bearer ${token}`)
        .send({ permission_key: 'not_a_key' });

      expect(res.statusCode).toBe(400);
    });
  });

  describe('DELETE /:orgId/members/:targetUserId/permissions/:permissionKey', () => {
    it('revokes an active override', async () => {
      const app = createApp(buildPermissionsPool({ targetRole: 'associate' }));
      const res = await request(app)
        .delete(
          `/api/organizations/${orgId}/members/${targetUserId}/permissions/manage_pets`,
        )
        .set('Authorization', `Bearer ${token}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.permission_key).toBe('manage_pets');
    });

    it('returns 404 when override is missing', async () => {
      const app = createApp(
        buildPermissionsPool({ targetRole: 'associate', revokeFound: false }),
      );
      const res = await request(app)
        .delete(
          `/api/organizations/${orgId}/members/${targetUserId}/permissions/manage_pets`,
        )
        .set('Authorization', `Bearer ${token}`);

      expect(res.statusCode).toBe(404);
    });
  });

  describe('GET /:orgId/audit-events', () => {
    it('returns recent audit events with safe metadata', async () => {
      const app = createApp(
        buildPermissionsPool({
          auditRows: [
            {
              id: 'audit-1',
              occurred_at: new Date('2026-07-25T10:00:00Z'),
              action: 'bundle_preset_applied',
              resource_type: 'organization_permission_bundle',
              resource_id: 'pet_admin',
              actor_user_id: userId,
              actor_pseudonym: null,
              metadata: {
                user_id: targetUserId,
                preset_name: 'pet_admin',
                permission_keys: ['manage_pets'],
                granted_count: 1,
                foster_notes: 'should be stripped',
              },
              retention_tier: 'hot',
            },
          ],
        }),
      );
      const res = await request(app)
        .get(`/api/organizations/${orgId}/audit-events`)
        .set('Authorization', `Bearer ${token}`);

      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body[0].action).toBe('bundle_preset_applied');
      expect(res.body[0].actor_user_id).toBe(userId);
      expect(res.body[0].metadata.preset_name).toBe('pet_admin');
      expect(res.body[0].metadata.foster_notes).toBeUndefined();
    });
  });
});
