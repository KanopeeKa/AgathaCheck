import request from 'supertest';

import { createApp } from '../../bin/server.js';
import { token as authToken } from '../pets/helpers.js';

/**
 * H.3-4 — migrated Batch H routers must not leak raw err.message or stacks in production 5xx.
 */
describe('Migrated router 5xx redaction (H.3-4)', () => {
  const secretMessage = 'secret-leak-xyzzy-5xx';
  const pool = {
    query: async () => {
      throw new Error(secretMessage);
    },
  };

  async function expectRedacted500(getPath) {
    const prev = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';
    try {
      const app = createApp(pool);
      const res = await request(app)
        .get(getPath)
        .set('Authorization', `Bearer ${authToken}`);
      expect(res.statusCode).toBe(500);
      expect(res.body.request_id).toBeDefined();
      expect(res.body.error).toBe('Internal server error');
      expect(JSON.stringify(res.body)).not.toContain(secretMessage);
      expect(res.body.stack).toBeUndefined();
    } finally {
      process.env.NODE_ENV = prev;
    }
  }

  it('GET /api/pets', () => expectRedacted500('/api/pets'));
  it('GET /api/weight-entries/overview', () => expectRedacted500('/api/weight-entries/overview'));
  it('GET /api/health-entries', () => expectRedacted500('/api/health-entries'));
  it('GET /api/share/access', () => expectRedacted500('/api/share/access'));
  it('GET /api/planned-absences', () => expectRedacted500('/api/planned-absences'));
});
