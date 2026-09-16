import { timestampToIso } from '../../lib/calendarDate.js';
import { absenceToMap } from '../../lib/care/plannedAbsence.js';

/**
 * @param {object} absenceMap
 * @param {object} row
 */
export function absenceResponse(row, petRows = []) {
  return appendHandoverFields(absenceToMap(row, petRows), row);
}

export function appendHandoverFields(absenceMap, row) {
  return {
    ...absenceMap,
    handover_note: row.handover_note ?? null,
    last_handover_downloaded_at: timestampToIso(row.last_handover_downloaded_at),
  };
}

/**
 * @param {unknown} value
 * @returns {string | null | undefined}
 */
export function normalizeHandoverNoteInput(value) {
  if (value === undefined) return undefined;
  if (value === null) return null;
  const text = String(value);
  return text === '' ? null : text;
}
