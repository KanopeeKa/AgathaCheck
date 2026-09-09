import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import { handlePetAccessQuery, handleManageEntryQuery } from '../helpers/petAccessMocks.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const petId = 'pet-1';
const entryId = 'he-weight';
const occurrenceId = 'occ-1';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

function makeWeightEntryRow(overrides = {}) {
  return {
    id: 'we-linked',
    pet_id: petId,
    user_id: userId,
    weight: 18.2,
    unit: 'kg',
    date: new Date('2026-09-09'),
    notes: '',
    measurement_source: 'guardian',
    health_occurrence_id: occurrenceId,
    created_at: new Date('2026-09-09'),
    ...overrides,
  };
}

function makeHealthEntryRow(overrides = {}) {
  return {
    id: entryId,
    pet_id: petId,
    user_id: userId,
    name: 'Weight check',
    type: 'other',
    frequency: 'monthly',
    frequency_interval: 1,
    start_date: new Date('2026-01-01'),
    next_due_date: new Date('2026-10-09'),
    care_family: 'weight_monitoring',
    care_source: 'guardian_defined',
    status: 'active',
    recurrence_anchor: 'from_completion',
    ...overrides,
  };
}

function makeOccurrenceRow(overrides = {}) {
  return {
    id: occurrenceId,
    health_entry_id: entryId,
    scheduled_date: new Date('2026-09-09'),
    scheduled_time: null,
    status: 'pending',
    completed_on: null,
    marked_at: null,
    marked_by_user_id: null,
    notes: '',
    ...overrides,
  };
}

describe('POST /api/pets/:petId/care-rhythms/:entryId/occurrences/:occurrenceId/complete-weight', () => {
  let app;
  let linkedWeight;
  let occurrence;
  let entry;
  let txDepth;

  beforeAll(() => {
    linkedWeight = null;
    occurrence = makeOccurrenceRow();
    entry = makeHealthEntryRow();
    txDepth = 0;

    const mockPool = {
      query: async (sql, params) => {
        if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
          if (sql === 'BEGIN') txDepth += 1;
          if (sql === 'COMMIT' || sql === 'ROLLBACK') txDepth = Math.max(0, txDepth - 1);
          return { rows: [] };
        }

        const access = handlePetAccessQuery(sql, params, {
          userId,
          ownedPetIds: [petId],
        });
        if (access) return access;

        const manageEntry = handleManageEntryQuery(sql, params, { tableName: 'health_entries he' });
        if (manageEntry) return manageEntry;

        if (sql.includes('FROM pets p') && sql.includes('WHERE p.id = $1')) {
          return { rows: [{ id: petId }] };
        }

        if (sql.includes('FROM health_entries he') && sql.includes('he.pet_id = $2')) {
          if (params[0] === entryId && params[1] === petId) {
            return { rows: [entry] };
          }
          return { rows: [] };
        }

        if (sql.includes('FROM health_occurrences ho') && sql.includes('ho.id = $1')) {
          if (params[0] === occurrenceId) {
            return { rows: [{ ...occurrence, marked_by_name: null }] };
          }
          return { rows: [] };
        }

        if (sql.includes('FROM weight_entries WHERE health_occurrence_id = $1')) {
          return { rows: linkedWeight ? [linkedWeight] : [] };
        }

        if (sql.includes('INSERT INTO weight_entries')) {
          linkedWeight = makeWeightEntryRow({
            id: params[0],
            weight: params[3],
            unit: params[4],
            date: new Date(params[5]),
            notes: params[6],
            measurement_source: params[7],
            health_occurrence_id: params[8],
          });
          return { rows: [linkedWeight] };
        }

        if (sql.includes('UPDATE health_occurrences SET status = \'completed\'')) {
          occurrence = {
            ...occurrence,
            status: 'completed',
            completed_on: new Date(params[0]),
            marked_at: params[1],
            marked_by_user_id: params[2],
            notes: params[3],
          };
          return { rows: [occurrence] };
        }

        if (sql.includes('SELECT next_due_date FROM health_entries WHERE id = $1')) {
          return { rows: [{ next_due_date: entry.next_due_date }] };
        }

        if (sql.includes('UPDATE pets SET weight = (')) {
          return { rows: [] };
        }

        if (sql.includes('INSERT INTO audit_events')) {
          return { rows: [{ id: 'audit-1' }] };
        }

        if (sql.includes('INSERT INTO pet_activity_events')) {
          return { rows: [{ id: 'activity-1' }] };
        }

        return { rows: [] };
      },
      connect: async () => ({
        query: async (sql, params) => mockPool.query(sql, params),
        release: () => {},
      }),
      end: async () => {},
    };

    app = createApp(mockPool);
  });

  beforeEach(() => {
    linkedWeight = null;
    occurrence = makeOccurrenceRow();
    entry = makeHealthEntryRow();
    txDepth = 0;
  });

  const path = `/api/pets/${petId}/care-rhythms/${entryId}/occurrences/${occurrenceId}/complete-weight`;
  const payload = {
    weight: 18.2,
    unit: 'kg',
    date: '2026-09-09',
    measurement_source: 'guardian',
    notes: '',
  };

  it('returns 401 without auth', async () => {
    const res = await request(app).post(path).send(payload);
    expect(res.statusCode).toBe(401);
  });

  it('creates linked weight and completes occurrence atomically', async () => {
    const res = await request(app)
      .post(path)
      .set('Authorization', `Bearer ${token}`)
      .send(payload);
    expect(res.statusCode).toBe(201);
    expect(res.body.weight_entry.health_occurrence_id).toBe(occurrenceId);
    expect(res.body.occurrence.status).toBe('completed');
    expect(res.body.next_due_date).toBe('2026-10-09');
    expect(linkedWeight).not.toBeNull();
    expect(occurrence.status).toBe('completed');
  });

  it('returns 200 for idempotent retry with same payload', async () => {
    await request(app).post(path).set('Authorization', `Bearer ${token}`).send(payload);
    const res = await request(app)
      .post(path)
      .set('Authorization', `Bearer ${token}`)
      .send(payload);
    expect(res.statusCode).toBe(200);
    expect(res.body.weight_entry.id).toBe(linkedWeight.id);
  });

  it('returns 409 when payload differs from linked weight', async () => {
    await request(app).post(path).set('Authorization', `Bearer ${token}`).send(payload);
    const res = await request(app)
      .post(path)
      .set('Authorization', `Bearer ${token}`)
      .send({ ...payload, weight: 19.0 });
    expect(res.statusCode).toBe(409);
  });

  it('returns 400 for non-weight monitoring entry', async () => {
    entry = makeHealthEntryRow({ care_family: 'dental' });
    const res = await request(app)
      .post(path)
      .set('Authorization', `Bearer ${token}`)
      .send(payload);
    expect(res.statusCode).toBe(400);
  });

  it('returns 404 when entry does not belong to pet', async () => {
    const res = await request(app)
      .post(`/api/pets/${petId}/care-rhythms/wrong-entry/occurrences/${occurrenceId}/complete-weight`)
      .set('Authorization', `Bearer ${token}`)
      .send(payload);
    expect(res.statusCode).toBe(404);
  });
});

describe('weight monitoring generic completion blocks', () => {
  it('POST occurrence complete returns 400 for weight_monitoring', async () => {
    const mockPool = {
      query: async (sql, params) => {
        const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
        if (access) return access;
        const manageEntry = handleManageEntryQuery(sql, params, { tableName: 'health_entries he' });
        if (manageEntry) return manageEntry;
        if (sql.includes('SELECT * FROM health_entries WHERE id = $1')) {
          return { rows: [makeHealthEntryRow()] };
        }
        return { rows: [] };
      },
      end: async () => {},
    };
    const app = createApp(mockPool);
    const res = await request(app)
      .post(`/api/health-entries/${entryId}/occurrences/${occurrenceId}/complete`)
      .set('Authorization', `Bearer ${token}`)
      .send({});
    expect(res.statusCode).toBe(400);
    expect(res.body.error).toMatch(/weight observation/i);
  });

  it('POST mark-taken returns 400 for weight_monitoring with pending occurrence', async () => {
    const mockPool = {
      query: async (sql, params) => {
        const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
        if (access) return access;
        const manageEntry = handleManageEntryQuery(sql, params, { tableName: 'health_entries he' });
        if (manageEntry) return manageEntry;
        if (sql.includes('SELECT he.* FROM health_entries he WHERE he.id = $1')) {
          return { rows: [makeHealthEntryRow()] };
        }
        if (sql.includes('health_occurrences WHERE health_entry_id = $1 AND status = \'pending\'')) {
          return { rows: [{ id: occurrenceId }] };
        }
        return { rows: [] };
      },
      end: async () => {},
    };
    const app = createApp(mockPool);
    const res = await request(app)
      .post(`/api/health-entries/${entryId}/mark-taken`)
      .set('Authorization', `Bearer ${token}`)
      .send({});
    expect(res.statusCode).toBe(400);
    expect(res.body.error).toMatch(/weight observation/i);
  });
});
