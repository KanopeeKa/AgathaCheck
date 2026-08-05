import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import { buildMockPool } from './helpers.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';

/** Minimal JPEG file header (FF D8 FF …). */
const JPEG_BUFFER = Buffer.from([
  0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0x00, 0x01,
]);

const REJECT_MESSAGE = 'Only JPG, PNG, and WebP images are allowed';

describe('Organization image uploads', () => {
  let app;
  let savedPhotoUrl;
  let savedLogoUrl;

  beforeAll(() => {
    const basePool = buildMockPool();
    app = createApp(
      buildMockPool({
        query: async (sql, params) => {
          if (sql.includes('UPDATE organizations SET photo_url')) {
            savedPhotoUrl = params[0];
            return { rows: [] };
          }
          if (sql.includes('UPDATE organizations SET logo_url')) {
            savedLogoUrl = params[0];
            return { rows: [] };
          }
          if (sql.includes('SELECT o.*') && sql.includes('WHERE o.id')) {
            return {
              rows: [{
                id: orgId,
                name: 'Test Org',
                type: 'professional',
                email: 'org@test.com',
                phone: '555-1234',
                address: '123 Main St',
                website: 'https://test.org',
                bio: 'A test organization',
                photo_url: savedPhotoUrl || '/photos/org.jpg',
                logo_url: savedLogoUrl || '/photos/org-logo.jpg',
                role: 'super_admin',
                member_count: '2',
                external_count: '1',
                pet_count: '1',
                created_at: new Date('2024-01-01'),
                updated_at: new Date('2024-06-01'),
              }],
            };
          }
          return basePool.query(sql, params);
        },
      }),
    );
  });

  describe('POST /:id/logo', () => {
    it('uploads a logo for an admin', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/logo`)
        .set('Authorization', `Bearer ${token}`)
        .attach('photo', JPEG_BUFFER, {
          filename: 'logo.jpg',
          contentType: 'image/jpeg',
        });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('logo_url');
      expect(String(res.body.logo_url)).toMatch(/^\/uploads\/org_logos\//);
      expect(res.body).toHaveProperty('id', orgId);
    });
  });

  describe('POST /:id/photo', () => {
    it('uploads a cover photo for an admin', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/photo`)
        .set('Authorization', `Bearer ${token}`)
        .attach('photo', JPEG_BUFFER, {
          filename: 'cover.jpg',
          contentType: 'image/jpeg',
        });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('photo_url');
      expect(String(res.body.photo_url)).toMatch(/^\/uploads\/org_photos\//);
      expect(res.body).toHaveProperty('id', orgId);
    });

    it('rejects unsupported MIME with 400 and a stable message', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/photo`)
        .set('Authorization', `Bearer ${token}`)
        .attach('photo', Buffer.from('not-an-image'), {
          filename: 'evil.exe',
          contentType: 'application/x-msdownload',
        });
      expect(res.statusCode).toBe(400);
      expect(res.body).toEqual({ error: REJECT_MESSAGE });
    });

    it('accepts application/octet-stream when buffer is a JPEG', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/photo`)
        .set('Authorization', `Bearer ${token}`)
        .attach('photo', JPEG_BUFFER, {
          filename: 'cover.jpg',
          contentType: 'application/octet-stream',
        });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('photo_url');
    });

    it('accepts empty MIME when buffer is a JPEG', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/photo`)
        .set('Authorization', `Bearer ${token}`)
        .attach('photo', JPEG_BUFFER, {
          filename: 'cover.jpg',
          contentType: '',
        });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('photo_url');
    });

    it('normalizes image/jpg alias to JPEG', async () => {
      const res = await request(app)
        .post(`/api/organizations/${orgId}/photo`)
        .set('Authorization', `Bearer ${token}`)
        .attach('photo', JPEG_BUFFER, {
          filename: 'cover.jpg',
          contentType: 'image/jpg',
        });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('photo_url');
    });
  });
});
