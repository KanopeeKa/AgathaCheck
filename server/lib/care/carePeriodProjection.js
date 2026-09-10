/**
 * Care-period projection — server-authoritative scheduling preview for a date window.
 *
 * Materialised health_occurrences win over simulated slots. from_completion rhythms
 * do not guess dates beyond an unresolved completion-dependent hop.
 */

import { dateToIsoDate } from '../calendarDate.js';
import { isEntrySeriesClosed, isOccurrenceDateWithinSeries } from '../occurrenceLifecycle.js';
import { advanceByFrequency } from '../recurrenceHelper.js';
import { scheduleTimesFromEntry } from '../occurrenceScheduling.js';
import { inferCareFamilyFromType } from '../../routes/healthEntries/shared.js';

export const PROJECTION_STATUS_COMPLETE = 'complete';
export const PROJECTION_STATUS_PARTIALLY_INDETERMINATE = 'partially_indeterminate';

export const UNCERTAINTY_REASON_FROM_COMPLETION_PENDING = 'from_completion_pending';
export const UNCERTAINTY_REASON_FROM_COMPLETION_CHAIN = 'from_completion_chain';

/**
 * @param {string} dateIso
 * @param {string} startsOn
 * @param {string} endsOn
 */
export function isDateInCareWindow(dateIso, startsOn, endsOn) {
  return dateIso >= startsOn && dateIso <= endsOn;
}

/**
 * @param {string|null|undefined} time
 */
function slotKey(dateIso, time) {
  const t = time == null || time === '' ? '__all_day__' : String(time).slice(0, 5);
  return `${dateIso}|${t}`;
}

/**
 * @param {object} entry
 */
function entryCareFamily(entry) {
  return entry.care_family || inferCareFamilyFromType(entry.type);
}

/**
 * @param {object} entry
 * @param {string} dateIso
 * @param {string|null} time
 * @param {'materialised'|'projected'} source
 * @param {string} status
 * @param {string|null} occurrenceId
 */
function buildItem(entry, dateIso, time, source, status, occurrenceId = null) {
  return {
    health_entry_id: entry.id,
    occurrence_id: occurrenceId,
    scheduled_date: dateIso,
    scheduled_time: time == null || time === '' ? null : String(time).slice(0, 5),
    status,
    source,
    name: entry.name || '',
    type: entry.type,
    care_family: entryCareFamily(entry),
  };
}

/**
 * @param {object} entry
 * @param {object} occurrence
 */
function materialisedItem(entry, occurrence) {
  const dateIso = dateToIsoDate(occurrence.scheduled_date);
  const time = occurrence.scheduled_time
    ? String(occurrence.scheduled_time).slice(0, 5)
    : null;
  return buildItem(
    entry,
    dateIso,
    time,
    'materialised',
    occurrence.status || 'pending',
    occurrence.id
  );
}

/**
 * @param {object[]} occurrences
 */
function sortOccurrences(occurrences) {
  return [...occurrences].sort((a, b) => {
    const da = dateToIsoDate(a.scheduled_date) || '';
    const db = dateToIsoDate(b.scheduled_date) || '';
    if (da !== db) return da.localeCompare(db);
    const ta = a.scheduled_time ? String(a.scheduled_time) : '';
    const tb = b.scheduled_time ? String(b.scheduled_time) : '';
    return ta.localeCompare(tb);
  });
}

/**
 * @param {object} entry
 * @param {object[]} occurrences all occurrences for this entry (in-window + pending)
 * @param {string} startsOn
 * @param {string} endsOn
 * @param {string} todayIso
 * @returns {{ items: object[], uncertainties: object[] }}
 */
export function projectEntryForPeriod(entry, occurrences, startsOn, endsOn, todayIso) {
  const items = [];
  const uncertainties = [];
  const knownSlots = new Set();

  const inWindowOccurrences = sortOccurrences(
    occurrences.filter((occ) => {
      const dateIso = dateToIsoDate(occ.scheduled_date);
      return dateIso && isDateInCareWindow(dateIso, startsOn, endsOn);
    })
  );

  for (const occ of inWindowOccurrences) {
    const item = materialisedItem(entry, occ);
    items.push(item);
    knownSlots.add(slotKey(item.scheduled_date, item.scheduled_time));
  }

  if (isEntrySeriesClosed(entry, todayIso)) {
    return { items, uncertainties };
  }

  const frequency = entry.frequency || 'once';
  const anchor = entry.recurrence_anchor || 'from_completion';

  if (frequency === 'once') {
    const candidates = [
      dateToIsoDate(entry.next_due_date),
      dateToIsoDate(entry.start_date),
    ].filter(Boolean);
    for (const dateIso of candidates) {
      if (!isDateInCareWindow(dateIso, startsOn, endsOn)) continue;
      for (const time of scheduleTimesFromEntry(entry)) {
        const key = slotKey(dateIso, time);
        if (knownSlots.has(key)) continue;
        items.push(buildItem(entry, dateIso, time, 'projected', 'pending'));
        knownSlots.add(key);
      }
    }
    return { items, uncertainties };
  }

  if (anchor === 'from_due_date') {
    let cursor = dateToIsoDate(entry.next_due_date) || dateToIsoDate(entry.start_date);
    if (!cursor) return { items, uncertainties };

    let guard = 0;
    while (cursor < startsOn && guard < 5000) {
      if (!isOccurrenceDateWithinSeries(entry, cursor)) {
        return { items, uncertainties };
      }
      const next = advanceByFrequency(cursor, entry);
      if (!next || next <= cursor) break;
      cursor = next;
      guard += 1;
    }

    guard = 0;
    while (
      cursor
      && cursor <= endsOn
      && isOccurrenceDateWithinSeries(entry, cursor)
      && guard < 5000
    ) {
      if (isDateInCareWindow(cursor, startsOn, endsOn)) {
        for (const time of scheduleTimesFromEntry(entry)) {
          const key = slotKey(cursor, time);
          if (!knownSlots.has(key)) {
            items.push(buildItem(entry, cursor, time, 'projected', 'pending'));
            knownSlots.add(key);
          }
        }
      }
      const next = advanceByFrequency(cursor, entry);
      if (!next || next <= cursor) break;
      cursor = next;
      guard += 1;
    }
    return { items, uncertainties };
  }

  const pending = sortOccurrences(
    occurrences.filter((occ) => (occ.status || 'pending') === 'pending')
  );

  if (pending.length > 0) {
    uncertainties.push({
      health_entry_id: entry.id,
      reason: UNCERTAINTY_REASON_FROM_COMPLETION_PENDING,
    });
    return { items, uncertainties };
  }

  const nextDue = dateToIsoDate(entry.next_due_date);
  if (nextDue && isDateInCareWindow(nextDue, startsOn, endsOn)) {
    for (const time of scheduleTimesFromEntry(entry)) {
      const key = slotKey(nextDue, time);
      if (!knownSlots.has(key)) {
        items.push(buildItem(entry, nextDue, time, 'projected', 'pending'));
        knownSlots.add(key);
      }
    }
    const secondHop = advanceByFrequency(nextDue, entry);
    if (
      secondHop
      && secondHop <= endsOn
      && isOccurrenceDateWithinSeries(entry, secondHop)
      && isDateInCareWindow(secondHop, startsOn, endsOn)
    ) {
      uncertainties.push({
        health_entry_id: entry.id,
        reason: UNCERTAINTY_REASON_FROM_COMPLETION_CHAIN,
      });
    }
    return { items, uncertainties };
  }

  if (nextDue && nextDue < startsOn) {
    uncertainties.push({
      health_entry_id: entry.id,
      reason: UNCERTAINTY_REASON_FROM_COMPLETION_PENDING,
    });
  }

  return { items, uncertainties };
}

/**
 * @param {object[]} entries
 * @param {Map<string, object[]>} occurrencesByEntryId
 * @param {string} startsOn
 * @param {string} endsOn
 * @param {string} todayIso
 */
export function projectCareForPeriod(entries, occurrencesByEntryId, startsOn, endsOn, todayIso) {
  const allItems = [];
  const allUncertainties = [];

  for (const entry of entries) {
    const occurrences = occurrencesByEntryId.get(entry.id) || [];
    const { items, uncertainties } = projectEntryForPeriod(
      entry,
      occurrences,
      startsOn,
      endsOn,
      todayIso
    );
    allItems.push(...items);
    allUncertainties.push(...uncertainties);
  }

  allItems.sort((a, b) => {
    if (a.scheduled_date !== b.scheduled_date) {
      return a.scheduled_date.localeCompare(b.scheduled_date);
    }
    const ta = a.scheduled_time || '';
    const tb = b.scheduled_time || '';
    if (ta !== tb) return ta.localeCompare(tb);
    return a.health_entry_id.localeCompare(b.health_entry_id);
  });

  const projectionStatus = allUncertainties.length > 0
    ? PROJECTION_STATUS_PARTIALLY_INDETERMINATE
    : PROJECTION_STATUS_COMPLETE;

  return {
    starts_on: startsOn,
    ends_on: endsOn,
    projection_status: projectionStatus,
    uncertainties: allUncertainties,
    items: allItems,
  };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} petId
 * @param {string} startsOn
 * @param {string} endsOn
 * @param {string} [todayIso]
 */
export async function loadAndProjectCareForPeriod(pool, petId, startsOn, endsOn, todayIso) {
  const entriesResult = await pool.query(
    'SELECT * FROM health_entries WHERE pet_id = $1 ORDER BY created_at ASC',
    [petId]
  );

  const occurrencesResult = await pool.query(
    `SELECT ho.*
     FROM health_occurrences ho
     INNER JOIN health_entries he ON he.id = ho.health_entry_id
     WHERE he.pet_id = $1
       AND (
         (ho.scheduled_date >= $2::date AND ho.scheduled_date <= $3::date)
         OR ho.status = 'pending'
       )`,
    [petId, startsOn, endsOn]
  );

  const occurrencesByEntryId = new Map();
  for (const row of occurrencesResult.rows) {
    const list = occurrencesByEntryId.get(row.health_entry_id) || [];
    list.push(row);
    occurrencesByEntryId.set(row.health_entry_id, list);
  }

  const projection = projectCareForPeriod(
    entriesResult.rows,
    occurrencesByEntryId,
    startsOn,
    endsOn,
    todayIso
  );

  return {
    pet_id: petId,
    ...projection,
  };
}
