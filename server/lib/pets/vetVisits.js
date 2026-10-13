import { v4 as uuidv4 } from 'uuid';

import { dateToIsoDate, normalizeCalendarDateInput } from '../calendarDate.js';

const VISIT_STATUSES = new Set(['open', 'completed']);

export function vetVisitToMap(row, linkedOccurrences = []) {
  return {
    id: row.id,
    pet_id: row.pet_id,
    visited_on: dateToIsoDate(row.visited_on),
    status: row.status,
    completed_on: row.completed_on ? dateToIsoDate(row.completed_on) : null,
    notes: row.notes || '',
    linked_occurrences: linkedOccurrences,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

export function linkedOccurrenceToMap(row) {
  return {
    occurrence_id: row.occurrence_id ?? row.health_occurrence_id ?? row.id,
    health_entry_id: row.health_entry_id,
    status: row.status,
    scheduled_date: dateToIsoDate(row.scheduled_date),
  };
}

function parseVisitedOn(body) {
  const raw = body?.visited_on ?? body?.visitedOn;
  const date = normalizeCalendarDateInput(raw);
  if (!date) return { ok: false, error: 'visited_on is required' };
  return { ok: true, value: date };
}

function parseCompletedOn(body, fallback) {
  const raw = body?.completed_on ?? body?.completedOn;
  if (raw === undefined || raw === null || raw === '') {
    return { ok: true, value: fallback };
  }
  const date = normalizeCalendarDateInput(raw);
  if (!date) return { ok: false, error: 'completed_on must be a calendar date' };
  return { ok: true, value: date };
}

function parseNotes(body) {
  if (body?.notes === undefined || body?.notes === null) return { ok: true, value: '' };
  const notes = String(body.notes);
  if (notes.length > 4000) return { ok: false, error: 'notes is too long' };
  return { ok: true, value: notes };
}

function parseOccurrenceIds(body) {
  const raw = body?.occurrence_ids ?? body?.occurrenceIds;
  if (raw === undefined || raw === null) return { ok: true, value: [] };
  if (!Array.isArray(raw)) return { ok: false, error: 'occurrence_ids must be an array' };
  const ids = raw.map((id) => String(id).trim()).filter(Boolean);
  if (ids.length !== new Set(ids).size) {
    return { ok: false, error: 'occurrence_ids must be unique' };
  }
  return { ok: true, value: ids };
}

async function loadLinkedOccurrences(pool, visitId) {
  const result = await pool.query(
    `SELECT ho.id AS occurrence_id, ho.health_entry_id, ho.status, ho.scheduled_date
     FROM vet_visit_occurrence_links l
     INNER JOIN health_occurrences ho ON ho.id = l.health_occurrence_id
     WHERE l.vet_visit_id = $1
     ORDER BY ho.scheduled_date ASC, ho.created_at ASC`,
    [visitId],
  );
  return result.rows.map(linkedOccurrenceToMap);
}

async function assertOccurrencesBelongToPet(pool, petId, occurrenceIds) {
  if (occurrenceIds.length === 0) return { ok: true };
  const result = await pool.query(
    `SELECT ho.id
     FROM health_occurrences ho
     INNER JOIN health_entries he ON he.id = ho.health_entry_id
     WHERE he.pet_id = $1 AND ho.id = ANY($2::uuid[])`,
    [petId, occurrenceIds],
  );
  if (result.rows.length !== occurrenceIds.length) {
    return { ok: false, error: 'One or more occurrence_ids are invalid for this pet' };
  }
  const taken = await pool.query(
    `SELECT health_occurrence_id
     FROM vet_visit_occurrence_links
     WHERE health_occurrence_id = ANY($1::uuid[])`,
    [occurrenceIds],
  );
  if (taken.rows.length > 0) {
    return { ok: false, error: 'occurrence already linked to a vet visit' };
  }
  return { ok: true };
}

export async function listPetVetVisits(pool, petId) {
  const result = await pool.query(
    `SELECT * FROM vet_visits
     WHERE pet_id = $1
     ORDER BY visited_on DESC, created_at DESC`,
    [petId],
  );
  const visits = [];
  for (const row of result.rows) {
    const linked = await loadLinkedOccurrences(pool, row.id);
    visits.push(vetVisitToMap(row, linked));
  }
  return { visits };
}

export async function getPetVetVisit(pool, petId, visitId) {
  const result = await pool.query(
    'SELECT * FROM vet_visits WHERE id = $1 AND pet_id = $2',
    [visitId, petId],
  );
  if (result.rows.length === 0) return null;
  const linked = await loadLinkedOccurrences(pool, visitId);
  return vetVisitToMap(result.rows[0], linked);
}

export async function createPetVetVisit(pool, userId, petId, body) {
  const pet = await pool.query('SELECT id FROM pets WHERE id = $1', [petId]);
  if (pet.rows.length === 0) return null;

  const visited = parseVisitedOn(body);
  if (!visited.ok) return { error: visited.error };
  const notes = parseNotes(body);
  if (!notes.ok) return { error: notes.error };
  const occurrenceIds = parseOccurrenceIds(body);
  if (!occurrenceIds.ok) return { error: occurrenceIds.error };

  const belong = await assertOccurrencesBelongToPet(pool, petId, occurrenceIds.value);
  if (!belong.ok) return { error: belong.error };

  const id = body?.id && String(body.id).trim() ? String(body.id).trim() : uuidv4();
  const insert = await pool.query(
    `INSERT INTO vet_visits (id, pet_id, visited_on, status, notes, created_by)
     VALUES ($1, $2, $3, 'open', $4, $5)
     RETURNING *`,
    [id, petId, visited.value, notes.value, userId],
  );
  const visitRow = insert.rows[0];

  for (const occurrenceId of occurrenceIds.value) {
    await pool.query(
      `INSERT INTO vet_visit_occurrence_links (id, vet_visit_id, health_occurrence_id)
       VALUES ($1, $2, $3)`,
      [uuidv4(), visitRow.id, occurrenceId],
    );
  }

  const linked = await loadLinkedOccurrences(pool, visitRow.id);
  return { visit: vetVisitToMap(visitRow, linked) };
}

export async function addVetVisitOccurrenceLinks(pool, petId, visitId, body) {
  const visit = await pool.query(
    'SELECT id, status FROM vet_visits WHERE id = $1 AND pet_id = $2',
    [visitId, petId],
  );
  if (visit.rows.length === 0) return null;
  if (visit.rows[0].status === 'completed') {
    return { error: 'Cannot link occurrences to a completed vet visit' };
  }

  const occurrenceIds = parseOccurrenceIds(body);
  if (!occurrenceIds.ok) return { error: occurrenceIds.error };
  if (occurrenceIds.value.length === 0) {
    return { error: 'occurrence_ids is required' };
  }

  const belong = await assertOccurrencesBelongToPet(pool, petId, occurrenceIds.value);
  if (!belong.ok) return { error: belong.error };

  for (const occurrenceId of occurrenceIds.value) {
    await pool.query(
      `INSERT INTO vet_visit_occurrence_links (id, vet_visit_id, health_occurrence_id)
       VALUES ($1, $2, $3)`,
      [uuidv4(), visitId, occurrenceId],
    );
  }

  const full = await getPetVetVisit(pool, petId, visitId);
  return { visit: full };
}

export async function removeVetVisitOccurrenceLink(pool, petId, visitId, occurrenceId) {
  const visit = await pool.query(
    'SELECT id FROM vet_visits WHERE id = $1 AND pet_id = $2',
    [visitId, petId],
  );
  if (visit.rows.length === 0) return null;

  const del = await pool.query(
    `DELETE FROM vet_visit_occurrence_links
     WHERE vet_visit_id = $1 AND health_occurrence_id = $2`,
    [visitId, occurrenceId],
  );
  if (del.rowCount === 0) return { error: 'Link not found' };

  const full = await getPetVetVisit(pool, petId, visitId);
  return { visit: full };
}

/**
 * Marks the visit completed only — never mutates linked health_occurrences (AC-FB-02).
 */
export async function completePetVetVisit(pool, petId, visitId, body) {
  const visit = await pool.query(
    'SELECT * FROM vet_visits WHERE id = $1 AND pet_id = $2',
    [visitId, petId],
  );
  if (visit.rows.length === 0) return null;
  const row = visit.rows[0];
  if (row.status === 'completed') {
    return { error: 'Vet visit is already completed' };
  }

  const completed = parseCompletedOn(body, dateToIsoDate(row.visited_on));
  if (!completed.ok) return { error: completed.error };

  const updated = await pool.query(
    `UPDATE vet_visits
     SET status = 'completed',
         completed_on = $3,
         updated_at = NOW()
     WHERE id = $1 AND pet_id = $2
     RETURNING *`,
    [visitId, petId, completed.value],
  );

  const linked = await loadLinkedOccurrences(pool, visitId);
  return { visit: vetVisitToMap(updated.rows[0], linked) };
}

export function isValidVisitStatus(status) {
  return VISIT_STATUSES.has(status);
}
