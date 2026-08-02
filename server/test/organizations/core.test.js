import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import { buildMockPool, makeOrgRow } from './helpers.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';
const memberId = 'member-user-id';
const inviteId = 'invite-1';


describe('Organizations API', () => {
  let app;

  beforeAll(() => {
    app = createApp(buildMockPool());
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
        expect(org).toHaveProperty('role', 'super_admin');
        expect(org).toHaveProperty('member_count', 2);
        expect(typeof org.member_count).toBe('number');
      });
    });
  
  describe('POST / (create)', () => {
      it('creates organization with owner role super_admin', async () => {
        const res = await request(app)
          .post('/api/organizations')
          .set('Authorization', `Bearer ${token}`)
          .send({ name: 'New Org', type: 'charity', email: 'new@org.com' });
        expect(res.statusCode).toBe(201);
        expect(res.body).toHaveProperty('name');
        expect(res.body).toHaveProperty('type');
        expect(res.body).toHaveProperty('role', 'super_admin');
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
            if (sql.includes("SELECT o.*") && sql.includes("'super_admin' as role")) {
              return { rows: [makeOrgRow({ type: 'professional', role: 'super_admin', member_count: '1', pet_count: '0' })] };
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
  
  describe('POST /join/:code (not implemented)', () => {
      it('returns 501 instead of faking a join', async () => {
        const res = await request(app)
          .post('/api/organizations/join/abc123')
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(501);
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

      it('persists discovery profile fields', async () => {
        let updateParams;
        const pool = buildMockPool({
          query: async (sql, params) => {
            if (sql.includes('UPDATE organizations SET')) {
              updateParams = params;
              return { rows: [] };
            }
            if (sql.includes('SELECT o.*') && sql.includes('WHERE o.id')) {
              return {
                rows: [{
                  id: orgId,
                  name: 'Rescue Hearts',
                  type: 'charity',
                  town: params?.[9] ?? 'Springfield',
                  administrative_area: params?.[10] ?? 'IL',
                  description: params?.[11] ?? 'A caring rescue shelter',
                  is_discoverable: params?.[12] ?? true,
                  bio: '',
                  photo_url: '',
                  logo_url: '/uploads/org_photos/rescue-hearts.png',
                  role: 'super_admin',
                  member_count: 1,
                  external_count: 0,
                  pet_count: 0,
                }],
              };
            }
            return { rows: [] };
          },
        });
        const a = createApp(pool);
        const res = await request(a)
          .put(`/api/organizations/${orgId}`)
          .set('Authorization', `Bearer ${token}`)
          .send({
            name: 'Rescue Hearts',
            type: 'charity',
            town: 'Springfield',
            administrative_area: 'IL',
            description: 'A caring rescue shelter',
            logo_url: '/uploads/org_photos/rescue-hearts.png',
            is_discoverable: true,
          });
        expect(res.statusCode).toBe(200);
        expect(updateParams[9]).toBe('Springfield');
        expect(updateParams[10]).toBe('IL');
        expect(updateParams[11]).toBe('A caring rescue shelter');
        expect(updateParams[12]).toBe(true);
        expect(res.body.town).toBe('Springfield');
        expect(res.body.is_discoverable).toBe(true);
      });

      it('persists postcode in public_profile_metadata', async () => {
        let updateParams;
        const pool = buildMockPool({
          query: async (sql, params) => {
            if (sql.includes('SELECT public_profile_metadata FROM organizations')) {
              return { rows: [{ public_profile_metadata: { postcode: 'OLD' } }] };
            }
            if (sql.includes('UPDATE organizations SET')) {
              updateParams = params;
              return { rows: [] };
            }
            if (sql.includes('SELECT o.*') && sql.includes('WHERE o.id')) {
              return {
                rows: [{
                  ...makeOrgRow(),
                  public_profile_metadata: JSON.parse(updateParams?.[13] ?? '{}'),
                }],
              };
            }
            return { rows: [] };
          },
        });
        const a = createApp(pool);
        const res = await request(a)
          .put(`/api/organizations/${orgId}`)
          .set('Authorization', `Bearer ${token}`)
          .send({
            name: 'Rescue Hearts',
            public_profile_metadata: { postcode: '62701' },
          });
        expect(res.statusCode).toBe(200);
        expect(JSON.parse(updateParams[13])).toEqual({ postcode: '62701' });
        expect(res.body.public_profile_metadata).toEqual({ postcode: '62701' });
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
      it('returns photo upload response for an admin', async () => {
        const res = await request(app)
          .post(`/api/organizations/${orgId}/photo`)
          .set('Authorization', `Bearer ${token}`)
          .attach('photo', Buffer.from('fake-image'), 'org.jpg');
        expect(res.statusCode).toBe(200);
        expect(res.body).toHaveProperty('photo_url');
        expect(res.body).toHaveProperty('id', orgId);
      });
  
      it('returns 403 for a non-admin member', async () => {
        const a = createApp(buildMockPool({ memberRole: 'foster' }));
        const res = await request(a)
          .post(`/api/organizations/${orgId}/photo`)
          .set('Authorization', `Bearer ${token}`)
          .send({});
        expect(res.statusCode).toBe(403);
      });
    });
});
