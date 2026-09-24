/**
 * Pure Care Planner for one absence (D-ACP-008).
 */

import { addCalendarDaysIso } from '../../calendarDate.js';
import { RECURRENCE_ANCHOR_FROM_DUE_DATE } from '../schedule/recurrenceAnchorDefaults.js';
import { estimateOccurrences } from '../schedule/estimateOccurrences.js';
import { isDateInCareWindow, projectEntryForPeriod } from '../schedule/projectSchedule.js';
import { resolveScheduleFlexibility } from '../schedule/index.js';
import { candidateMoves } from './candidateMoves.js';

/**
 * @param {object[]} occurrences
 * @param {object|null} openOccurrence
 * @returns {object[]}
 */
function occurrencesForProjection(occurrences, openOccurrence) {
  if (!openOccurrence?.occurrence_id) return occurrences || [];
  return (occurrences || []).map((row) => (
    row.id === openOccurrence.occurrence_id
      ? { ...row, scheduled_date: openOccurrence.scheduled_date }
      : row
  ));
}

/**
 * @param {object} params
 * @param {object} params.entry
 * @param {object|null} params.openOccurrence
 * @param {string|null} params.lastClosedDate
 * @param {string} params.startsOn
 * @param {string} params.endsOn
 * @param {string} params.today
 * @param {number} [params.materializedInWindow]
 * @param {object[]} [params.occurrences]
 * @returns {number}
 */
export function countInWindowOccurrences({
  entry,
  openOccurrence,
  lastClosedDate,
  startsOn,
  endsOn,
  today,
  materializedInWindow = 0,
  occurrences = [],
}) {
  const anchor = entry.recurrence_anchor || 'from_completion';
  if (anchor === RECURRENCE_ANCHOR_FROM_DUE_DATE) {
    const occRows = occurrencesForProjection(occurrences, openOccurrence);
    const { items } = projectEntryForPeriod(entry, occRows, startsOn, endsOn, today);
    return items.filter((item) => isDateInCareWindow(item.scheduled_date, startsOn, endsOn)).length;
  }

  const estimate = estimateOccurrences({
    entry,
    openOccurrence: openOccurrence
      ? { scheduled_date: openOccurrence.scheduled_date }
      : null,
    lastCompletedOn: lastClosedDate,
    startsOn,
    endsOn,
    todayIso: today,
  });
  return estimate.dates.length;
}

function rationaleForMove({ direction, toDate, startsOn, endsOn }) {
  if (toDate < startsOn) return 'move_before_departure';
  if (toDate > endsOn) return 'move_after_return';
  return direction === 'earlier' ? 'move_before_departure' : 'move_after_return';
}

/**
 * @param {object} params
 * @param {object} params.entry
 * @param {object} params.openOccurrence
 * @param {string|null} params.lastClosedDate
 * @param {string} params.startsOn
 * @param {string} params.endsOn
 * @param {string} params.today
 * @param {number} materializedInWindow
 * @param {object[]} [occurrences]
 * @returns {object|null}
 */
function bestMoveSuggestion({
  entry,
  openOccurrence,
  lastClosedDate,
  startsOn,
  endsOn,
  today,
  materializedInWindow,
  occurrences = [],
}) {
  const flex = resolveScheduleFlexibility(entry, today);
  if (flex.flexibility === 'fixed' || flex.flexibility === 'carer_task') {
    return null;
  }
  if (!openOccurrence?.occurrence_id || !openOccurrence?.scheduled_date) {
    return null;
  }

  const openDate = openOccurrence.scheduled_date;
  if (openDate < today && today >= startsOn) {
    return null;
  }

  const isOverdueBeforeAbsence = openDate < today && today < startsOn;

  const inWindowBefore = countInWindowOccurrences({
    entry,
    openOccurrence,
    lastClosedDate,
    startsOn,
    endsOn,
    today,
    materializedInWindow,
    occurrences,
  });
  if (inWindowBefore === 0 && !isOverdueBeforeAbsence) {
    return null;
  }

  const candidates = candidateMoves({
    entry,
    openOccurrence,
    today,
    startsOn,
    endsOn,
    lastClosedDate,
    maxShiftDays: flex.max_shift_days,
    flexibility: flex.flexibility,
  });

  let best = null;
  for (const candidate of candidates) {
    const hypotheticalOpen = {
      ...openOccurrence,
      scheduled_date: candidate.date,
    };
    const inWindowAfter = countInWindowOccurrences({
      entry,
      openOccurrence: hypotheticalOpen,
      lastClosedDate,
      startsOn,
      endsOn,
      today,
      materializedInWindow: 0,
      occurrences: occurrencesForProjection(occurrences, hypotheticalOpen),
    });
    if (inWindowAfter >= inWindowBefore) continue;

    const suggestion = {
      health_entry_id: entry.id,
      occurrence_id: openOccurrence.occurrence_id,
      from_date: openDate,
      to_date: candidate.date,
      direction: candidate.direction,
      in_window_before: inWindowBefore,
      in_window_after: inWindowAfter,
      flexibility: flex.flexibility,
      rationale_code: rationaleForMove({
        direction: candidate.direction,
        toDate: candidate.date,
        startsOn,
        endsOn,
      }),
      _k: candidate.k,
    };

    if (!best) {
      best = suggestion;
      continue;
    }

    const reduction = inWindowBefore - inWindowAfter;
    const bestReduction = best.in_window_before - best.in_window_after;
    if (reduction > bestReduction) {
      best = suggestion;
      continue;
    }
    if (reduction < bestReduction) continue;

    if (candidate.direction === 'earlier' && best.direction !== 'earlier') {
      best = suggestion;
      continue;
    }
    if (candidate.direction !== 'earlier' && best.direction === 'earlier') {
      continue;
    }

    if (candidate.k < best._k) {
      best = suggestion;
    }
  }

  if (best) {
    const { _k, ...rest } = best;
    if (openDate < today && today < startsOn && rest.to_date < startsOn) {
      return { ...rest, rationale_code: 'overdue_do_before_departure' };
    }
    return rest;
  }

  if (isOverdueBeforeAbsence) {
    const beforeLeave = addCalendarDaysIso(startsOn, -1);
    if (beforeLeave >= today && beforeLeave !== openDate) {
      const moves = candidateMoves({
        entry,
        openOccurrence,
        today,
        startsOn,
        endsOn,
        lastClosedDate,
        maxShiftDays: flex.max_shift_days,
        flexibility: flex.flexibility,
      });
      const target = moves.find((c) => c.date === beforeLeave);
      if (target) {
        return {
          health_entry_id: entry.id,
          occurrence_id: openOccurrence.occurrence_id,
          from_date: openDate,
          to_date: target.date,
          direction: target.direction,
          in_window_before: inWindowBefore,
          in_window_after: 0,
          flexibility: flex.flexibility,
          rationale_code: 'overdue_do_before_departure',
        };
      }
    }
  }

  return null;
}

/**
 * @param {object} input
 * @param {{ id: string, starts_on: string, ends_on: string }} input.absence
 * @param {string} input.today
 * @param {{ pet_id: string, entries: object[] }[]} input.pets
 * @returns {{ pets: object[] }}
 */
export function planAbsenceCare(input) {
  const { absence, today, pets } = input;
  const startsOn = absence.starts_on;
  const endsOn = absence.ends_on;

  const resultPets = pets.map((pet) => {
    const suggestions = [];
    const byEntry = [];
    let carerTaskCount = 0;

    for (const row of pet.entries || []) {
      const { entry, open_occurrence: openOccurrence, last_closed_date: lastClosedDate, materialized_in_window: materializedInWindow = 0, occurrences = [] } = row;

      if (!entry || entry.status === 'paused' || entry.status === 'closed') {
        continue;
      }

      const flex = resolveScheduleFlexibility(entry, today);
      const inWindow = countInWindowOccurrences({
        entry,
        openOccurrence,
        lastClosedDate,
        startsOn,
        endsOn,
        today,
        materializedInWindow,
        occurrences,
      });

      if (flex.flexibility === 'fixed') {
        if (inWindow > 0) {
          carerTaskCount += inWindow;
          byEntry.push({
            health_entry_id: entry.id,
            count: inWindow,
            reason: 'fixed',
          });
        }
        continue;
      }

      if (flex.flexibility === 'carer_task') {
        if (inWindow > 0) {
          carerTaskCount += inWindow;
          byEntry.push({
            health_entry_id: entry.id,
            count: inWindow,
            reason: 'carer_task',
          });
        }
        continue;
      }

      const suggestion = bestMoveSuggestion({
        entry,
        openOccurrence,
        lastClosedDate,
        startsOn,
        endsOn,
        today,
        materializedInWindow,
        occurrences,
      });
      if (suggestion) {
        suggestions.push(suggestion);
      } else if (inWindow > 0) {
        carerTaskCount += inWindow;
        byEntry.push({
          health_entry_id: entry.id,
          count: inWindow,
          reason: 'no_valid_move',
        });
      }
    }

    return {
      pet_id: pet.pet_id,
      suggestions,
      carer_tasks: {
        count: carerTaskCount,
        by_entry: byEntry,
      },
    };
  });

  return { pets: resultPets };
}
