/**
 * PostgreSQL harness for care occurrence integration tests: real app, real
 * engine, test clock header. Every test creates its own user and pet.
 */
import { randomUUID } from 'crypto';

import jwt from 'jsonwebtoken';
import pg from 'pg';
import request from 'supertest';

import { createApp } from '../../../bin/server.js';
import { dateToIsoDate } from '../../../lib/calendarDate.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';

export function createDbPool() {
  if (process.env.DATABASE_URL) {
    return new pg.Pool({ connectionString: process.env.DATABASE_URL });
  }
  return new pg.Pool({
    user: process.env.PGUSER || 'user',
    password: process.env.PGPASSWORD || 'password',
    host: process.env.PGHOST || 'localhost',
    port: Number(process.env.PGPORT || 5432),
    database: process.env.PGDATABASE || 'agatha_db',
  });
}

/**
 * @returns {Promise<{ pool: import('pg').Pool|null, app: any }>}
 */
export async function openHarness() {
  const pool = createDbPool();
  try {
    const ready = await pool.query(
      `SELECT 1 FROM information_schema.columns
       WHERE table_name = 'health_occurrences' AND column_name = 'origin'`,
    );
    if (ready.rows.length === 0) throw new Error('schema not migrated');
    return { pool, app: createApp(pool) };
  } catch {
    await pool.end();
    return { pool: null, app: null };
  }
}

/**
 * Like `openHarness`, but a missing or unmigrated database fails the suite
 * instead of skipping it: these suites run only in the PostgreSQL CI job.
 *
 * @returns {Promise<{ pool: import('pg').Pool, app: any }>}
 */
export async function openStrictHarness() {
  const harness = await openHarness();
  if (!harness.pool) {
    throw new Error('Care DB integration tests require a migrated PostgreSQL (health_occurrences.origin)');
  }
  return harness;
}

/**
 * @param {import('pg').Pool} pool
 * @param {{ timeZone?: string }} [options]
 */
export async function createOwner(pool, { timeZone = 'UTC' } = {}) {
  const userId = randomUUID();
  const petId = randomUUID();
  await pool.query(
    `INSERT INTO users (id, email, password_hash, first_name, last_name)
     VALUES ($1, $2, 'hash', 'Care', 'Tester')`,
    [userId, `care-${userId}@example.com`],
  );
  await pool.query(
    `INSERT INTO pets (id, user_id, name, species, home_timezone) VALUES ($1, $2, 'Buddy', 'dog', $3)`,
    [petId, userId, timeZone],
  );
  const token = jwt.sign({ id: userId, email: `care-${userId}@example.com` }, JWT_SECRET, { expiresIn: '1h' });
  return { userId, petId, token };
}

/**
 * @param {import('pg').Pool} pool
 * @param {{ userId: string, petId: string }} owner
 */
export async function removeOwner(pool, owner) {
  await pool.query('DELETE FROM health_entries WHERE pet_id = $1', [owner.petId]);
  await pool.query('DELETE FROM pets WHERE id = $1', [owner.petId]);
  await pool.query('DELETE FROM pet_activity_events WHERE actor_user_id = $1', [owner.userId]).catch(() => {});
  await pool.query('DELETE FROM audit_events WHERE actor_user_id = $1', [owner.userId]).catch(() => {});
  await pool.query('DELETE FROM users WHERE id = $1', [owner.userId]);
}

/**
 * API client bound to one owner and a test clock.
 */
export function careApi(app, owner) {
  let clock = null;
  const send = (method, path, body) => {
    let req = request(app)[method](`/api/health-entries${path}`)
      .set('Authorization', `Bearer ${owner.token}`);
    if (clock) req = req.set('X-Care-As-Of', clock);
    return body === undefined ? req : req.send(body);
  };
  return {
    at(isoLocal) {
      clock = isoLocal;
      return this;
    },
    create(body) {
      return send('post', '', { pet_id: owner.petId, name: 'Care', ...body });
    },
    get(id) {
      return send('get', `/${id}`);
    },
    put(id, body) {
      return send('put', `/${id}`, body);
    },
    complete(id, occId, body = {}) {
      return send('post', `/${id}/occurrences/${occId}/complete`, body);
    },
    skip(id, occId, body = {}) {
      return send('post', `/${id}/occurrences/${occId}/skip`, body);
    },
    plan(id, body) {
      return send('post', `/${id}/occurrences`, body);
    },
    reschedule(id, occId, body) {
      return send('post', `/${id}/occurrences/${occId}/reschedule`, body);
    },
    record(id, occId, body = {}) {
      return send('post', `/${id}/occurrences/${occId}/record`, body);
    },
    resolveStack(id, body) {
      return send('post', `/${id}/occurrences/resolve-stack`, body);
    },
    postpone(id, body) {
      return send('post', `/${id}/postpone`, body);
    },
    resume(id, body = {}) {
      return send('post', `/${id}/resume`, body);
    },
    undo(id, body = {}) {
      return send('post', `/${id}/schedule/undo`, body);
    },
    close(id) {
      return send('post', `/${id}/close`, {});
    },
    reopen(id) {
      return send('post', `/${id}/reopen`, {});
    },
    past(id) {
      return send('get', `/${id}/occurrences?status=past`);
    },
    occurrence(id, occId) {
      return send('get', `/${id}/occurrences/${occId}`);
    },
    patchOccurrence(id, occId, body) {
      return send('patch', `/${id}/occurrences/${occId}`, body);
    },
    history(id) {
      return send('get', `/${id}/history`);
    },
  };
}

/**
 * @param {import('pg').Pool} pool
 * @param {string} entryId
 */
export async function occurrenceRows(pool, entryId) {
  const result = await pool.query(
    `SELECT id, to_char(scheduled_date, 'YYYY-MM-DD') AS date,
       to_char(scheduled_time, 'HH24:MI') AS time, status, origin, close_reason,
       to_char(completed_on, 'YYYY-MM-DD') AS completed_on
     FROM health_occurrences WHERE health_entry_id = $1
     ORDER BY scheduled_date, scheduled_time NULLS FIRST`,
    [entryId],
  );
  return result.rows;
}

/**
 * INV-1, INV-2, INV-5 for one item.
 *
 * @param {import('pg').Pool} pool
 * @param {string} entryId
 * @returns {Promise<string[]>} violations
 */
export async function invariantViolations(pool, entryId) {
  const entry = (await pool.query('SELECT * FROM health_entries WHERE id = $1', [entryId])).rows[0];
  const rows = await occurrenceRows(pool, entryId);
  const open = rows.filter((r) => r.status === 'pending');
  const violations = [];
  const plannedCare = (entry.care_planning || 'planned') !== 'unplanned';
  if (entry.status === 'active' && plannedCare && open.length === 0) violations.push('INV-1 no open occurrence');
  if (open.filter((r) => r.origin === 'computed').length > 1) violations.push('INV-2 two computed');
  if (entry.status === 'completed' && open.length > 0) violations.push('INV-4 finished item has open occurrences');
  const nextDue = dateToIsoDate(entry.next_due_date);
  const earliest = open[0]?.date ?? null;
  if (entry.status !== 'completed' && nextDue !== earliest) {
    violations.push(`INV-5 next_due_date ${nextDue} != ${earliest}`);
  }
  return violations;
}
