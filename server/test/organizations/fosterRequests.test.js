import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import { buildMockPool } from './helpers.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const adminUserId = 'test-user-id';
const fosterUserId = 'foster-user-1';
const adminToken = jwt.sign(
  { id: adminUserId, email: 'test@example.com' },
  JWT_SECRET,
  { expiresIn: '1h' },
);
const fosterToken = jwt.sign(
  { id: fosterUserId, email: 'jane@example.com' },
  JWT_SECRET,
  { expiresIn: '1h' },
);
const orgId = 'org-1';

describe('Organizations API', () => {
  let app;

  beforeAll(() => {
    app = createApp(buildMockPool());
  });

  describe('Foster requests', () => {
    it('GET /:orgId/foster-requests lists requests for admins', async () => {
      const res = await request(app)
        .get(`/api/organizations/${orgId}/foster-requests`)
        .set('Authorization', `Bearer ${adminToken}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body[0]).toMatchObject({
        id: 'fr-sent-1',
        status: 'sent',
        message: 'Can you help with these pets?',
        target_count: 1,
      });
      expect(res.body[0].response_summary).toEqual({
        pending: 0,
        can_help: 1,
        cannot_help: 0,
      });
    });

    it('GET /:orgId/foster-requests returns 403 for foster role', async () => {
      const fosterApp = createApp(buildMockPool({ memberRole: 'foster' }));
      const res = await request(fosterApp)
        .get(`/api/organizations/${orgId}/foster-requests`)
        .set('Authorization', `Bearer ${fosterToken}`);
      expect(res.statusCode).toBe(403);
    });

    it('POST /:orgId/foster-requests creates a draft request', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/foster-requests`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          message: 'Need help this weekend',
          pet_ids: ['pet-1'],
          org_foster_parent_ids: ['fp-member-1'],
        });
      expect(res.statusCode).toBe(201);
      expect(res.body).toMatchObject({
        status: 'draft',
        message: 'Need help this weekend',
        pets: [{ pet_id: 'pet-1', pet_name: 'Buddy', species: 'dog' }],
      });
      expect(res.body.id).toBeTruthy();
      expect(res.body.responses).toEqual([]);
    });

    it('POST /:orgId/foster-requests creates and sends when send=true', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/foster-requests`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          message: 'Urgent placement needed',
          pet_ids: ['pet-1'],
          org_foster_parent_ids: ['fp-member-1'],
          send: true,
        });
      expect(res.statusCode).toBe(201);
      expect(res.body.status).toBe('sent');
    });

    it('POST /:orgId/foster-requests returns 400 without message', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/foster-requests`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          pet_ids: ['pet-1'],
          org_foster_parent_ids: ['fp-member-1'],
        });
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/message/i);
    });

    it('POST /:orgId/foster-requests returns 400 for unknown pets', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/foster-requests`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          message: 'Need help',
          pet_ids: ['pet-missing'],
          org_foster_parent_ids: ['fp-member-1'],
        });
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/pets/i);
    });

    it('POST /:orgId/foster-requests returns 400 for ineligible targets', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/foster-requests`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          message: 'Need help',
          pet_ids: ['pet-1'],
          org_foster_parent_ids: ['fp-not-approved'],
        });
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/targets/i);
    });

    it('POST /:orgId/foster-requests/:id/send sends a draft request', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/foster-requests/fr-draft-1/send`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({});
      expect(res.statusCode).toBe(200);
      expect(res.body).toMatchObject({
        id: 'fr-draft-1',
        status: 'sent',
      });
    });

    it('GET /:orgId/foster-requests/:id returns detail with pets, targets, and responses', async () => {
      const res = await request(app)
        .get(`/api/organizations/${orgId}/foster-requests/fr-sent-1`)
        .set('Authorization', `Bearer ${adminToken}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toMatchObject({
        id: 'fr-sent-1',
        status: 'sent',
        pets: [{ pet_id: 'pet-1', pet_name: 'Buddy', species: 'dog' }],
        targets: [{
          org_foster_parent_id: 'fp-member-1',
          display_name: 'Jane Foster',
        }],
      });
      expect(res.body.responses[0]).toMatchObject({
        response: 'can_help',
        earliest_availability: '2026-08-01',
      });
    });

    it('GET /:orgId/foster-requests/:id returns 404 when missing', async () => {
      const res = await request(app)
        .get(`/api/organizations/${orgId}/foster-requests/fr-missing`)
        .set('Authorization', `Bearer ${adminToken}`);
      expect(res.statusCode).toBe(404);
    });

    it('POST /:orgId/foster-requests/:id/responses records can_help from matched foster', async () => {
      const fosterApp = createApp(buildMockPool({ memberRole: 'foster' }));
      const res = await request(fosterApp)
        .post(`/api/organizations/${orgId}/foster-requests/fr-sent-1/responses`)
        .set('Authorization', `Bearer ${fosterToken}`)
        .send({
          response: 'can_help',
          earliest_availability: '2026-08-15',
          message: 'I can take them next week',
        });
      expect(res.statusCode).toBe(200);
      expect(res.body.responses[0]).toMatchObject({
        response: 'can_help',
        earliest_availability: '2026-08-15',
        message: 'I can take them next week',
      });
    });

    it('POST /:orgId/foster-requests/:id/responses returns 400 without earliest_availability for can_help', async () => {
      const fosterApp = createApp(buildMockPool({ memberRole: 'foster' }));
      const res = await request(fosterApp)
        .post(`/api/organizations/${orgId}/foster-requests/fr-sent-1/responses`)
        .set('Authorization', `Bearer ${fosterToken}`)
        .send({ response: 'can_help' });
      expect(res.statusCode).toBe(400);
    });

    it('POST /:orgId/foster-requests/:id/responses returns 404 for non-target foster', async () => {
      const fosterApp = createApp(buildMockPool({ memberRole: 'foster' }));
      const res = await request(fosterApp)
        .post(`/api/organizations/${orgId}/foster-requests/fr-sent-1/responses`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          response: 'cannot_help',
          message: 'Not available',
        });
      expect(res.statusCode).toBe(404);
    });
  });
});
