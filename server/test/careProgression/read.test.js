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

  it('returns establishments and milestones for authorised guardian', async () => {
    const establishedAt = new Date('2026-09-09T12:00:00.000Z');
    const achievedAt = new Date('2026-09-09T12:05:00.000Z');
    const app = createTestApp(async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
      if (access) return access;
      if (sql.includes('FROM pets p') && sql.includes('WHERE p.id = $1')) {
        return { rows: [{ id: petId }] };
      }
      if (sql.includes('FROM care_establishments') && sql.includes('WHERE pet_id = $1')) {
        return {
          rows: [{
            id: 'est-1',
            care_family: 'weight_monitoring',
            health_entry_id: 'he-weight',
            established_at: establishedAt,
            policy_version: '1.0.0',
          }],
        };
      }
      if (sql.includes('FROM care_milestones') && sql.includes('WHERE pet_id = $1')) {
        return {
          rows: [{
            id: 'ms-1',
            milestone_type: 'weight_monitoring_established',
            care_family: 'weight_monitoring',
            source_entity_id: 'he-weight',
            achieved_at: achievedAt,
            policy_version: '1.0.0',
            bundle_id: 'bundle-1',
          }],
        };
      }
      return { rows: [] };
    });
    const res = await request(app)
      .get(`/api/pets/${petId}/care-progression`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.milestones).toEqual([{
      id: 'ms-1',
      milestone_type: 'weight_monitoring_established',
      care_family: 'weight_monitoring',
      source_entity_id: 'he-weight',
      achieved_at: achievedAt.toISOString(),
      policy_version: '1.0.0',
      bundle_id: 'bundle-1',
    }]);
    expect(res.body.establishments).toEqual([{
      id: 'est-1',
      care_family: 'weight_monitoring',
      health_entry_id: 'he-weight',
      established_at: establishedAt.toISOString(),
      policy_version: '1.0.0',
    }]);
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
