/**
 * Health entry list, export, and single-item read use cases for CRUD routes.
 */

import { dateToIsoDate } from '../calendarDate.js';
import {
  accessiblePetSql,
} from '../petAccess.js';
import { hasPetCapability, PET_CAPABILITIES } from '../petCapabilityPolicy.js';
import { csvCell } from '../health/healthEntryCsv.js';

export async function listHealthEntriesForUser(pool, userId, petId) {
  if (petId) {
    if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_VIEW))) {
      return { error: 'Forbidden', status: 403 };
    }
    const result = await pool.query(
      `SELECT he.*, p.name as pet_name, p.home_timezone AS pet_home_timezone FROM health_entries he
       JOIN pets p ON he.pet_id = p.id
       WHERE he.pet_id = $1 AND ${accessiblePetSql('p', '$2')}
       ORDER BY he.next_due_date ASC NULLS LAST, he.created_at DESC`,
      [petId, userId],
    );
    return { rows: result.rows };
  }
  const result = await pool.query(
    `SELECT he.*, p.name as pet_name, p.home_timezone AS pet_home_timezone FROM health_entries he
     JOIN pets p ON he.pet_id = p.id
     WHERE ${accessiblePetSql('p', '$1')}
     ORDER BY he.next_due_date ASC NULLS LAST, he.created_at DESC`,
    [userId],
  );
  return { rows: result.rows };
}

export async function exportHealthEntriesCsv(pool, userId) {
  const result = await pool.query(
    `SELECT he.*, p.name as pet_name FROM health_entries he
     JOIN pets p ON he.pet_id = p.id
     WHERE ${accessiblePetSql('p', '$1')}
     ORDER BY he.created_at DESC`,
    [userId],
  );
  let csv = 'id,pet_name,name,type,dosage,frequency,start_date,next_due_date,completed_on,recurrence_anchor,notes\n';
  for (const row of result.rows) {
    csv += [
      row.id, row.pet_name, row.name, row.type, row.dosage,
      row.frequency,
      dateToIsoDate(row.start_date),
      dateToIsoDate(row.next_due_date),
      dateToIsoDate(row.completed_on),
      row.recurrence_anchor, row.notes,
    ].map(csvCell).join(',') + '\n';
  }
  return csv;
}

export async function getHealthEntryForUser(pool, userId, entryId) {
  const result = await pool.query(
    `SELECT he.*, p.name as pet_name FROM health_entries he
     JOIN pets p ON he.pet_id = p.id
     WHERE he.id = $1 AND ${accessiblePetSql('p', '$2')}`,
    [entryId, userId],
  );
  if (result.rows.length === 0) return { error: 'Entry not found', status: 404 };
  return { row: result.rows[0] };
}
