import request from 'supertest';

import { createApp } from '../../bin/server.js';
import { createMockPool, petId, token, userId } from '../pets/helpers.js';

function authHeader() {
  return { Authorization: `Bearer ${token}` };
}

describe('health entry absence-context API', () => {
  const entryId = 'entry-1';

  it('GET /api/health-entries/:id/absence-context returns 401 without auth', async () => {
    const app = createApp(createMockPool(async () => ({ rows: [] })));
    const res = await request(app).get(`/api/health-entries/${entryId}/absence-context`);
    expect(res.statusCode).toBe(401);
  });

  it('GET returns 404 when entry missing', async () => {
    const app = createApp(
      createMockPool(async (sql) => {
        if (sql.includes('FROM health_entries WHERE id')) {
          return { rows: [] };
        }
        return { rows: [] };
      })
    );
    const res = await request(app)
      .get(`/api/health-entries/${entryId}/absence-context`)
      .set(authHeader());
    expect(res.statusCode).toBe(404);
  });
});
