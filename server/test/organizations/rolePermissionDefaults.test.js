import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import {
  buildRolePermissionDefaultsResponse,
  effectiveTierDefaultKeys,
} from '../../lib/orgPermissions.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';

function buildRoleDefaultsPool({
  viewerRole = 'super_admin',
  orgDefaultRows = [],
  membersByRole = { associate: ['member-1'], admin: ['admin-1'] },
} = {}) {
  const query = async (sql, params) => {
    if (sql.includes('SELECT role') && sql.includes('organization_users')) {
      return { rows: viewerRole ? [{ role: viewerRole }] : [] };
    }
    if (sql.includes('FROM organization_role_permission_defaults')) {
      return { rows: orgDefaultRows };
    }
    if (sql.includes('DELETE FROM organization_role_permission_defaults')) {
      return { rows: [], rowCount: orgDefaultRows.length };
    }
    if (sql.includes('INSERT INTO organization_role_permission_defaults')) {
      return { rows: [], rowCount: 1 };
    }
    if (sql.includes('SELECT user_id') && sql.includes('organization_users')) {
      const role = params?.[1];
      const ids = membersByRole[role] ?? [];
      return { rows: ids.map((id) => ({ user_id: id })) };
    }
    if (sql.includes('SELECT permission_key') && sql.includes('organization_permissions')) {
      return { rows: [] };
    }
    if (sql.includes('UPDATE organization_permissions')) {
      return { rows: [], rowCount: 0 };
    }
    if (sql.includes('INSERT INTO audit_events')) {
      return { rows: [{ id: 'audit-1' }] };
    }
    if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
      return { rows: [] };
    }
    return { rows: [] };
  };

  const client = { query, release: () => {} };

  return {
    query,
    connect: async () => client,
    end: async () => {},
  };
}

describe('Organizations role permission defaults API', () => {
  describe('GET /:orgId/role-permission-defaults', () => {
    it('returns tier defaults with G0 union org rows', async () => {
      const orgDefaultRows = [
        {
          role_tier: 'associate',
          permission_key: 'manage_pets',
          granted: true,
        },
      ];
      const app = createApp(buildRoleDefaultsPool({ orgDefaultRows }));
      const res = await request(app)
        .get(`/api/organizations/${orgId}/role-permission-defaults`)
        .set('Authorization', `Bearer ${token}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.tiers.associate.editable).toBe(true);
      expect(res.body.tiers.associate.effective_defaults).toContain('manage_pets');
      expect(res.body.tiers.super_admin.editable).toBe(false);
      expect(res.body.permission_keys).toContain('manage_fosters');
    });

    it('returns 403 without manage_permissions', async () => {
      const app = createApp(buildRoleDefaultsPool({ viewerRole: 'admin' }));
      const res = await request(app)
        .get(`/api/organizations/${orgId}/role-permission-defaults`)
        .set('Authorization', `Bearer ${token}`);

      expect(res.statusCode).toBe(403);
    });
  });

  describe('PUT /:orgId/role-permission-defaults', () => {
    it('saves associate tier defaults and reports members affected', async () => {
      const app = createApp(
        buildRoleDefaultsPool({
          membersByRole: { associate: ['member-1', 'member-2'] },
        }),
      );
      const grantedKeys = effectiveTierDefaultKeys('associate', [
        { role_tier: 'associate', permission_key: 'manage_pets', granted: true },
      ]);

      const res = await request(app)
        .put(`/api/organizations/${orgId}/role-permission-defaults`)
        .set('Authorization', `Bearer ${token}`)
        .send({ tier: 'associate', granted_keys: grantedKeys });

      expect(res.statusCode).toBe(200);
      expect(res.body.tier).toBe('associate');
      expect(res.body.members_affected).toBe(2);
      expect(res.body.effective_defaults).toContain('manage_pets');
    });

    it('rejects super_admin tier updates', async () => {
      const app = createApp(buildRoleDefaultsPool());
      const res = await request(app)
        .put(`/api/organizations/${orgId}/role-permission-defaults`)
        .set('Authorization', `Bearer ${token}`)
        .send({
          tier: 'super_admin',
          granted_keys: buildRolePermissionDefaultsResponse().tiers.super_admin
            .effective_defaults,
        });

      expect(res.statusCode).toBe(400);
    });

    it('returns 400 for invalid permission keys', async () => {
      const app = createApp(buildRoleDefaultsPool());
      const res = await request(app)
        .put(`/api/organizations/${orgId}/role-permission-defaults`)
        .set('Authorization', `Bearer ${token}`)
        .send({ tier: 'admin', granted_keys: ['not_a_key'] });

      expect(res.statusCode).toBe(400);
    });
  });
});

describe('buildRolePermissionDefaultsResponse', () => {
  it('computes effective defaults as G0 union org rows', () => {
    const response = buildRolePermissionDefaultsResponse([
      { role_tier: 'associate', permission_key: 'manage_pets', granted: true },
      {
        role_tier: 'associate',
        permission_key: 'view_fostering_sessions',
        granted: false,
      },
    ]);

    expect(response.tiers.associate.effective_defaults).toContain('manage_pets');
    expect(response.tiers.associate.effective_defaults).not.toContain(
      'view_fostering_sessions',
    );
    expect(response.tiers.super_admin.org_overrides).toEqual([]);
  });
});
