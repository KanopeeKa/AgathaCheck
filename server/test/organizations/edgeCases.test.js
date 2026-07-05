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
