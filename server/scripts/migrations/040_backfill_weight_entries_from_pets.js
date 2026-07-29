import { v4 as uuidv4 } from 'uuid';

import { dateToIsoDate } from '../../lib/calendarDate.js';

const SELECT_SQL = `
  SELECT p.id, p.user_id, p.weight, p.created_at, p.updated_at
  FROM pets p
  WHERE p.weight IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM weight_entries we WHERE we.pet_id = p.id
    )`;

const INSERT_SQL = `
  INSERT INTO weight_entries (id, pet_id, user_id, weight, unit, date, notes, created_at)
  VALUES ($1, $2, $3, $4, 'kg', $5, '', $6)`;

/**
 * One-time backfill: pets with a profile weight but no weight_entries history.
 * @param {import('pg').PoolClient} client
 */
export async function backfillWeightEntriesFromPets(client) {
  const { rows } = await client.query(SELECT_SQL);
  for (const row of rows) {
    const anchor = row.updated_at || row.created_at || new Date();
    const dateVal = dateToIsoDate(anchor) || dateToIsoDate(new Date());
    await client.query(INSERT_SQL, [
      uuidv4(),
      row.id,
      row.user_id,
      row.weight,
      dateVal,
      anchor,
    ]);
  }
}
