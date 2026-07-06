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
          .send({ email: 'invite@example.com', role: 'admin' });
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
          .send({ role: 'super_admin' });
        expect(res.statusCode).toBe(200);
        expect(res.body).toHaveProperty('role');
      });
  
      it('rejects an invalid role with 400', async () => {
        const res = await request(app)
          .put(`/api/organizations/${orgId}/members/${memberId}/role`)
          .set('Authorization', `Bearer ${token}`)
          .send({ role: 'pending_super_admin' });
        expect(res.statusCode).toBe(400);
      });
  
      it('returns 403 for a non-admin member', async () => {
        const a = createApp(buildMockPool({ memberRole: 'foster' }));
        const res = await request(a)
          .put(`/api/organizations/${orgId}/members/${memberId}/role`)
          .set('Authorization', `Bearer ${token}`)
          .send({ role: 'super_admin' });
        expect(res.statusCode).toBe(403);
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
          .send({ role: 'super_admin' });
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
});
