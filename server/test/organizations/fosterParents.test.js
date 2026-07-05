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

  describe('Foster parents directory', () => {
      it('GET /:orgId/foster-parents returns members and external foster parents', async () => {
        const res = await request(app)
          .get(`/api/organizations/${orgId}/foster-parents`)
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(200);
        expect(Array.isArray(res.body)).toBe(true);
        expect(res.body.length).toBe(2);
        const member = res.body.find((r) => r.kind === 'member');
        const external = res.body.find((r) => r.kind === 'external');
        expect(member).toMatchObject({
          user_id: 'foster-user-1',
          display_name: 'Jane Foster',
          role: 'foster',
          active_pet_count: 2,
        });
        expect(member.active_pets).toEqual([
          { pet_id: 'pet-a', pet_name: 'Max', status: 'in_progress' },
        ]);
        expect(external).toMatchObject({
          display_name: 'Off-app Parent',
          email: 'offapp@example.com',
          active_pet_count: 0,
        });
      });
  
      it('GET /:orgId/foster-parents returns 403 for foster', async () => {
        const a = createApp(buildMockPool({ memberRole: 'foster' }));
        const res = await request(a)
          .get(`/api/organizations/${orgId}/foster-parents`)
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(403);
      });
  
      it('POST /:orgId/foster-parents creates an external foster parent', async () => {
        const res = await request(app)
          .post(`/api/organizations/${orgId}/foster-parents`)
          .set('Authorization', `Bearer ${token}`)
          .send({
            display_name: 'New Parent',
            email: 'new@example.com',
            lawful_basis_confirmed: true,
          });
        expect(res.statusCode).toBe(201);
        expect(res.body).toMatchObject({
          kind: 'external',
          display_name: 'New Parent',
          email: 'new@example.com',
          active_pet_count: 0,
        });
      });
  
      it('POST /:orgId/foster-parents returns 400 without lawful basis confirmation', async () => {
        const res = await request(app)
          .post(`/api/organizations/${orgId}/foster-parents`)
          .set('Authorization', `Bearer ${token}`)
          .send({ display_name: 'New Parent', email: 'new@example.com' });
        expect(res.statusCode).toBe(400);
      });
  
      it('GET /:orgId/people returns unified people directory', async () => {
        const res = await request(app)
          .get(`/api/organizations/${orgId}/people`)
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(200);
        expect(Array.isArray(res.body)).toBe(true);
        expect(res.body.length).toBeGreaterThanOrEqual(1);
        expect(res.body[0]).toMatchObject({
          kind: 'member',
          record_id: 'ou-1',
          active_foster_count: 1,
        });
      });
  
      it('POST /:orgId/foster-parents returns 400 without display name', async () => {
        const res = await request(app)
          .post(`/api/organizations/${orgId}/foster-parents`)
          .set('Authorization', `Bearer ${token}`)
          .send({ email: 'x@y.com' });
        expect(res.statusCode).toBe(400);
      });
  
      it('PUT /:orgId/foster-parents/:id updates an external foster parent', async () => {
        const res = await request(app)
          .put(`/api/organizations/${orgId}/foster-parents/fp-external-1`)
          .set('Authorization', `Bearer ${token}`)
          .send({
            display_name: 'Updated Parent',
            email: 'updated@example.com',
            phone: '555-1111',
            notes: 'Updated',
          });
        expect(res.statusCode).toBe(200);
        expect(res.body.display_name).toBe('Updated Parent');
      });
  
      it('DELETE /:orgId/foster-parents/:id removes an external foster parent', async () => {
        const res = await request(app)
          .delete(`/api/organizations/${orgId}/foster-parents/fp-external-1`)
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(200);
        expect(res.body).toMatchObject({ deleted: true });
      });
  
      it('POST /:orgId/foster-parents returns 400 without email', async () => {
        const res = await request(app)
          .post(`/api/organizations/${orgId}/foster-parents`)
          .set('Authorization', `Bearer ${token}`)
          .send({
            display_name: 'New Parent',
            lawful_basis_confirmed: true,
          });
        expect(res.statusCode).toBe(400);
        expect(res.body.error).toMatch(/email/i);
      });
  
      it('PUT /:orgId/foster-parents/:id returns 404 when not found', async () => {
        const pool = buildMockPool({
          query: async (sql, params) => {
            if (sql.includes('SELECT role FROM organization_users WHERE organization_id')) {
              return { rows: [{ role: 'super_admin' }] };
            }
            if (sql.includes('UPDATE org_foster_parents')) {
              return { rows: [] };
            }
            return { rows: [] };
          },
        });
        const localApp = createApp(pool);
        const res = await request(localApp)
          .put(`/api/organizations/${orgId}/foster-parents/missing-id`)
          .set('Authorization', `Bearer ${token}`)
          .send({ display_name: 'Updated Parent' });
        expect(res.statusCode).toBe(404);
      });
  
      it('DELETE /:orgId/foster-parents/:id returns 404 when not found', async () => {
        const pool = buildMockPool({
          query: async (sql) => {
            if (sql.includes('SELECT role FROM organization_users WHERE organization_id')) {
              return { rows: [{ role: 'super_admin' }] };
            }
            if (sql.includes('DELETE FROM org_foster_parents')) {
              return { rows: [] };
            }
            return { rows: [] };
          },
        });
        const localApp = createApp(pool);
        const res = await request(localApp)
          .delete(`/api/organizations/${orgId}/foster-parents/missing-id`)
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(404);
      });
  
      it('PUT /:orgId/foster-parents/:id returns 400 without display name', async () => {
        const res = await request(app)
          .put(`/api/organizations/${orgId}/foster-parents/fp-external-1`)
          .set('Authorization', `Bearer ${token}`)
          .send({ email: 'x@y.com' });
        expect(res.statusCode).toBe(400);
      });
    });
});
