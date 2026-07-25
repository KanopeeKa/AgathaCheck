import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import { buildMockPool } from './helpers.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';

describe('Organizations API', () => {
  let app;

  beforeAll(() => {
    app = createApp(buildMockPool());
  });

  describe('Prospects directory', () => {
    it('GET /:orgId/prospects returns org prospects', async () => {
      const res = await request(app)
        .get(`/api/organizations/${orgId}/prospects`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBe(1);
      expect(res.body[0]).toMatchObject({
        id: 'prospect-1',
        display_name: 'Adopter Prospect',
        email: 'prospect@example.com',
        phone: '555-2222',
        notes: 'Interested in cats',
        user_id: null,
        creation_source: 'manual_shelter_entry',
        retention_category: 'manual_contact',
      });
    });

    it('GET /:orgId/prospects returns 403 for foster', async () => {
      const fosterApp = createApp(buildMockPool({ memberRole: 'foster' }));
      const res = await request(fosterApp)
        .get(`/api/organizations/${orgId}/prospects`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(403);
    });

    it('POST /:orgId/prospects creates a manual prospect', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/prospects`)
        .set('Authorization', `Bearer ${token}`)
        .send({
          display_name: 'New Prospect',
          email: 'newprospect@example.com',
          lawful_basis_confirmed: true,
        });
      expect(res.statusCode).toBe(201);
      expect(res.body).toMatchObject({
        display_name: 'New Prospect',
        email: 'newprospect@example.com',
        user_id: null,
        creation_source: 'manual_shelter_entry',
        retention_category: 'manual_contact',
      });
      expect(res.body.lawful_basis_attested_at).toBeTruthy();
    });

    it('POST /:orgId/prospects returns 400 without lawful basis confirmation', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/prospects`)
        .set('Authorization', `Bearer ${token}`)
        .send({ display_name: 'New Prospect', email: 'newprospect@example.com' });
      expect(res.statusCode).toBe(400);
    });

    it('POST /:orgId/prospects returns 400 without display name', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/prospects`)
        .set('Authorization', `Bearer ${token}`)
        .send({ email: 'x@y.com', lawful_basis_confirmed: true });
      expect(res.statusCode).toBe(400);
    });

    it('POST /:orgId/prospects returns 400 without email', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/prospects`)
        .set('Authorization', `Bearer ${token}`)
        .send({ display_name: 'New Prospect', lawful_basis_confirmed: true });
      expect(res.statusCode).toBe(400);
    });

    it('GET /:orgId/prospects/merge-suggestions returns email matches', async () => {
      const res = await request(app)
        .get(`/api/organizations/${orgId}/prospects/merge-suggestions`)
        .query({ email: 'match@example.com' })
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toEqual([{
        user_id: 'registered-user-1',
        display_name: 'Registered User',
        email: 'match@example.com',
        is_org_member: false,
      }]);
    });

    it('GET /:orgId/prospects/merge-suggestions returns 400 without email', async () => {
      const res = await request(app)
        .get(`/api/organizations/${orgId}/prospects/merge-suggestions`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(400);
    });

    it('PATCH /:orgId/prospects/:id/contact updates contact fields', async () => {
      const res = await request(app)
        .patch(`/api/organizations/${orgId}/prospects/prospect-1/contact`)
        .set('Authorization', `Bearer ${token}`)
        .send({
          display_name: 'Updated Prospect',
          email: 'updated@example.com',
          phone: '555-3333',
        });
      expect(res.statusCode).toBe(200);
      expect(res.body).toMatchObject({
        display_name: 'Updated Prospect',
        email: 'updated@example.com',
        phone: '555-3333',
      });
    });

    it('PATCH /:orgId/prospects/:id/contact returns 400 without display name', async () => {
      const res = await request(app)
        .patch(`/api/organizations/${orgId}/prospects/prospect-1/contact`)
        .set('Authorization', `Bearer ${token}`)
        .send({ email: 'updated@example.com' });
      expect(res.statusCode).toBe(400);
    });

    it('POST /:orgId/prospects/:id/merge links prospect to registered user', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/prospects/prospect-1/merge`)
        .set('Authorization', `Bearer ${token}`)
        .send({ target_user_id: 'registered-user-1' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toMatchObject({
        user_id: 'registered-user-1',
        retention_category: 'prospect_relationship',
      });
    });

    it('POST /:orgId/prospects/:id/merge returns 400 without target_user_id', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/prospects/prospect-1/merge`)
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(400);
    });
  });
});
