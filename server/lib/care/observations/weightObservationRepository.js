const LIST_BY_PET_SQL = `
  SELECT we.*, p.name AS pet_name
  FROM weight_entries we
  JOIN pets p ON we.pet_id = p.id
  WHERE we.pet_id = $1 AND {{ACCESS_SQL}}
  ORDER BY we.date DESC, we.created_at DESC`;

const LIST_ALL_SQL = `
  SELECT we.*, p.name AS pet_name
  FROM weight_entries we
  JOIN pets p ON we.pet_id = p.id
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
export async function deleteWeightEntryById(db, id) {
  await db.query('DELETE FROM weight_entries WHERE id = $1', [id]);
}
