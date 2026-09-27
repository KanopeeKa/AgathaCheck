/**
 * R-A1: shared affected-item rule for away plan and Care Item absence join-work.
 *
 * @param {object} row enriched planned_care_items row
 * @returns {boolean}
 */
export function isCareItemAffectedByAbsence(row) {
  if (row.is_paused) {
    return false;
  }
  if (row.in_window != null) {
    return true;
  }
  const open = row.open_occurrence;
  if (!open?.open_status) {
    return false;
  }
  return open.open_status === 'overdue' || open.open_status === 'due_before_absence';
}
