import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const ownerId = 'owner-id';
const orgViewerId = 'org-viewer-id';
const collaboratorId = 'collab-id';
const petId = 'pet-1';
const orgId = 'org-1';

const ownerToken = jwt.sign({ id: ownerId, email: 'owner@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgViewerToken = jwt.sign({ id: orgViewerId, email: 'viewer@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const collaboratorToken = jwt.sign({ id: collaboratorId, email: 'collab@example.com' }, JWT_SECRET, { expiresIn: '1h' });

function buildMockPool() {
  const collaboratorAccess = new Set([`${petId}:${collaboratorId}`]);
  const orgViewerAccess = new Set([`${orgId}:${orgViewerId}`]);

  const handler = async (sql, params) => {
    if (sql === 'BEGIN') return { command: 'BEGIN', rows: [] };
    if (sql === 'COMMIT') return { command: 'COMMIT', rows: [] };
    if (sql === 'ROLLBACK') return { command: 'ROLLBACK', rows: [] };

    if (sql.includes('SELECT home_timezone FROM pets')) {
      return { rows: [{ home_timezone: 'UTC' }] };
    }

    if (sql.includes('FROM health_entries') && sql.includes('weight_monitoring')) {
      return { rows: [] };
    }

    if (sql.includes('FROM pets WHERE id = $1') && sql.includes('weight_reference')) {
      return { rows: [{ weight_reference_value: null }] };
    }

    if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2 LIMIT 1')) {
      const [pid, uid] = params;
      return { rows: uid === ownerId && pid === petId ? [{ '?column?': 1 }] : [] };
    }

    if (sql.startsWith('SELECT 1 FROM pet_access')) {
      const [pid, uid] = params;
      return { rows: collaboratorAccess.has(`${pid}:${uid}`) ? [{ '?column?': 1 }] : [] };
    }

    if (sql.includes('JOIN organization_users ou')) {
      const [, uid] = params;
      if (uid !== orgViewerId) return { rows: [] };
      return { rows: orgViewerAccess.has(`${orgId}:${uid}`) ? [{ '?column?': 1 }] : [] };
    }

    if (sql.includes('SELECT organization_id FROM pets WHERE id = $1')) {
      return { rows: [{ organization_id: orgId }] };
    }

    if (sql.includes('INSERT INTO weight_entries')) {
      return {
        rows: [{
          id: params[0],
          pet_id: params[1],
          user_id: params[2],
          weight: params[3],
          unit: 'kg',
          date: params[4],
          notes: params[5] || '',
          health_occurrence_id: null,
          measurement_source: 'guardian',
          created_at: new Date(),
        }],
      };
    }

    if (sql.includes('UPDATE pets SET weight')) {
      return { rows: [] };
    }

    return { rows: [] };
  };

  return {
    query: handler,
    connect: async () => ({
      query: handler,
      release: () => {},
    }),
    end: async () => {},
  };
}

describe('weight fulfilment capability auth matrix (S1/S2)', () => {
  let app;

  beforeAll(() => {
    app = createApp(buildMockPool());
  });

  it('org viewer may GET fulfilment-candidates and overview', async () => {
    const candidates = await request(app)
      .get(`/api/weight-entries/fulfilment-candidates?pet_id=${petId}`)
      .set('Authorization', `Bearer ${orgViewerToken}`);
    expect(candidates.statusCode).toBe(200);
    expect(candidates.body.candidates).toEqual([]);

    const overview = await request(app)
      .get(`/api/weight-entries/overview?pet_id=${petId}`)
      .set('Authorization', `Bearer ${orgViewerToken}`);
    expect(overview.statusCode).toBe(200);
  });

  it('org viewer cannot POST fulfil', async () => {
    const res = await request(app)
      .post('/api/weight-entries')
      .set('Authorization', `Bearer ${orgViewerToken}`)
      .send({
        pet_id: petId,
        weight: 10,
        fulfils_occurrence_id: 'occ-1',
      });
    expect(res.statusCode).toBe(403);
  });

  it('collaborator may POST standalone weight', async () => {
    const res = await request(app)
      .post('/api/weight-entries')
      .set('Authorization', `Bearer ${collaboratorToken}`)
      .send({ pet_id: petId, weight: 10, unit: 'kg', date: '2026-02-01' });
    expect(res.statusCode).toBe(201);
  });
});
