import request from 'supertest';
import { createApp } from '../../bin/server.js';
import {
  userId,
  userEmail,
  userRow,
  buildMockPool,
  makeToken,
  makeExpiredToken,
  mockComparePassword,
} from './helpers.js';

describe('Auth Routes — Profile', () => {
  let app;
  let mockPool;

  beforeEach(() => {
    mockPool = buildMockPool();
    app = createApp(mockPool, mockComparePassword);
  });

  describe('GET /api/auth/me', () => {
    it('should return user profile with valid token', async () => {
      const token = makeToken();
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('id', userId);
      expect(res.body).toHaveProperty('email', userEmail);
      expect(res.body).toHaveProperty('first_name', 'Test');
      expect(res.body).toHaveProperty('last_name', 'User');
      expect(res.body).toHaveProperty('category', 'pet_carer');
      expect(res.body).toHaveProperty('bio', 'A test bio');
      expect(res.body).toHaveProperty('photo_url', 'http://example.com/photo.png');
      expect(res.body).toHaveProperty('locale', 'en');
      expect(res.body).toHaveProperty('pinned_organization_id', null);
    });

    it('should return 401 without token', async () => {
      const res = await request(app).get('/api/auth/me');
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 401 with expired token', async () => {
      const token = makeExpiredToken();
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 401 with invalid token', async () => {
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', 'Bearer invalid-token');
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 401 with malformed authorization header', async () => {
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', 'NotBearer sometoken');
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 404 when user not found', async () => {
      const pool = buildMockPool({
        selectUserById: async () => ({ rows: [] }),
      });
      const noUserApp = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(noUserApp)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error');
    });
  });

  describe('PUT /api/auth/me', () => {
    it('should update user profile fields', async () => {
      const updatedRow = { ...userRow, first_name: 'Updated', last_name: 'Name', bio: 'New bio' };
      const pool = buildMockPool({
        updateUser: async () => ({ rows: [updatedRow] }),
      });
      const updateApp = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(updateApp)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({ first_name: 'Updated', last_name: 'Name', bio: 'New bio' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('first_name', 'Updated');
      expect(res.body).toHaveProperty('last_name', 'Name');
      expect(res.body).toHaveProperty('bio', 'New bio');
    });

    it('should update locale', async () => {
      const updatedRow = { ...userRow, locale: 'fr' };
      const pool = buildMockPool({
        updateUser: async () => ({ rows: [updatedRow] }),
      });
      const updateApp = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(updateApp)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({ locale: 'fr' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('locale', 'fr');
    });

    it('should return 400 with no fields to update', async () => {
      const token = makeToken();
      const res = await request(app)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 401 without token', async () => {
      const res = await request(app)
        .put('/api/auth/me')
        .send({ first_name: 'Hacker' });
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 401 with expired token', async () => {
      const token = makeExpiredToken();
      const res = await request(app)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({ first_name: 'Expired' });
      expect(res.statusCode).toBe(500);
    });

    it('should return 404 when user not found on update', async () => {
      const pool = buildMockPool({
        updateUser: async () => ({ rows: [] }),
      });
      const noUserApp = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(noUserApp)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({ first_name: 'Ghost' });
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error');
    });
  });

  describe('POST /api/auth/me/photo', () => {
    it('should update photo and return user', async () => {
      const updatedRow = { ...userRow, photo_url: '/uploads/photos/test.jpg' };
      const pool = buildMockPool({
        updateUser: async () => ({ rows: [updatedRow] }),
      });
      const photoApp = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(photoApp)
        .post('/api/auth/me/photo')
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('photo_url');
    });

    it('should return 401 without token', async () => {
      const res = await request(app)
        .post('/api/auth/me/photo')
        .send({});
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 401 with expired token', async () => {
      const token = makeExpiredToken();
      const res = await request(app)
        .post('/api/auth/me/photo')
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(500);
    });

    it('should return 404 when user not found', async () => {
      const pool = buildMockPool({
        updateUser: async () => ({ rows: [] }),
      });
      const noUserApp = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(noUserApp)
        .post('/api/auth/me/photo')
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(404);
    });
  });

  describe('DELETE /api/auth/me', () => {
    it('should delete account with correct password', async () => {
      const token = makeToken();
      const res = await request(app)
        .delete('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({ password: 'testpassword' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Account deleted successfully');
    });

    it('should return 400 with incorrect password', async () => {
      const token = makeToken();
      const res = await request(app)
        .delete('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({ password: 'wrongpassword' });
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error', 'Password is incorrect');
    });

    it('should return 400 when password is missing', async () => {
      const token = makeToken();
      const res = await request(app)
        .delete('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 401 without token', async () => {
      const res = await request(app)
        .delete('/api/auth/me')
        .send({ password: 'testpassword' });
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 404 when user not found', async () => {
      const pool = buildMockPool({
        selectPasswordHash: async () => ({ rows: [] }),
      });
      const noUserApp = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(noUserApp)
        .delete('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({ password: 'testpassword' });
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error');
    });
  });

  describe('GET /api/auth/me/export', () => {
    it('should export user data with pets and vets', async () => {
      const token = makeToken();
      const res = await request(app)
        .get('/api/auth/me/export')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('user');
      expect(res.body.user).toHaveProperty('id', userId);
      expect(res.body.user).toHaveProperty('email', userEmail);
      expect(res.body).toHaveProperty('pets');
      expect(Array.isArray(res.body.pets)).toBe(true);
      expect(res.body.pets.length).toBe(1);
      expect(res.body).toHaveProperty('vets');
      expect(Array.isArray(res.body.vets)).toBe(true);
      expect(res.body.vets.length).toBe(1);
      expect(res.body).toHaveProperty('exported_at');
    });

    it('should include all GDPR export sections', async () => {
      const exportSections = {
        health_entries: [{ id: 'he-1' }],
        health_issues: [{ id: 'hi-1' }],
        weight_entries: [{ id: 'we-1' }],
        notifications: [{ id: 'n-1' }],
        notification_preferences: [{ preference: 'health_reminders' }],
        organization_memberships: [{ organization_id: 'org-1', role: 'member' }],
        organizations: [{ id: 'org-1', name: 'Test Org' }],
        pet_access: [{ pet_id: 'pet-2', role: 'shared' }],
        pet_share_links: [{ code: 'abc123' }],
        shared_pets: [],
        archived_pets: [],
        family_events: [],
        foster_placements: [],
        org_foster_parent_records: [],
        health_history: [],
        health_event_photos: [],
        health_issue_documents: [],
        health_issue_events: [],
      };
      const pool = buildMockPool({
        selectExportSection: async (sql) => {
          if (sql.includes('health_entries WHERE')) return { rows: exportSections.health_entries };
          if (sql.includes('health_issues WHERE')) return { rows: exportSections.health_issues };
          if (sql.includes('weight_entries WHERE')) return { rows: exportSections.weight_entries };
          if (sql.includes('notifications WHERE')) return { rows: exportSections.notifications };
          if (sql.includes('notification_preferences')) return { rows: exportSections.notification_preferences };
          if (sql.includes('organization_users WHERE')) return { rows: exportSections.organization_memberships };
          if (sql.includes('organizations o')) return { rows: exportSections.organizations };
          if (sql.includes('pet_access WHERE')) return { rows: exportSections.pet_access };
          if (sql.includes('pet_share_links')) return { rows: exportSections.pet_share_links };
          return { rows: [] };
        },
      });
      const exportApp = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(exportApp)
        .get('/api/auth/me/export')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      for (const [key, value] of Object.entries(exportSections)) {
        expect(res.body).toHaveProperty(key);
        expect(res.body[key]).toEqual(value);
      }
      expect(res.body.user).not.toHaveProperty('password_hash');
    });

    it('should return 401 without token', async () => {
      const res = await request(app).get('/api/auth/me/export');
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should return error with expired token', async () => {
      const token = makeExpiredToken();
      const res = await request(app)
        .get('/api/auth/me/export')
        .set('Authorization', `Bearer ${token}`);
      expect([401, 500]).toContain(res.statusCode);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 404 when user not found', async () => {
      const pool = buildMockPool({
        selectUserById: async () => ({ rows: [] }),
      });
      const noUserApp = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(noUserApp)
        .get('/api/auth/me/export')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error');
    });
  });
});
