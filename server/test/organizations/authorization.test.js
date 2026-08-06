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

  describe('Authorization guards (membership / role)', () => {
      it('GET /:orgId/members returns 403 for a non-member', async () => {
        const a = createApp(buildMockPool({ memberRole: null }));
        const res = await request(a)
          .get(`/api/organizations/${orgId}/members`)
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(403);
      });
  
      it('GET /:orgId/pets returns 403 for a non-member', async () => {
        const a = createApp(buildMockPool({ memberRole: null }));
        const res = await request(a)
          .get(`/api/organizations/${orgId}/pets`)
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(403);
      });
  
      it('GET /:orgId/archived returns 403 for a non-member', async () => {
        const a = createApp(buildMockPool({ memberRole: null }));
        const res = await request(a)
          .get(`/api/organizations/${orgId}/archived`)
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(403);
      });
  
      it('PUT /:id returns 403 for a non-admin member', async () => {
        const a = createApp(buildMockPool({ memberRole: 'foster' }));
        const res = await request(a)
          .put(`/api/organizations/${orgId}`)
          .set('Authorization', `Bearer ${token}`)
          .send({ name: 'Hijack' });
        expect(res.statusCode).toBe(403);
      });
  
      it('DELETE /:id returns 403 for a non-member', async () => {
        const a = createApp(buildMockPool({ memberRole: null }));
        const res = await request(a)
          .delete(`/api/organizations/${orgId}`)
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(403);
      });
  
      it('POST /:id/invite returns 403 for a non-admin member', async () => {
        const a = createApp(buildMockPool({ memberRole: 'foster' }));
        const res = await request(a)
          .post(`/api/organizations/${orgId}/invite`)
          .set('Authorization', `Bearer ${token}`)
          .send({ email: 'x@y.com', role: 'admin' });
        expect(res.statusCode).toBe(403);
      });
  
      it('POST /:id/invite rejects an invalid role with 400', async () => {
        const res = await request(app)
          .post(`/api/organizations/${orgId}/invite`)
          .set('Authorization', `Bearer ${token}`)
          .send({ email: 'x@y.com', role: 'pending_super_admin' });
        expect(res.statusCode).toBe(400);
      });
  
      it('PUT /:id returns 403 for org admin (super admin only)', async () => {
        const a = createApp(buildMockPool({ memberRole: 'admin' }));
        const res = await request(a)
          .put(`/api/organizations/${orgId}`)
          .set('Authorization', `Bearer ${token}`)
          .send({ name: 'Hijack' });
        expect(res.statusCode).toBe(403);
      });
  
      it('DELETE /:id returns 403 for org admin (super admin only)', async () => {
        const a = createApp(buildMockPool({ memberRole: 'admin' }));
        const res = await request(a)
          .delete(`/api/organizations/${orgId}`)
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(403);
      });
  
      it('GET /:orgId/members returns 403 for foster', async () => {
        const a = createApp(buildMockPool({ memberRole: 'foster' }));
        const res = await request(a)
          .get(`/api/organizations/${orgId}/members`)
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(403);
      });
  
      it('GET /:orgId/pets returns 403 for foster', async () => {
        const a = createApp(buildMockPool({ memberRole: 'foster' }));
        const res = await request(a)
          .get(`/api/organizations/${orgId}/pets`)
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(403);
      });
  
      it('GET /:orgId/archived returns 403 for foster', async () => {
        const a = createApp(buildMockPool({ memberRole: 'foster' }));
        const res = await request(a)
          .get(`/api/organizations/${orgId}/archived`)
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(403);
      });
  
      it('GET /:id returns org for foster (contact access)', async () => {
        const a = createApp(buildMockPool({ memberRole: 'foster' }));
        const res = await request(a)
          .get(`/api/organizations/${orgId}`)
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(200);
        expect(res.body).toHaveProperty('email');
      });
  
      it('POST /:id/invite succeeds for org admin', async () => {
        const a = createApp(buildMockPool({ memberRole: 'admin' }));
        const res = await request(a)
          .post(`/api/organizations/${orgId}/invite`)
          .set('Authorization', `Bearer ${token}`)
          .send({ email: 'x@y.com', role: 'associate' });
        expect(res.statusCode).toBe(200);
      });
  
      it('POST /:id/invite returns 403 when admin invites super_admin', async () => {
        const a = createApp(buildMockPool({ memberRole: 'admin' }));
        const res = await request(a)
          .post(`/api/organizations/${orgId}/invite`)
          .set('Authorization', `Bearer ${token}`)
          .send({ email: 'x@y.com', role: 'super_admin' });
        expect(res.statusCode).toBe(403);
      });
  
      it('PUT /:orgId/members/:userId/role returns 403 when admin assigns super_admin', async () => {
        const a = createApp(buildMockPool({ memberRole: 'admin' }));
        const res = await request(a)
          .put(`/api/organizations/${orgId}/members/${memberId}/role`)
          .set('Authorization', `Bearer ${token}`)
          .send({ role: 'super_admin' });
        expect(res.statusCode).toBe(403);
      });
    });
});
