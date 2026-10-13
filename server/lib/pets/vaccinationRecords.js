import { v4 as uuidv4 } from 'uuid';

import { dateToIsoDate, normalizeCalendarDateInput } from '../calendarDate.js';

const RECORD_SOURCES = new Set(['user', 'imported']);

export function vaccinationRecordToMap(row) {
  return {
    id: row.id,
    pet_id: row.pet_id,
    vaccine_name: row.vaccine_name,
    administered_on: dateToIsoDate(row.administered_on),
    record_source: row.record_source || 'user',
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

/**
 * Computed from rows — never stored on pets (programme B3).
 */
export function computeVaccinationSummary(records) {
  const count = records.length;
  const last = count > 0 ? records[0].administered_on : null;
  return {
    record_count: count,
    last_administered_on: last ? dateToIsoDate(last) : null,
  };
}

function parseVaccineName(body) {
  const raw = body?.vaccine_name ?? body?.vaccineName;
  if (raw === undefined || raw === null) {
    return { ok: false, error: 'vaccine_name is required' };
  }
  const name = String(raw).trim();
  if (!name) return { ok: false, error: 'vaccine_name is required' };
  if (name.length > 255) return { ok: false, error: 'vaccine_name is too long' };
  return { ok: true, value: name };
}

function parseAdministeredOn(body) {
  const raw = body?.administered_on ?? body?.administeredOn;
  const date = normalizeCalendarDateInput(raw);
  if (!date) return { ok: false, error: 'administered_on is required' };
  return { ok: true, value: date };
}

function parseRecordSource(body) {
  const raw = body?.record_source ?? body?.recordSource ?? 'user';
  const source = String(raw).trim().toLowerCase();
  if (!RECORD_SOURCES.has(source)) {
    return { ok: false, error: 'Invalid record_source' };
  }
  return { ok: true, value: source };
}

export async function listPetVaccinationRecords(pool, petId) {
  const result = await pool.query(
    `SELECT * FROM pet_vaccination_records
     WHERE pet_id = $1
     ORDER BY administered_on DESC, created_at DESC`,
    [petId],
  );
  const records = result.rows.map(vaccinationRecordToMap);
  return {
    records,
    summary: computeVaccinationSummary(result.rows),
  };
}

export async function createPetVaccinationRecord(pool, userId, petId, body) {
  const pet = await pool.query('SELECT id FROM pets WHERE id = $1', [petId]);
  if (pet.rows.length === 0) return null;

  const vaccine = parseVaccineName(body);
  if (!vaccine.ok) return { error: vaccine.error };
  const administered = parseAdministeredOn(body);
  if (!administered.ok) return { error: administered.error };
  const source = parseRecordSource(body);
  if (!source.ok) return { error: source.error };

  const id = body?.id && String(body.id).trim() ? String(body.id).trim() : uuidv4();
  const result = await pool.query(
    `INSERT INTO pet_vaccination_records (
       id, pet_id, vaccine_name, administered_on, record_source, created_by
     ) VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [id, petId, vaccine.value, administered.value, source.value, userId],
  );
  return { record: vaccinationRecordToMap(result.rows[0]) };
}
