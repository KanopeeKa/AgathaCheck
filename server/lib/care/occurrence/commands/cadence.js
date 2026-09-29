/**
 * Cadence change "this and following" (D-CSM-006, D-CSM-032).
 */

import { normalizeCalendarDateInput } from '../../../calendarDate.js';
import { resolveRecurrenceAnchorForWrite } from '../../schedule/recurrenceAnchorDefaults.js';
import { SCHEDULE_EVENT_CADENCE_ADJUSTED, insertCareScheduleEvent } from '../../schedule/scheduleEventLedger.js';
import { seriesStep } from '../../schedule/seriesDates.js';
import { badRequest } from '../careCommandError.js';
import { reloadEntry } from '../entryRepository.js';
import { listOpenRows } from '../occurrenceRepository.js';
import { reconcileScheduleEdit } from './lifecycle.js';

/**
 * @param {object} ctx
 * @param {object} params
 */
export async function adjustCadenceCommand(ctx, {
  effectiveFrom,
  frequency,
  frequencyInterval,
  frequencyDays,
  recurrenceAnchor,
  reasonCode = null,
  reasonNote = null,
}) {
  const { db, entry, asOf, userId } = ctx;
  if ((entry.status || 'active') !== 'active' || !seriesStep(entry)) {
    throw badRequest('cadence_not_adjustable', 'Entry cadence cannot be adjusted');
  }
  const effectiveFromIso = normalizeCalendarDateInput(effectiveFrom);
  if (!effectiveFromIso) throw badRequest('effective_from_required', 'effective_from is required');
  if (effectiveFromIso < asOf.todayIso) {
    throw badRequest('invalid_date', 'effective_from cannot be in the past');
  }
  const nextAnchor = recurrenceAnchor != null && recurrenceAnchor !== ''
    ? resolveRecurrenceAnchorForWrite({ careFamily: entry.care_family, explicitAnchor: recurrenceAnchor })
    : entry.recurrence_anchor;

  const updated = await db.query(
    `UPDATE health_entries SET frequency = $1, frequency_interval = $2, frequency_days = $3,
       recurrence_anchor = $4, updated_at = NOW()
     WHERE id = $5 RETURNING *`,
    [
      frequency ?? entry.frequency,
      frequencyInterval ?? entry.frequency_interval ?? 1,
      frequencyDays !== undefined ? frequencyDays : entry.frequency_days,
      nextAnchor,
      entry.id,
    ],
  );
  const after = updated.rows[0];
  const openRows = await listOpenRows(db, entry.id);
  const nextOpen = openRows[0]?.scheduled_date ?? null;
  await reconcileScheduleEdit({ ...ctx, entry: after, openRows }, {
    before: entry,
    requestedNextDate: !nextOpen || nextOpen >= effectiveFromIso ? effectiveFromIso : null,
  });
  await insertCareScheduleEvent(db, {
    healthEntryId: entry.id,
    eventType: SCHEDULE_EVENT_CADENCE_ADJUSTED,
    fromAnchor: entry.recurrence_anchor,
    toAnchor: nextAnchor,
    reasonCode,
    reasonNote,
    actorUserId: userId,
    effectiveFrom: effectiveFromIso,
  });
  return { event: null, result: { entryAfterUpdate: await reloadEntry(db, entry.id) } };
}
