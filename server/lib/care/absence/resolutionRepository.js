import { v4 as uuidv4 } from 'uuid';

import {
  RESOLUTION_DECISIONS,
  RESOLUTION_DECISION_KEEP_DATE,
} from './constants.js';
import { collectCurrentDatesInWindow } from './deriveResolutionState.js';
import {
  CARER_KIND_SHARED_USER,
  validateCarerInput,
} from '../plannedAbsence.js';

/**
 * @param {object} row
 */
export function resolutionRowToMap(row) {
  const kind = row.carer_kind || null;
  const lookedAfterRemoved = kind === CARER_KIND_SHARED_USER && !row.carer_user_id;
  const dates = Array.isArray(row.dates_decided_for)
    ? row.dates_decided_for.map(String)
    : [];
  return {
    id: row.id,
    health_entry_id: row.health_entry_id,
    planned_absence_id: row.planned_absence_id,
    decision: row.decision,
    looked_after_by: kind
      ? {
          carer_kind: kind,
          carer_user_id: row.carer_user_id || null,
          carer_name: row.carer_name || null,
          carer_removed: lookedAfterRemoved,
        }
      : null,
    absence_note: row.absence_note || null,
    dates_decided_for: dates,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} absenceId
 */
export async function listResolutionsForAbsence(pool, absenceId) {
  const result = await pool.query(
    `SELECT *
     FROM health_entry_absence_resolutions
     WHERE planned_absence_id = $1
     ORDER BY health_entry_id`,
    [absenceId]
  );
  return result.rows.map(resolutionRowToMap);
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} absenceId
 * @param {string[]} healthEntryIds
 */
export async function loadResolutionsByEntryIds(pool, absenceId, healthEntryIds) {
  if (!healthEntryIds.length) return new Map();
  const result = await pool.query(
    `SELECT *
     FROM health_entry_absence_resolutions
     WHERE planned_absence_id = $1
       AND health_entry_id = ANY($2::uuid[])`,
    [absenceId, healthEntryIds]
  );
  const map = new Map();
  for (const row of result.rows) {
    map.set(row.health_entry_id, row);
  }
  return map;
}

/**
 * @param {object} input
 */
export function validateResolutionDecision(input) {
  const raw = input.decision;
  if (!raw || !RESOLUTION_DECISIONS.includes(String(raw))) {
    return { ok: false, error: 'decision must be keep_date, move_before, move_after, or nothing_needed' };
  }
  return { ok: true, decision: String(raw) };
}

/**
 * Optional looked-after-by uses the same carer shape as planned_absence_pets.
 *
 * @param {object} input
 */
export function validateLookedAfterByInput(input) {
  const payload = input.looked_after_by ?? input.lookedAfterBy ?? input;
  if (payload == null || (typeof payload === 'object' && Object.keys(payload).length === 0)) {
    return {
      ok: true,
      carer_kind: null,
      carer_user_id: null,
      carer_name: null,
    };
  }
  return validateCarerInput(payload);
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} absenceId
 * @param {string} healthEntryId
 * @param {object} body
 * @param {{
 *   startsOn: string,
 *   endsOn: string,
 *   projectionItems: object[],
 * }} context
 */
export async function upsertResolution(pool, absenceId, healthEntryId, body, context) {
  const decisionResult = validateResolutionDecision(body);
  if (!decisionResult.ok) {
    return decisionResult;
  }

  const lookedAfter = validateLookedAfterByInput(body);
  if (!lookedAfter.ok) {
    return lookedAfter;
  }

  const absenceNoteRaw = body.absence_note ?? body.absenceNote;
  const absenceNote = absenceNoteRaw == null || absenceNoteRaw === ''
    ? null
    : String(absenceNoteRaw);

  const datesDecidedFor = collectCurrentDatesInWindow(
    context.projectionItems,
    healthEntryId,
    context.startsOn,
    context.endsOn
  );

  const existing = await pool.query(
    `SELECT id FROM health_entry_absence_resolutions
     WHERE planned_absence_id = $1 AND health_entry_id = $2`,
    [absenceId, healthEntryId]
  );

  if (existing.rows.length > 0) {
    const id = existing.rows[0].id;
    const result = await pool.query(
      `UPDATE health_entry_absence_resolutions
       SET decision = $1,
           carer_kind = $2,
           carer_user_id = $3,
           carer_name = $4,
           absence_note = $5,
           dates_decided_for = $6::jsonb,
           updated_at = NOW()
       WHERE id = $7
       RETURNING *`,
      [
        decisionResult.decision,
        lookedAfter.carer_kind,
        lookedAfter.carer_user_id,
        lookedAfter.carer_name,
        absenceNote,
        JSON.stringify(datesDecidedFor),
        id,
      ]
    );
    return { ok: true, resolution: resolutionRowToMap(result.rows[0]) };
  }

  const id = uuidv4();
  const result = await pool.query(
    `INSERT INTO health_entry_absence_resolutions (
       id, health_entry_id, planned_absence_id, decision,
       carer_kind, carer_user_id, carer_name, absence_note, dates_decided_for
     ) VALUES (
       $1, $2, $3, $4, $5, $6, $7, $8, $9::jsonb
     )
     RETURNING *`,
    [
      id,
      healthEntryId,
      absenceId,
      decisionResult.decision,
      lookedAfter.carer_kind,
      lookedAfter.carer_user_id,
      lookedAfter.carer_name,
      absenceNote,
      JSON.stringify(datesDecidedFor),
    ]
  );
  return { ok: true, resolution: resolutionRowToMap(result.rows[0]) };
}

/**
 * Suggested looked-after-by from planned_absence_pets carer for one pet.
 *
 * @param {object|null} petRow
 */
export function suggestedLookedAfterFromPetCarer(petRow) {
  if (!petRow?.carer_kind) return null;
  if (petRow.carer_kind === CARER_KIND_SHARED_USER && !petRow.carer_user_id) {
    return null;
  }
  return {
    carer_kind: petRow.carer_kind,
    carer_user_id: petRow.carer_user_id || null,
    carer_name: petRow.carer_name || null,
  };
}

/**
 * Default decision for quick "keep the date · {carer}" suggestion.
 */
export function defaultSuggestedDecision() {
  return RESOLUTION_DECISION_KEEP_DATE;
}
