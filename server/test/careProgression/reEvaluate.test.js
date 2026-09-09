import request from 'supertest';
import { createApp } from '../../bin/server.js';
import { handlePetAccessQuery } from '../helpers/petAccessMocks.js';
import { createMockPool, petId, token, userId } from '../pets/helpers.js';

describe('POST /api/pets/:id/care-progression/re-evaluate', () => {
  function createTestApp(queryHandler) {
    return createApp(createMockPool(queryHandler));
  }

  it('returns 401 without auth', async () => {
    const app = createTestApp(async () => ({ rows: [] }));
    const res = await request(app)
      .post(`/api/pets/${petId}/care-progression/re-evaluate`)
      .send({});
    expect(res.statusCode).toBe(401);
  });

  it('returns evaluation results in non-production', async () => {
    const app = createTestApp(async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
      if (access) return access;
      if (sql.includes('FROM pets p') && sql.includes('WHERE p.id = $1')) {
        return { rows: [{ id: petId }] };
      }
      if (sql.includes('FROM health_entries') && sql.includes('care_family = \'weight_monitoring\'')) {
        return { rows: [] };
      }
      return { rows: [] };
    });

    const res = await request(app)
      .post(`/api/pets/${petId}/care-progression/re-evaluate`)
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.statusCode).toBe(200);
    expect(res.body.internal_only).toBe(true);
    expect(res.body.results).toEqual([]);
  });
});
