import { v4 as uuidv4 } from 'uuid';

import { todayCalendarIso } from './calendarDate.js';

const LATEST_WEIGHT_ENTRY_SQL = `
  SELECT id, weight, unit, date, notes, created_at
  FROM weight_entries
  WHERE pet_id = $1
  ORDER BY date DESC, created_at DESC
  LIMIT 1`;

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {string} petId
 * @returns {Promise<{ id: string, weight: number, unit: string, date: string, notes: string, created_at: Date } | null>}
 */
export async function getLatestWeightEntry(db, petId) {
  const result = await db.query(LATEST_WEIGHT_ENTRY_SQL, [petId]);
  return result.rows[0] || null;
}

/**
 * Sets pets.weight to the latest weight_entries row for the pet, or NULL when none exist.
 *
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {string} petId
 */
export async function refreshPetWeightCache(db, petId) {
  await db.query(
    `UPDATE pets SET weight = (
       SELECT weight FROM weight_entries
       WHERE pet_id = $1
       ORDER BY date DESC, created_at DESC
       LIMIT 1
     ), updated_at = NOW()
     WHERE id = $1`,
    [petId],
  );
}

/**
 * @param {number|null|undefined} a
 * @param {number|null|undefined} b
 */
export function weightsDiffer(a, b) {
  if (a == null && b == null) return false;
  if (a == null || b == null) return true;
  return Math.abs(Number(a) - Number(b)) > 1e-9;
}

/**
 * Inserts a weight entry and refreshes pets.weight from the latest entry.
 *
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {{
 *   petId: string,
 *   userId: string,
 *   weight: number,
 *   date?: string,
 *   notes?: string,
 *   unit?: string,
 *   entryId?: string,
 * }} params
 */
export async function createWeightEntryAndSyncPet(db, {
  petId,
  userId,
  weight,
  date = todayCalendarIso(),
  notes = '',
  unit = 'kg',
  entryId,
}) {
  const id = entryId || uuidv4();
  const weightVal = typeof weight === 'number' ? weight : parseFloat(weight || '0');
  await db.query(
    'INSERT INTO weight_entries (id, pet_id, user_id, weight, unit, date, notes) VALUES ($1, $2, $3, $4, $5, $6, $7)',
    [id, petId, userId, weightVal, unit || 'kg', date, notes || ''],
  );
  await refreshPetWeightCache(db, petId);
  return id;
}

/**
 * When a pet create/update payload includes weight, append a history row when the
 * value changed relative to the latest entry (pet edit / initial weight).
 *
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {{ petId: string, userId: string, weight: number|null|undefined }} params
 */
export async function maybeCreateWeightEntryFromPetPayload(db, { petId, userId, weight }) {
  if (weight == null || weight === '') return;
  const weightVal = typeof weight === 'number' ? weight : parseFloat(weight);
  if (Number.isNaN(weightVal)) return;

  const latest = await getLatestWeightEntry(db, petId);
  if (!weightsDiffer(weightVal, latest?.weight)) return;

  await createWeightEntryAndSyncPet(db, {
    petId,
    userId,
    weight: weightVal,
    date: todayCalendarIso(),
    notes: '',
    unit: 'kg',
  });
}
