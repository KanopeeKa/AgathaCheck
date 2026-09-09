import request from 'supertest';
import { createApp } from '../../bin/server.js';
import { handlePetAccessQuery } from '../helpers/petAccessMocks.js';
import { createMockPool, petId, token, userId } from '../pets/helpers.js';

describe('GET /api/pets/:id/care-progression', () => {
  function createTestApp(queryHandler) {
    return createApp(createMockPool(queryHandler));
  }

  it('returns 401 without auth', async () => {
    const app = createTestApp(async () => ({ rows: [] }));
    const res = await request(app).get(`/api/pets/${petId}/care-progression`);
    expect(res.statusCode).toBe(401);
  });

  it('returns empty establishments and milestones for authorised guardian', async () => {
    const app = createTestApp(async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
      if (access) return access;
      if (sql.includes('FROM pets p') && sql.includes('WHERE p.id = $1')) {
        return { rows: [{ id: petId }] };
      }
      return { rows: [] };
    });
    const res = await request(app)
      .get(`/api/pets/${petId}/care-progression`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ establishments: [], milestones: [] });
  });

  it('returns 403 when guardian lacks health view capability', async () => {
    const app = createTestApp(async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, {
        userId,
        ownedPetIds: [],
        sharedPetIds: [],
      });
      if (access) return access;
      return { rows: [] };
    });
    const res = await request(app)
      .get(`/api/pets/${petId}/care-progression`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(403);
  });

  it('returns 404 when pet is not accessible', async () => {
    const app = createTestApp(async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
      if (access) return access;
      if (sql.includes('FROM pets p') && sql.includes('WHERE p.id = $1')) {
        return { rows: [] };
      }
      return { rows: [] };
    });
    const res = await request(app)
      .get(`/api/pets/${petId}/care-progression`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(404);
  });
});
