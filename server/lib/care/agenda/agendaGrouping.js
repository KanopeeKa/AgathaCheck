'use strict';

/**
 * Due-soon / upcoming rows: group consecutive items by calendar due date.
 * Shared rule for agenda same-day date headers (AC-CO-01 / D-CIE-025 extension).
 *
 * @param {Array<{ date: string }>} rows sorted by due date ascending
 * @returns {Array<{ dateKey: string, rows: Array<{ date: string }> }>}
 */
function groupAgendaRowsByDueDate(rows) {
  const groups = [];
  for (const row of rows) {
    const dateKey = row.date;
    const last = groups[groups.length - 1];
    if (last && last.dateKey === dateKey) {
      last.rows.push(row);
    } else {
      groups.push({ dateKey, rows: [row] });
    }
  }
  return groups;
}

/** Same-day date sub-header when two or more items share a due calendar day. */
function showSameDayDateHeader(group) {
  return group.rows.length >= 2;
}

export { groupAgendaRowsByDueDate, showSameDayDateHeader };
