/**
 * Planned absence helpers — Care Context V1 (declarer-scoped).
 */

import {
  addCalendarDaysIso,
  normalizeCalendarDateInput,
  timestampToIso,
  todayCalendarIso,
} from '../calendarDate.js';

export const PLANNED_ABSENCE_PROVENANCE_USER_DECLARED = 'user_declared';
export const PLANNED_ABSENCE_STATUS_ACTIVE = 'active';
export const PLANNED_ABSENCE_STATUS_CANCELLED = 'cancelled';

export const CARER_KIND_SHARED_USER = 'shared_user';
export const CARER_KIND_NOTE_ONLY = 'note_only';

/** Max forward request horizon (calendar months approximated as days). */
export const PLANNED_ABSENCE_MAX_HORIZON_DAYS = 366;

/**
 * @param {string|null|undefined} startsOn
 * @param {string|null|undefined} endsOn
 * @param {string} [todayIso]
 * @returns {{ ok: true, starts_on: string, ends_on: string } | { ok: false, error: string }}
 */
export function validateAbsenceDateWindow(startsOn, endsOn, todayIso = todayCalendarIso()) {
  const starts = normalizeCalendarDateInput(startsOn);
  const ends = normalizeCalendarDateInput(endsOn);
  if (!starts || !ends) {
    return { ok: false, error: 'starts_on and ends_on are required calendar dates (YYYY-MM-DD)' };
  }
  if (ends < starts) {
    return { ok: false, error: 'ends_on must be on or after starts_on' };
  }
  const maxEnd = addCalendarDaysIso(todayIso, PLANNED_ABSENCE_MAX_HORIZON_DAYS);
  if (ends > maxEnd) {
    return { ok: false, error: 'Absence end date exceeds the maximum planning horizon' };
  }
  return { ok: true, starts_on: starts, ends_on: ends };
}

/**
 * Calendar ranges overlap when both are inclusive date intervals.
 *
 * @param {string} aStart
 * @param {string} aEnd
 * @param {string} bStart
 * @param {string} bEnd
 */
export function dateRangesOverlap(aStart, aEnd, bStart, bEnd) {
  return aStart <= bEnd && bStart <= aEnd;
}

/**
 * @param {{ first_name?: string|null, last_name?: string|null, email?: string|null }} row
 */
export function formatCarerCandidateDisplayName(row) {
  const first = (row.first_name || '').trim();
  const last = (row.last_name || '').trim();
  if (first && last) {
    return `${first} ${last.charAt(0)}.`;
  }
  return first || last || 'User';
}

/**
 * @param {object} row
 */
export function carerRowToMap(row) {
  const kind = row.carer_kind || null;
  const removed = kind === CARER_KIND_SHARED_USER && !row.carer_user_id;
  return {
    pet_id: row.pet_id,
    carer_kind: kind,
    carer_user_id: row.carer_user_id || null,
    carer_name: row.carer_name || null,
    carer_note: row.carer_note || null,
    carer_removed: removed,
  };
}

/**
 * @param {object} input
 * @returns {{ ok: true, carer_kind: string|null, carer_user_id: string|null, carer_name: string|null, carer_note: string|null } | { ok: false, error: string }}
 */
export function validateCarerInput(input) {
  const kindRaw = input.carer_kind ?? input.carerKind ?? null;
  if (kindRaw === null || kindRaw === '') {
    return {
      ok: true,
      carer_kind: null,
      carer_user_id: null,
      carer_name: null,
      carer_note: null,
    };
  }
  if (kindRaw !== CARER_KIND_SHARED_USER && kindRaw !== CARER_KIND_NOTE_ONLY) {
    return { ok: false, error: 'carer_kind must be shared_user, note_only, or null' };
  }
  if (kindRaw === CARER_KIND_SHARED_USER) {
    const carerUserId = input.carer_user_id || input.carerUserId || null;
    if (!carerUserId) {
      return { ok: false, error: 'carer_user_id is required for shared_user carers' };
    }
    return {
      ok: true,
      carer_kind: CARER_KIND_SHARED_USER,
      carer_user_id: String(carerUserId),
      carer_name: null,
      carer_note: null,
    };
  }
  const name = (input.carer_name || input.carerName || '').trim();
  if (!name) {
    return { ok: false, error: 'carer_name is required for note_only carers' };
  }
  const note = input.carer_note ?? input.carerNote ?? null;
  return {
    ok: true,
    carer_kind: CARER_KIND_NOTE_ONLY,
    carer_user_id: null,
    carer_name: name,
    carer_note: note == null || note === '' ? null : String(note),
  };
}

/**
 * @param {object} row
 * @param {object[]} [petRows]
 */
export function absenceToMap(row, petRows = []) {
  const petCarers = petRows.map((petRow) => (
    typeof petRow === 'string' ? carerRowToMap({ pet_id: petRow }) : carerRowToMap(petRow)
  ));
  return {
    id: row.id,
    user_id: row.user_id,
    starts_on: normalizeCalendarDateInput(row.starts_on),
    ends_on: normalizeCalendarDateInput(row.ends_on),
    provenance: row.provenance || PLANNED_ABSENCE_PROVENANCE_USER_DECLARED,
    source_ref: row.source_ref || null,
    status: row.status || PLANNED_ABSENCE_STATUS_ACTIVE,
    pet_ids: petCarers.map((pet) => pet.pet_id),
    pet_carers: petCarers,
    created_at: timestampToIso(row.created_at),
    updated_at: timestampToIso(row.updated_at),
    cancelled_at: timestampToIso(row.cancelled_at),
  };
}

/**
 * Active for overlap/list: not cancelled and ends_on >= today.
 *
 * @param {string} [todayIso]
 */
export function activeAbsenceSqlPredicate(todayIso = todayCalendarIso()) {
  return {
    sql: `pa.status != $cancelled AND pa.ends_on >= $today::date`,
    params: { cancelled: PLANNED_ABSENCE_STATUS_CANCELLED, today: todayIso },
  };
}
