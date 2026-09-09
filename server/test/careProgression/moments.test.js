import request from 'supertest';
import { createApp } from '../../bin/server.js';
import { handlePetAccessQuery } from '../helpers/petAccessMocks.js';
import { createMockPool, petId, token, userId } from '../pets/helpers.js';

describe('care-progression moments routes', () => {
  function createTestApp(queryHandler) {
    return createApp(createMockPool(queryHandler));
  }

  it('GET pending-moments returns 401 without auth', async () => {
    const app = createTestApp(async () => ({ rows: [] }));
    const res = await request(app).get(`/api/pets/${petId}/care-progression/pending-moments`);
    expect(res.statusCode).toBe(401);
  });

  it('GET pending-moments returns bundle for authorised guardian', async () => {
    const achievedAt = new Date('2026-09-09T12:00:00.000Z');
    const bundleId = 'bundle-1';
    const app = createTestApp(async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
      if (access) return access;
      if (sql.includes('FROM pets p') && sql.includes('WHERE p.id = $1')) {
        return { rows: [{ id: petId }] };
      }
      if (sql.includes('MAX(cmp.shown_at)')) return { rows: [{ last_shown_at: null }] };
      if (sql.includes('NOT EXISTS') && sql.includes('care_milestone_presentations')) {
        return {
          rows: [{
            id: 'ms-1',
            pet_id: petId,
            milestone_type: 'weight_monitoring_established',
            care_family: 'weight_monitoring',
            source_entity_id: 'he-weight',
            achieved_at: achievedAt,
            policy_version: '1.0.0',
            bundle_id: bundleId,
          }],
        };
      }
      return { rows: [] };
    });

    const res = await request(app)
      .get(`/api/pets/${petId}/care-progression/pending-moments`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.moments).toHaveLength(1);
    expect(res.body.moments[0].bundle_id).toBe(bundleId);
  });

  it('POST acknowledge-presented inserts presentation rows', async () => {
    const bundleId = 'bundle-ack';
    const inserts = [];
    const app = createTestApp(async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
      if (access) return access;
      if (sql.includes('FROM pets p') && sql.includes('WHERE p.id = $1')) {
        return { rows: [{ id: petId }] };
      }
      if (sql.includes('SELECT id FROM care_milestones')) {
        return { rows: [{ id: 'ms-1' }, { id: 'ms-2' }] };
      }
      if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') return { rows: [] };
      if (sql.includes('INSERT INTO care_milestone_presentations')) {
        inserts.push(params);
        return { rows: [] };
      }
      return { rows: [] };
    });

    const res = await request(app)
      .post(`/api/pets/${petId}/care-progression/moments/${bundleId}/acknowledge-presented`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.acknowledged).toBe(true);
    expect(inserts).toHaveLength(2);
  });

  it('POST acknowledge-presented returns 404 for unknown bundle', async () => {
    const app = createTestApp(async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
      if (access) return access;
      if (sql.includes('FROM pets p') && sql.includes('WHERE p.id = $1')) {
        return { rows: [{ id: petId }] };
      }
      if (sql.includes('SELECT id FROM care_milestones')) return { rows: [] };
      return { rows: [] };
    });

    const res = await request(app)
      .post(`/api/pets/${petId}/care-progression/moments/missing/acknowledge-presented`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(404);
  });
});
