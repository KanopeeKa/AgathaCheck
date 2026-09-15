import request from 'supertest';

import { createApp } from '../../bin/server.js';
import { createMockPool, petId, token, userId } from './helpers.js';

function authHeader() {
  return { Authorization: `Bearer ${token}` };
}

describe('GET /api/pets/:id/carer-candidates', () => {
  it('returns 401 without auth', async () => {
    const app = createApp(createMockPool(async () => ({ rows: [] })));
    const res = await request(app).get(`/api/pets/${petId}/carer-candidates`);
    expect(res.statusCode).toBe(401);
  });

  it('returns 403 when caller cannot manage pet', async () => {
    const app = createApp(createMockPool(async (sql) => {
      if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2 LIMIT 1')) {
        return { rows: [] };
      }
      if (sql.includes('SELECT 1 FROM pet_access')) {
        return { rows: [] };
      }
      return { rows: [] };
    }));
    const res = await request(app)
      .get(`/api/pets/${petId}/carer-candidates`)
      .set(authHeader());
    expect(res.statusCode).toBe(403);
  });

  it('returns minimal collaborator list for manageable pets', async () => {
    const app = createApp(createMockPool(async (sql) => {
      if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2 LIMIT 1')) {
        return { rows: [{ '?column?': 1 }] };
      }
      if (sql.includes('FROM pet_access pa') && sql.includes('INNER JOIN users u')) {
        return {
          rows: [{
            user_id: 'collab-1',
            first_name: 'Sarah',
            last_name: 'Miller',
            email: 'sarah@example.com',
          }],
        };
      }
      return { rows: [] };
    }));

    const res = await request(app)
      .get(`/api/pets/${petId}/carer-candidates`)
      .set(authHeader());

    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual([{
      user_id: 'collab-1',
      display_name: 'Sarah M.',
    }]);
    expect(res.body[0]).not.toHaveProperty('email');
  });
});
