import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import { buildMockPool } from './helpers.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';

describe('Organizations API — connections permissions', () => {
  it('GET /:orgId/connections allows foster with view_connections', async () => {
    const pool = buildMockPool({
      memberRole: 'foster',
      query: async (sql) => {
        if (sql.includes('FROM org_connections')) {
          return {
            rows: [{
              id: 'conn-1',
              peer_org_id: 'org-2',
              peer_org_name: 'Partner Rescue',
              peer_org_type: 'charity',
              peer_org_email: 'partner@example.com',
              connected_at: new Date('2024-06-01'),
            }],
          };
        }
        return { rows: [] };
      },
    });
    const app = createApp(pool);
    const res = await request(app)
      .get(`/api/organizations/${orgId}/connections`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual([
      expect.objectContaining({
        peer_org_id: 'org-2',
        peer_org_name: 'Partner Rescue',
      }),
    ]);
  });

  it('GET /:orgId/connections returns 403 for non-members', async () => {
    const app = createApp(buildMockPool({ memberRole: null }));
    const res = await request(app)
      .get(`/api/organizations/${orgId}/connections`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(403);
  });
});
