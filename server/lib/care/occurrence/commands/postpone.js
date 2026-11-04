/**
 * Postpone until / Pause / Resume — one mechanism (D-CSM-028).
 */

import { dateToIsoDate } from '../../../calendarDate.js';
import {
  isFixedSchedule,
  scheduleAnchorIso,
} from '../../schedule/fixedSlots.js';
import { scheduleTimesFromEntry } from '../../schedule/scheduleTimes.js';
import {
  SCHEDULE_EVENT_POSTPONED,
  SCHEDULE_EVENT_RESUMED,
} from '../../schedule/scheduleEventLedger.js';
import {
  addSteps,
  isSeriesDate,
  seriesDateOnOrAfter,
  seriesStep,
} from '../../schedule/seriesDates.js';
import { CareCommandError, badRequest } from '../careCommandError.js';
import { updateEntryFields } from '../entryRepository.js';
import {
  applyOpenOccurrencePauseCloseRule,
  insertOpenOccurrence,
  moveOpenOccurrence,
} from '../occurrenceRepository.js';

export const POSTPONE_REASONS = ['pause', 'absence', 'manual'];

/**
 * @param {object} ctx
 * @param {object} params
 * @param {string|null} params.until YYYY-MM-DD, or null to pause without an end
 * @param {'pause'|'absence'|'manual'} [params.reason]
 * @param {string|null} [params.absenceId]
 * @param {string|null} [params.occurrenceId] After it's done: the date to move (default: earliest open)
 */
export async function postponeCommand(ctx, {
  until = null, reason = 'manual', absenceId = null, occurrenceId = null,
}) {
  const { db, entry, openRows, trace, asOf } = ctx;
  if (!POSTPONE_REASONS.includes(reason)) {
    throw badRequest('invalid_reason', `reason must be one of ${POSTPONE_REASONS.join(', ')}`);
  }
  if (until && until < asOf.todayIso) {
    throw badRequest('invalid_date', 'Postpone date cannot be in the past');
  }
  if ((entry.status || 'active') === 'completed') {
    throw badRequest('item_finished', 'This care item is finished');
  }
  const fixed = isFixedSchedule(entry);
  let fromDate = asOf.todayIso;

  if (until && !fixed) {
    const target = occurrenceId
      ? openRows.find((o) => o.id === occurrenceId)
      : openRows[0];
    if (!target) throw new CareCommandError(409, 'occurrence_not_open', 'Nothing open to postpone');
    fromDate = target.scheduled_date;
    if (until !== target.scheduled_date) {
      trace.movedRow(target);
      const moved = await moveOpenOccurrence(db, {
        entryId: entry.id, occurrenceId: target.id, date: until, origin: 'planned',
      });
      if (!moved) throw new CareCommandError(409, 'date_already_planned', 'That date is already planned');
    }
    if (entry.status === 'paused') {
      await updateEntryFields(db, entry.id, { status: 'active', paused_since: null, paused_until: null });
      trace.markEntryChanged();
    }
  } else {
    const pauseRows = fixed
      ? openRows.filter((o) => o.origin === 'schedule')
      : openRows;
    await applyOpenOccurrencePauseCloseRule(db, {
      entryId: entry.id,
      rows: pauseRows,
      asOf,
      trace,
      until: fixed ? until : null,
      onlyOrigin: fixed ? 'schedule' : null,
    });
    const pauseResumeAnchor = !fixed && openRows[0]?.scheduled_date
      ? dateToIsoDate(openRows[0].scheduled_date)
      : null;
    await updateEntryFields(db, entry.id, {
      status: 'paused',
      paused_since: entry.status === 'paused' ? dateToIsoDate(entry.paused_since) : asOf.todayIso,
      paused_until: fixed ? until : null,
      ...(pauseResumeAnchor ? { series_resumed_on: pauseResumeAnchor } : {}),
    });
    trace.markEntryChanged();
  }

  return {
    event: {
      type: SCHEDULE_EVENT_POSTPONED,
      fromDate,
      toDate: until,
      reasonCode: reason,
      extra: { reason, until, absence_id: absenceId },
    },
    result: { until, reason },
  };
}

/**
 * Default resume date (D-CSM-028): the date it would have had without the pause.
 *
 * @param {object} entry
 * @param {object[]} openRows
 * @param {{ todayIso: string, nowTimeIso: string }} asOf
 * @returns {string}
 */
export function defaultResumeDate(entry, openRows, asOf) {
  if (!seriesStep(entry)) return openRows[0]?.scheduled_date ?? asOf.todayIso;
  if (isFixedSchedule(entry)) {
    const anchor = scheduleAnchorIso(entry) || asOf.todayIso;
    const today = seriesDateOnOrAfter(anchor, entry, asOf.todayIso);
    if (today === asOf.todayIso) {
      const times = scheduleTimesFromEntry(entry);
      const last = times[times.length - 1];
      if (last == null || last >= (asOf.nowTimeIso ?? '00:00')) return today;
      return seriesDateOnOrAfter(anchor, entry, addSteps(asOf.todayIso, { frequency: 'daily' }, 1));
    }
    return today;
  }
  if (!openRows.length) {
    const anchor = dateToIsoDate(entry.series_resumed_on)
      || dateToIsoDate(entry.next_due_date)
      || dateToIsoDate(entry.start_date)
      || asOf.todayIso;
    return seriesDateOnOrAfter(anchor, entry, asOf.todayIso);
  }
  let date = openRows[0].scheduled_date;
  let guard = 0;
  while (date < asOf.todayIso && guard < 1000) {
    date = addSteps(date, entry, 1);
    guard += 1;
  }
  return date;
}

/**
 * @param {object} ctx
 * @param {{ date?: string|null, reasonNote?: string|null }} params
 */
export async function resumeCommand(ctx, { date = null, reasonNote = null }) {
  const { db, entry, openRows, trace, asOf } = ctx;
  if (entry.status !== 'paused') {
    throw badRequest('not_paused', 'This care item is not paused');
  }
  const resumeOn = date || defaultResumeDate(entry, openRows, asOf);
  if (resumeOn < asOf.todayIso) throw badRequest('invalid_date', 'Resume date cannot be in the past');

  const fields = { status: 'active', paused_since: null, paused_until: null, series_resumed_on: null };
  if (isFixedSchedule(entry)) {
    const anchor = scheduleAnchorIso(entry);
    if (anchor && isSeriesDate(anchor, entry, resumeOn)) {
      fields.series_resumed_on = resumeOn;
    } else {
      fields.schedule_anchor_date = resumeOn;
      fields.series_resumed_on = resumeOn;
    }
  } else if (seriesStep(entry) || openRows.length) {
    const target = openRows[0];
    if (target && target.scheduled_date !== resumeOn) {
      trace.movedRow(target);
      await moveOpenOccurrence(db, {
        entryId: entry.id, occurrenceId: target.id, date: resumeOn, origin: 'planned',
      });
    } else if (!target) {
      const id = await insertOpenOccurrence(db, {
        entryId: entry.id, date: resumeOn, time: null, origin: 'planned',
      });
      trace.createdRow(id, 'planned', true);
    }
  }
  await updateEntryFields(db, entry.id, fields);
  trace.markEntryChanged();
  return {
    event: {
      type: SCHEDULE_EVENT_RESUMED,
      fromDate: dateToIsoDate(entry.paused_since),
      toDate: resumeOn,
      reasonNote,
    },
    result: { resumeOn },
  };
}
