'use strict';

import { groupAgendaRowsByDueDate } from './agendaGrouping.js';

/**
 * Multi-pet same-day coordination (AC-CO-02): banner when due rows on one
 * calendar day belong to two or more pets — links only, no merged agenda row.
 *
 * @param {Array<{ petId: string, date: string }>} rows
 * @returns {Array<{ dateKey: string, petIds: string[] }>}
 */
function coordinationBanners(rows) {
  const banners = [];
  for (const group of groupAgendaRowsByDueDate(rows)) {
    const petIds = [...new Set(group.rows.map((r) => r.petId))].sort();
    if (petIds.length >= 2) {
      banners.push({ dateKey: group.dateKey, petIds });
    }
  }
  return banners;
}

export { coordinationBanners };
