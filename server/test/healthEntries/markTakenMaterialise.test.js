/**
 * Regression: POST /:id/mark-taken returned 400 "No pending occurrence" for
 * active entries whose head was never materialised (next due outside the T-1
 * window, or UAT demo rows seeded without occurrences). Mark-taken now
 * materialises the canonical head (as ensure-open does) and completes it.
 */
import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import { handlePetAccessQuery, handleManageEntryQuery } from '../helpers/petAccessMocks.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const petId = 'pet-1';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

function makeEntry(overrides = {}) {
  return {
    id: 'he-unmaterialised',
    pet_id: petId,
    user_id: userId,
    name: 'Joint supplement',
    type: 'medication',
    dosage: '1 tablet',
    frequency: 'daily',
    frequency_interval: 1,
    start_date: new Date('2020-01-01'),
    next_due_date: new Date('2099-01-08'),
    recurrence_anchor: 'from_completion',
    care_family: 'medication',
    care_source: 'guardian_defined',
    status: 'active',
    schedule_times: null,
    repeat_end_date: null,
    ...overrides,
  };
}

function createHarness(entry) {
  const occurrences = [];
  const pool = {
    query: async (sql, params = []) => {
      const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
      if (access) return access;
      const manage = handleManageEntryQuery(sql, params, { tableName: 'health_entries he' });
      if (manage) return manage;

      if (/FROM health_entries\b/.test(sql) && sql.trimStart().startsWith('SELECT')) {
        return { rows: params[0] === entry.id ? [entry] : [] };
      }
      if (sql.includes('INSERT INTO health_occurrences')) {
        occurrences.push({
          id: params[0],
          health_entry_id: params[1],
          scheduled_date: new Date(params[2]),
          scheduled_time: params[3] ?? null,
          status: 'pending',
          completed_on: null,
        });
        return { rows: [{ id: params[0] }] };
      }
      if (sql.includes('UPDATE health_occurrences') && sql.includes("status = 'completed'")) {
        const occ = occurrences.find((o) => params.includes(o.id));
        if (!occ) return { rows: [] };
        occ.status = 'completed';
        return { rows: [occ] };
      }
      if (sql.includes('FROM health_occurrences') && sql.includes("status = 'pending'")) {
        const pending = occurrences.filter((o) => o.status === 'pending');
        if (sql.includes('WHERE id = $1')) {
          return { rows: pending.filter((o) => o.id === params[0]) };
        }
        return { rows: pending };
      }
      return { rows: [] };
    },
    connect: async () => ({ query: pool.query, release: () => {} }),
    end: async () => {},
  };
  return { pool, occurrences };
}

describe('POST /api/health-entries/:id/mark-taken with no materialised occurrence', () => {
  it('materialises the head on next_due_date and completes it (not 400)', async () => {
    const entry = makeEntry();
    const { pool, occurrences } = createHarness(entry);
    const app = createApp(pool);

    const res = await request(app)
      .post(`/api/health-entries/${entry.id}/mark-taken`)
      .set('Authorization', `Bearer ${token}`)
      .send({ notes: '', completed_on: '2026-09-30' });

    expect(res.body.error).toBeUndefined();
    expect(res.statusCode).toBe(200);
    expect(occurrences[0].scheduled_date.toISOString().slice(0, 10)).toBe('2099-01-08');
    expect(occurrences[0].status).toBe('completed');
    // from_completion daily: the series rolls forward from the completion day.
    expect(occurrences.slice(1).map((o) => o.status)).toEqual(['pending']);
  });

  it('still returns 400 for a paused entry with nothing to materialise', async () => {
    const entry = makeEntry({ status: 'paused' });
    const { pool, occurrences } = createHarness(entry);
    const app = createApp(pool);

    const res = await request(app)
      .post(`/api/health-entries/${entry.id}/mark-taken`)
      .set('Authorization', `Bearer ${token}`)
      .send({ completed_on: '2026-09-30' });

    expect(res.statusCode).toBe(400);
    expect(res.body.error).toBe('Care item is paused');
    expect(occurrences).toHaveLength(0);
  });
});
