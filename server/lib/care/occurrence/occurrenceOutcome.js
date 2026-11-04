/**
 * Care date stored outcome on the wire (CARE-STATUS-R-001, R-004).
 * Open rows use status `pending`; closed rows use completed | skipped | not_recorded.
 */

/** @typedef {'open'|'done'|'skipped'|'not_recorded'} OccurrenceWireOutcome */

/**
 * @param {object} row health_occurrences row (post migration 084)
 * @returns {OccurrenceWireOutcome}
 */
export function occurrenceOutcomeFromRow(row) {
  if (!row) return 'skipped';
  switch (row.status) {
    case 'pending':
      return 'open';
    case 'completed':
      return 'done';
    case 'not_recorded':
      return 'not_recorded';
    case 'skipped':
      return 'skipped';
    default:
      return 'skipped';
  }
}

/**
 * @param {object} row
 * @returns {boolean}
 */
export function isNotRecordedOutcomeRow(row) {
  return occurrenceOutcomeFromRow(row) === 'not_recorded';
}

/**
 * Human-readable export label (R-004).
 * @param {object} row
 * @returns {'Done'|'Skipped'|'Not recorded'|'Open'}
 */
export function occurrenceOutcomeExportLabel(row) {
  switch (occurrenceOutcomeFromRow(row)) {
    case 'done':
      return 'Done';
    case 'not_recorded':
      return 'Not recorded';
    case 'open':
      return 'Open';
    default:
      return 'Skipped';
  }
}
