import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';
const memberId = 'member-user-id';
const inviteId = 'invite-1';

function makeOrgRow(overrides = {}) {
  return {
    id: orgId,
    name: 'Test Org',
    type: 'professional',
    email: 'org@test.com',
    phone: '555-1234',
    address: '123 Main St',
    website: 'https://test.org',
    bio: 'A test organization',
    photo_url: '/photos/org.jpg',
    role: 'super_user',
    member_count: '2',
    pet_count: '1',
    created_at: new Date('2024-01-01'),
    updated_at: new Date('2024-06-01'),
    ...overrides,
  };
}

function buildMockPool(overrides = {}) {
  const defaultHandler = async (sql, params) => {
    if (sql.includes('SELECT o.*') && sql.includes('ORDER BY o.name')) {
      return { rows: [makeOrgRow()] };
    }
    if (sql.includes('INSERT INTO organizations')) {
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO organization_users') && !sql.includes('ON CONFLICT')) {
      return { rows: [] };
    }
    if (sql.includes("SELECT o.*, 'super_user' as role")) {
      return { rows: [makeOrgRow({ role: 'super_user', member_count: '1', pet_count: '0' })] };
    }
    if (sql.includes('SELECT o.*') && sql.includes('WHERE o.id')) {
      return { rows: [makeOrgRow()] };
    }
    if (sql.includes('UPDATE organizations SET')) {
      return { rows: [] };
    }
    if (sql.includes('DELETE FROM organizations')) {
      return { rows: [makeOrgRow()] };
    }
    if (sql.includes('SELECT ou.id, ou.organization_id')) {
      return {
        rows: [{
          id: inviteId,
          organization_id: orgId,
          role: 'pending_member',
          org_name: 'Test Org',
          org_type: 'professional',
        }],
      };
    }
    if (sql.includes("UPDATE organization_users SET role = REPLACE")) {
      return {
        rows: [{
          id: inviteId,
          organization_id: orgId,
          role: 'member',
          user_id: userId,
        }],
      };
    }
    if (sql.includes("DELETE FROM organization_users WHERE id")) {
      return { rows: [] };
    }
    if (sql.includes('SELECT ou.id, ou.role, ou.created_at, u.id as user_id')) {
      return {
        rows: [{
          id: 'ou-1',
          user_id: userId,
          email: 'test@example.com',
          first_name: 'Test',
          last_name: 'User',
          photo_url: '/photos/user.jpg',
          role: 'super_user',
          created_at: new Date('2024-01-01'),
        }],
      };
    }
    if (sql.includes('SELECT id FROM users WHERE email')) {
      return { rows: [{ id: memberId }] };
    }
    if (sql.includes('INSERT INTO organization_users') && sql.includes('ON CONFLICT')) {
      return { rows: [] };
    }
    if (sql.includes('UPDATE organization_users SET role = $1')) {
      return {
        rows: [{ id: 'ou-1', organization_id: orgId, user_id: memberId, role: 'member' }],
      };
    }
    if (sql.includes('DELETE FROM organization_users WHERE organization_id') && sql.includes('AND user_id = $2')) {
      return { rows: [] };
    }
    if (sql.includes('SELECT * FROM pets WHERE organization_id')) {
      return {
        rows: [{
          id: 'pet-1',
          name: 'Buddy',
          species: 'dog',
          breed: 'Labrador',
          organization_id: orgId,
        }],
      };
    }
    if (sql.includes('SELECT * FROM archived_pets WHERE organization_id')) {
      return { rows: [] };
    }
    return { rows: [] };
  };

  return {
    query: overrides.query || defaultHandler,
    end: async () => {},
  };
}

describe('Organizations API', () => {
  let app;

  beforeAll(() => {
    app = createApp(buildMockPool());
  });

  describe('Auth guard - 401 without token', () => {
    const endpoints = [
      ['GET', '/api/organizations'],
      ['POST', '/api/organizations'],
      ['GET', `/api/organizations/${orgId}`],
      ['PUT', `/api/organizations/${orgId}`],
      ['DELETE', `/api/organizations/${orgId}`],
      ['GET', '/api/organizations/invites/pending'],
      ['POST', `/api/organizations/invites/${inviteId}/accept`],
      ['POST', `/api/organizations/invites/${inviteId}/decline`],
      ['POST', '/api/organizations/join/abc123'],
      ['GET', `/api/organizations/${orgId}/members`],
      ['POST', `/api/organizations/${orgId}/invite`],
      ['DELETE', `/api/organizations/${orgId}/members/me`],
      ['GET', `/api/organizations/${orgId}/pets`],
      ['GET', `/api/organizations/${orgId}/archived`],
    ];

    endpoints.forEach(([method, url]) => {
      it(`${method} ${url} returns 401 without token`, async () => {
        const res = await request(app)[method.toLowerCase()](url).send({});
        expect(res.statusCode).toBe(401);
      });
    });
  });

  describe('GET / (list)', () => {
    it('returns array of organizations with mapped fields', async () => {
      const res = await request(app)
        .get('/api/organizations')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBe(1);
      const org = res.body[0];
      expect(org).toHaveProperty('id', orgId);
      expect(org).toHaveProperty('name', 'Test Org');
      expect(org).toHaveProperty('type', 'professional');
      expect(org).toHaveProperty('email', 'org@test.com');
      expect(org).toHaveProperty('phone', '555-1234');
      expect(org).toHaveProperty('address', '123 Main St');
      expect(org).toHaveProperty('website', 'https://test.org');
      expect(org).toHaveProperty('bio', 'A test organization');
      expect(org).toHaveProperty('photo_url', '/photos/org.jpg');
      expect(org).toHaveProperty('role', 'super_user');
      expect(org).toHaveProperty('member_count', 2);
      expect(typeof org.member_count).toBe('number');
    });
  });

  describe('POST / (create)', () => {
    it('creates organization with owner role super_user', async () => {
      const res = await request(app)
        .post('/api/organizations')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'New Org', type: 'charity', email: 'new@org.com' });
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('name');
      expect(res.body).toHaveProperty('type');
      expect(res.body).toHaveProperty('role', 'super_user');
      expect(res.body).toHaveProperty('member_count');
    });

    it('defaults type to professional when not specified', async () => {
      let insertedType = null;
      const pool = buildMockPool({
        query: async (sql, params) => {
          if (sql.includes('INSERT INTO organizations (')) {
            insertedType = params[2];
            return { rows: [] };
          }
          if (sql.includes('INSERT INTO organization_users')) {
            return { rows: [] };
          }
          if (sql.includes("SELECT o.*") && sql.includes("'super_user' as role")) {
            return { rows: [makeOrgRow({ type: 'professional', role: 'super_user', member_count: '1', pet_count: '0' })] };
          }
          if (sql.includes('SELECT o.*')) {
            return { rows: [makeOrgRow()] };
          }
          return { rows: [] };
        },
      });
      const a = createApp(pool);
      const res = await request(a)
        .post('/api/organizations')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Test' });
      expect(res.statusCode).toBe(201);
      expect(insertedType).toBe('professional');
    });
  });

  describe('GET /invites/pending', () => {
    it('returns pending invites', async () => {
      const res = await request(app)
        .get('/api/organizations/invites/pending')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      const invite = res.body[0];
      expect(invite).toHaveProperty('id');
      expect(invite).toHaveProperty('organization_id');
      expect(invite).toHaveProperty('role');
      expect(invite).toHaveProperty('org_name');
      expect(invite).toHaveProperty('org_type');
    });
  });

  describe('POST /invites/:id/accept', () => {
    it('accepts an invite', async () => {
      const res = await request(app)
        .post(`/api/organizations/invites/${inviteId}/accept`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('id');
      expect(res.body).toHaveProperty('organization_id');
      expect(res.body).toHaveProperty('role');
    });

    it('returns 404 when invite not found', async () => {
      const pool = buildMockPool({
        query: async (sql) => {
          if (sql.includes("UPDATE organization_users SET role = REPLACE")) {
            return { rows: [] };
          }
          return { rows: [] };
        },
      });
      const a = createApp(pool);
      const res = await request(a)
        .post('/api/organizations/invites/nonexistent/accept')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
    });
  });

  describe('POST /invites/:id/decline', () => {
    it('declines an invite', async () => {
      const res = await request(app)
        .post(`/api/organizations/invites/${inviteId}/decline`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('success', true);
    });
  });

  describe('POST /join/:code', () => {
    it('joins an organization by code', async () => {
      const res = await request(app)
        .post('/api/organizations/join/abc123')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message');
    });
  });

  describe('GET /:id', () => {
    it('returns a single organization with mapped fields', async () => {
      const res = await request(app)
        .get(`/api/organizations/${orgId}`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('id', orgId);
      expect(res.body).toHaveProperty('name');
      expect(res.body).toHaveProperty('type');
      expect(res.body).toHaveProperty('role');
      expect(res.body).toHaveProperty('member_count');
    });

    it('returns 404 when not found', async () => {
      const pool = buildMockPool({
        query: async (sql) => {
          if (sql.includes('SELECT o.*') && sql.includes('WHERE o.id')) {
            return { rows: [] };
          }
          return { rows: [] };
        },
      });
      const a = createApp(pool);
      const res = await request(a)
        .get('/api/organizations/nonexistent')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
    });
  });

  describe('PUT /:id', () => {
    it('updates organization and returns mapped fields', async () => {
      const res = await request(app)
        .put(`/api/organizations/${orgId}`)
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Updated Org', type: 'charity', email: 'updated@org.com', phone: '555-9999', address: '456 Elm St', website: 'https://updated.org', bio: 'Updated bio', photo_url: '/photos/new.jpg' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('id');
      expect(res.body).toHaveProperty('name');
      expect(res.body).toHaveProperty('type');
    });

    it('returns 404 when org not found after update', async () => {
      const pool = buildMockPool({
        query: async (sql) => {
          if (sql.includes('UPDATE organizations')) return { rows: [] };
          if (sql.includes('SELECT o.*') && sql.includes('WHERE o.id')) return { rows: [] };
          return { rows: [] };
        },
      });
      const a = createApp(pool);
      const res = await request(a)
        .put('/api/organizations/nonexistent')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Test' });
      expect(res.statusCode).toBe(404);
    });
  });

  describe('DELETE /:id', () => {
    it('deletes an organization', async () => {
      const res = await request(app)
        .delete(`/api/organizations/${orgId}`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('deleted', true);
    });

    it('returns 404 when org not found', async () => {
      const pool = buildMockPool({
        query: async (sql) => {
          if (sql.includes('DELETE FROM organizations')) return { rows: [] };
          return { rows: [] };
        },
      });
      const a = createApp(pool);
      const res = await request(a)
        .delete('/api/organizations/nonexistent')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
    });
  });

  describe('POST /:id/photo', () => {
    it('returns photo upload response', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/photo`)
        .send({});
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('photo_url');
    });
  });

  describe('GET /:orgId/members', () => {
    it('returns member list with user details', async () => {
      const res = await request(app)
        .get(`/api/organizations/${orgId}/members`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      const member = res.body[0];
      expect(member).toHaveProperty('id');
      expect(member).toHaveProperty('user_id');
      expect(member).toHaveProperty('email');
      expect(member).toHaveProperty('first_name');
      expect(member).toHaveProperty('last_name');
      expect(member).toHaveProperty('photo_url');
      expect(member).toHaveProperty('role');
      expect(member).toHaveProperty('created_at');
    });
  });

  describe('POST /:id/invite', () => {
    it('invites a user by email', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/invite`)
        .set('Authorization', `Bearer ${token}`)
        .send({ email: 'invite@example.com', role: 'member' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('success', true);
      expect(res.body).toHaveProperty('user_id');
    });

    it('returns 400 when email missing', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/invite`)
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error', 'Email is required');
    });

    it('returns 404 when user not found', async () => {
      const pool = buildMockPool({
        query: async (sql) => {
          if (sql.includes('SELECT id FROM users WHERE email')) return { rows: [] };
          return { rows: [] };
        },
      });
      const a = createApp(pool);
      const res = await request(a)
        .post(`/api/organizations/${orgId}/invite`)
        .set('Authorization', `Bearer ${token}`)
        .send({ email: 'unknown@example.com' });
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error', 'User not found');
    });
  });

  describe('PUT /:orgId/members/:userId/role', () => {
    it('updates member role', async () => {
      const res = await request(app)
        .put(`/api/organizations/${orgId}/members/${memberId}/role`)
        .set('Authorization', `Bearer ${token}`)
        .send({ role: 'admin' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('role');
    });

    it('returns 404 when member not found', async () => {
      const pool = buildMockPool({
        query: async (sql) => {
          if (sql.includes('UPDATE organization_users SET role = $1')) return { rows: [] };
          return { rows: [] };
        },
      });
      const a = createApp(pool);
      const res = await request(a)
        .put(`/api/organizations/${orgId}/members/nonexistent/role`)
        .set('Authorization', `Bearer ${token}`)
        .send({ role: 'admin' });
      expect(res.statusCode).toBe(404);
    });
  });

  describe('DELETE /:orgId/members/me', () => {
    it('leaves organization', async () => {
      const res = await request(app)
        .delete(`/api/organizations/${orgId}/members/me`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Left organization');
    });
  });

  describe('DELETE /:orgId/members/:userId', () => {
    it('removes a member', async () => {
      const res = await request(app)
        .delete(`/api/organizations/${orgId}/members/${memberId}`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Member removed');
    });
  });

  describe('GET /:orgId/pets', () => {
    it('returns pets for organization', async () => {
      const res = await request(app)
        .get(`/api/organizations/${orgId}/pets`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      const pet = res.body[0];
      expect(pet).toHaveProperty('id');
      expect(pet).toHaveProperty('name');
      expect(pet).toHaveProperty('species');
      expect(pet).toHaveProperty('breed');
      expect(pet).toHaveProperty('organization_id');
    });
  });

  describe('POST /:orgId/pets', () => {
    it('adds pet to organization', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/pets`)
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(201);
    });
  });

  describe('GET /:orgId/archived', () => {
    it('returns archived pets for organization', async () => {
      const res = await request(app)
        .get(`/api/organizations/${orgId}/archived`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  describe('Error handling', () => {
    it('returns 500 when database throws on GET /', async () => {
      const pool = buildMockPool({
        query: async () => { throw new Error('DB error'); },
      });
      const a = createApp(pool);
      const res = await request(a)
        .get('/api/organizations')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(500);
      expect(res.body).toHaveProperty('error');
    });
  });

  describe('Org field mapping edge cases', () => {
    it('defaults type to professional when missing', async () => {
      const pool = buildMockPool({
        query: async (sql) => {
          if (sql.includes('SELECT o.*') && sql.includes('ORDER BY')) {
            return { rows: [makeOrgRow({ type: undefined })] };
          }
          return { rows: [] };
        },
      });
      const a = createApp(pool);
      const res = await request(a)
        .get('/api/organizations')
        .set('Authorization', `Bearer ${token}`);
      expect(res.body[0].type).toBe('professional');
    });

    it('defaults bio to empty string when null', async () => {
      const pool = buildMockPool({
        query: async (sql) => {
          if (sql.includes('SELECT o.*') && sql.includes('ORDER BY')) {
            return { rows: [makeOrgRow({ bio: null })] };
          }
          return { rows: [] };
        },
      });
      const a = createApp(pool);
      const res = await request(a)
        .get('/api/organizations')
        .set('Authorization', `Bearer ${token}`);
      expect(res.body[0].bio).toBe('');
    });

    it('parses member_count as number', async () => {
      const pool = buildMockPool({
        query: async (sql) => {
          if (sql.includes('SELECT o.*') && sql.includes('ORDER BY')) {
            return { rows: [makeOrgRow({ member_count: '5' })] };
          }
          return { rows: [] };
        },
      });
      const a = createApp(pool);
      const res = await request(a)
        .get('/api/organizations')
        .set('Authorization', `Bearer ${token}`);
      expect(res.body[0].member_count).toBe(5);
      expect(typeof res.body[0].member_count).toBe('number');
    });
  });
});
