import { dateToIsoDate } from '../../calendarDate.js';

const FULFILS_JOIN = `
  LEFT JOIN health_occurrences ho_f ON ho_f.id = we.health_occurrence_id
  LEFT JOIN health_entries he_f ON he_f.id = ho_f.health_entry_id`;

const LIST_BY_PET_SQL = `
  SELECT we.*, p.name AS pet_name,
    he_f.id AS fulfils_entry_id,
    he_f.name AS fulfils_entry_name,
    ho_f.id AS fulfils_occurrence_id,
    ho_f.scheduled_date AS fulfils_scheduled_date
  FROM weight_entries we
  JOIN pets p ON we.pet_id = p.id
  ${FULFILS_JOIN}
  WHERE we.pet_id = $1 AND {{ACCESS_SQL}}
  ORDER BY we.date DESC, we.created_at DESC`;

const LIST_ALL_SQL = `
  SELECT we.*, p.name AS pet_name,
    he_f.id AS fulfils_entry_id,
    he_f.name AS fulfils_entry_name,
    ho_f.id AS fulfils_occurrence_id,
    ho_f.scheduled_date AS fulfils_scheduled_date
  FROM weight_entries we
  JOIN pets p ON we.pet_id = p.id
  ${FULFILS_JOIN}
  WHERE {{ACCESS_SQL}}
  ORDER BY we.date DESC, we.created_at DESC`;

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {string} accessSql
 * @param {string} userId
 * @param {string|null} petId
 */
export async function listWeightEntries(db, accessSql, userId, petId) {
  if (petId) {
    const sql = LIST_BY_PET_SQL.replace('{{ACCESS_SQL}}', accessSql);
    return db.query(sql, [petId, userId]);
  }
  const sql = LIST_ALL_SQL.replace('{{ACCESS_SQL}}', accessSql);
  return db.query(sql, [userId]);
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {string} accessSql
 * @param {string} petId
 * @param {string} userId
 */
export async function findLatestWeightEntry(db, accessSql, petId, userId) {
  const result = await db.query(
    `SELECT we.*, p.name AS pet_name
     FROM weight_entries we
     JOIN pets p ON we.pet_id = p.id
     WHERE we.pet_id = $1 AND ${accessSql}
     ORDER BY we.date DESC, we.created_at DESC LIMIT 1`,
    [petId, userId],
  );
  return result.rows[0] || null;
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {string} id
 */
export async function findWeightEntryById(db, id) {
  const result = await db.query('SELECT * FROM weight_entries WHERE id = $1', [id]);
  return result.rows[0] || null;
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {string} occurrenceId
 */
export async function findWeightEntryByOccurrenceId(db, occurrenceId) {
  const result = await db.query(
    'SELECT * FROM weight_entries WHERE health_occurrence_id = $1 LIMIT 1',
    [occurrenceId],
  );
  return result.rows[0] || null;
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {{
 *   id: string,
 *   petId: string,
 *   userId: string,
 *   weightKg: number,
 *   date: string,
 *   notes?: string,
 *   measurementSource: string,
 *   healthOccurrenceId?: string|null,
 * }} row
 */
export async function insertWeightEntry(db, row) {
  const result = await db.query(
    `INSERT INTO weight_entries
      (id, pet_id, user_id, weight, unit, date, notes, measurement_source, health_occurrence_id)
     VALUES ($1, $2, $3, $4, 'kg', $5, $6, $7, $8)
     RETURNING *`,
    [
      row.id,
      row.petId,
      row.userId,
      row.weightKg,
      row.date,
      row.notes || '',
      row.measurementSource,
      row.healthOccurrenceId ?? null,
    ],
  );
  return result.rows[0];
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {{
 *   id: string,
 *   weightKg: number,
 *   date: string,
 *   notes: string,
 *   measurementSource: string,
 * }} patch
 */
export async function updateWeightEntry(db, patch) {
  const result = await db.query(
    `UPDATE weight_entries
     SET weight = $1, unit = 'kg', date = $2, notes = $3, measurement_source = $4
     WHERE id = $5
     RETURNING *`,
    [patch.weightKg, patch.date, patch.notes, patch.measurementSource, patch.id],
  );
  return result.rows[0] || null;
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {string} id
 */
export async function deleteWeightEntryById(db, id, occurrenceId = null) {
  if (occurrenceId) {
    await db.query(
      'DELETE FROM weight_entries WHERE id = $1 AND health_occurrence_id = $2',
      [id, occurrenceId],
    );
    return;
  }
  await db.query('DELETE FROM weight_entries WHERE id = $1', [id]);
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {string|null} weightId when null, unlinks any row for the occurrence
 * @param {string} occurrenceId
 */
export async function unlinkWeightFromOccurrence(db, weightId, occurrenceId) {
  if (weightId) {
    const result = await db.query(
      `UPDATE weight_entries SET health_occurrence_id = NULL
       WHERE id = $1 AND health_occurrence_id = $2
       RETURNING id`,
      [weightId, occurrenceId],
    );
    return result.rows[0] || null;
  }
  const result = await db.query(
    `UPDATE weight_entries SET health_occurrence_id = NULL
     WHERE health_occurrence_id = $1
     RETURNING id`,
    [occurrenceId],
  );
  return result.rows[0] || null;
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {string} occurrenceId
 * @param {string} dateIso YYYY-MM-DD
 * @returns {Promise<{ date_before: Date|string }|null>}
 */
/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {string} weightId
 * @param {string} occurrenceId
 */
export async function linkWeightToOccurrence(db, weightId, occurrenceId) {
  const result = await db.query(
    `UPDATE weight_entries
     SET health_occurrence_id = $2
     WHERE id = $1 AND health_occurrence_id IS NULL
     RETURNING id`,
    [weightId, occurrenceId],
  );
  return result.rows[0] || null;
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {string} petId
 */
export async function loadFulfilmentContext(db, petId) {
  const itemsResult = await db.query(
    `SELECT * FROM health_entries
     WHERE pet_id = $1 AND care_family = 'weight_monitoring' AND status = 'active'`,
    [petId],
  );
  const items = itemsResult.rows;
  const entryIds = items.map((r) => r.id);
  const pendingByEntry = new Map();
  const latestCompletedOnByEntry = new Map();
  if (entryIds.length > 0) {
    const pendingResult = await db.query(
      `SELECT * FROM health_occurrences
       WHERE health_entry_id = ANY($1::uuid[]) AND status = 'pending'
       ORDER BY scheduled_date ASC, scheduled_time ASC NULLS FIRST`,
      [entryIds],
    );
    for (const row of pendingResult.rows) {
      const list = pendingByEntry.get(row.health_entry_id) || [];
      list.push(row);
      pendingByEntry.set(row.health_entry_id, list);
    }
    const doneResult = await db.query(
      `SELECT DISTINCT ON (health_entry_id) health_entry_id, completed_on
       FROM health_occurrences
       WHERE health_entry_id = ANY($1::uuid[]) AND status = 'completed'
       ORDER BY health_entry_id, completed_on DESC NULLS LAST`,
      [entryIds],
    );
    for (const row of doneResult.rows) {
      latestCompletedOnByEntry.set(
        row.health_entry_id,
        row.completed_on ? dateToIsoDate(row.completed_on) : null,
      );
    }
  }
  return { items, pendingByEntry, latestCompletedOnByEntry };
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {string} petId
 */
export async function loadWeightOverviewContext(db, petId) {
  const petResult = await db.query(
    `SELECT id, weight_reference_value, weight_reference_authority, weight_management_context
     FROM pets WHERE id = $1`,
    [petId],
  );
  const itemsResult = await db.query(
    `SELECT * FROM health_entries
     WHERE pet_id = $1 AND care_family = 'weight_monitoring'
       AND status IN ('active', 'paused')
     ORDER BY name`,
    [petId],
  );
  const items = itemsResult.rows;
  const entryIds = items.map((r) => r.id);
  const pendingByEntry = new Map();
  if (entryIds.length > 0) {
    const pendingResult = await db.query(
      `SELECT * FROM health_occurrences
       WHERE health_entry_id = ANY($1::uuid[]) AND status = 'pending'
       ORDER BY scheduled_date ASC, scheduled_time ASC NULLS FIRST`,
      [entryIds],
    );
    for (const row of pendingResult.rows) {
      const list = pendingByEntry.get(row.health_entry_id) || [];
      list.push(row);
      pendingByEntry.set(row.health_entry_id, list);
    }
  }
  return { pet: petResult.rows[0] || null, items, pendingByEntry };
}

export async function updateWeightDateForOccurrence(db, occurrenceId, dateIso) {
  const existing = await db.query(
    'SELECT id, date FROM weight_entries WHERE health_occurrence_id = $1 LIMIT 1',
    [occurrenceId],
  );
  if (!existing.rows[0]) return null;
  const dateBefore = existing.rows[0].date;
  await db.query(
    'UPDATE weight_entries SET date = $1 WHERE health_occurrence_id = $2',
    [dateIso, occurrenceId],
  );
  return { date_before: dateBefore };
}
