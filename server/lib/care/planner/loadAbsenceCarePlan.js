import { dateToIsoDate, todayCalendarIso } from '../../calendarDate.js';
import { loadLastClosedOccurrenceDateIso } from '../schedule/index.js';
import { isDateInCareWindow, loadScheduleDataForProjection } from '../schedule/projectSchedule.js';
import { planAbsenceCare } from './planAbsenceCare.js';

/**
 * @param {object[]} occurrences
 * @returns {object|null}
 */
function earliestPendingOccurrence(occurrences) {
  const pending = (occurrences || [])
    .filter((row) => row.status === 'pending')
    .sort((a, b) => String(a.scheduled_date).localeCompare(String(b.scheduled_date)));
  const row = pending[0];
  if (!row) return null;
  const scheduled = dateToIsoDate(row.scheduled_date);
  if (!scheduled) return null;
  return {
    occurrence_id: row.id,
    scheduled_date: scheduled,
  };
}

/**
 * @param {object[]} occurrences
 * @param {string} startsOn
 * @param {string} endsOn
 * @returns {number}
 */
function countMaterializedInWindow(occurrences, startsOn, endsOn) {
  return (occurrences || []).filter(
    (row) => row.status === 'pending'
      && isDateInCareWindow(dateToIsoDate(row.scheduled_date), startsOn, endsOn),
  ).length;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} absenceRow
 * @param {object[]} petRows
 * @param {string} [todayIso]
 */
export async function loadAbsenceCarePlan(pool, absenceRow, petRows, todayIso) {
  const startsOn = dateToIsoDate(absenceRow.starts_on);
  const endsOn = dateToIsoDate(absenceRow.ends_on);
  const today = todayIso || todayCalendarIso();
  if (!startsOn || !endsOn) {
    throw new Error('Absence dates are required for care plan');
  }

  const pets = [];
  for (const petRow of petRows) {
    const petId = petRow.pet_id;
    const { entries, occurrencesByEntryId } = await loadScheduleDataForProjection(
      pool,
      petId,
      startsOn,
      endsOn,
    );

    const entryPayloads = [];
    for (const entry of entries) {
      const occurrences = occurrencesByEntryId.get(entry.id) || [];
      const openOccurrence = earliestPendingOccurrence(occurrences);
      const lastClosedDate = await loadLastClosedOccurrenceDateIso(pool, entry);
      entryPayloads.push({
        entry,
        open_occurrence: openOccurrence,
        last_closed_date: lastClosedDate,
        materialized_in_window: countMaterializedInWindow(occurrences, startsOn, endsOn),
      });
    }

    pets.push({ pet_id: petId, entries: entryPayloads });
  }

  const plan = planAbsenceCare({
    absence: {
      id: absenceRow.id,
      starts_on: startsOn,
      ends_on: endsOn,
    },
    today,
    pets,
  });

  return {
    absence_id: absenceRow.id,
    today,
    starts_on: startsOn,
    ends_on: endsOn,
    ...plan,
  };
}
