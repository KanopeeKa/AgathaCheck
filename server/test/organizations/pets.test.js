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
        expect(pet).toHaveProperty('organization_name', 'Happy Paws');
      });
    });
  
  describe('POST /:orgId/pets', () => {
      it('creates an org pet when name and species are provided', async () => {
        const res = await request(app)
          .post(`/api/organizations/${orgId}/pets`)
          .set('Authorization', `Bearer ${token}`)
          .send({ name: 'New Pet', species: 'cat' });
        expect(res.statusCode).toBe(201);
        expect(res.body).toMatchObject({
          name: 'New Pet',
          species: 'cat',
          organization_id: orgId,
        });
      });
  
      it('returns 400 without name and species', async () => {
        const res = await request(app)
          .post(`/api/organizations/${orgId}/pets`)
          .set('Authorization', `Bearer ${token}`)
          .send({});
        expect(res.statusCode).toBe(400);
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
});
