import { dateToIsoDate } from '../../calendarDate.js';
import { refreshPetWeightCache } from '../../petWeightSync.js';
import { SCHEDULE_EVENT_COMPLETED, SCHEDULE_EVENT_COMPLETION_DATE_CHANGED } from '../schedule/scheduleEventLedger.js';
import {
  deleteWeightEntryById,
  unlinkWeightFromOccurrence,
  updateWeightDateForOccurrence,
} from './weightObservationRepository.js';
import { registerObservationCompletionHook } from './observationCompletionHooks.js';

const NUMERIC_WEIGHT = 'numeric_weight';

function observationFromPayload(payload) {
  if (payload?.observation?.kind === NUMERIC_WEIGHT) {
    return payload.observation;
  }
  if (payload?.weight?.id) {
    return { kind: NUMERIC_WEIGHT, id: payload.weight.id, created: payload.weight.created === true };
  }
  return null;
}

async function undoCompletedWeight(ctx, event) {
  if (event.event_type !== SCHEDULE_EVENT_COMPLETED) return;
  const payload = event.payload || {};
  const occurrenceId = event.health_occurrence_id;
  if (!occurrenceId) return;

  const observation = observationFromPayload(payload);
  let changed = false;
  if (observation) {
    if (observation.created) {
      await deleteWeightEntryById(ctx.db, observation.id, occurrenceId);
      changed = true;
    } else {
      const row = await unlinkWeightFromOccurrence(ctx.db, observation.id, occurrenceId);
      if (row) changed = true;
    }
  } else {
    const row = await unlinkWeightFromOccurrence(ctx.db, null, occurrenceId);
    if (row) changed = true;
  }
  if (changed && ctx.entry?.pet_id) {
    await refreshPetWeightCache(ctx.db, ctx.entry.pet_id);
  }
}

async function undoCompletionDateWeight(ctx, event) {
  if (event.event_type !== SCHEDULE_EVENT_COMPLETION_DATE_CHANGED) return;
  const before = event.payload?.weight_date_before;
  const occurrenceId = event.health_occurrence_id;
  if (!before || !occurrenceId) return;
  const updated = await updateWeightDateForOccurrence(ctx.db, occurrenceId, before);
  if (updated && ctx.entry?.pet_id) {
    await refreshPetWeightCache(ctx.db, ctx.entry.pet_id);
  }
}

registerObservationCompletionHook({
  async onUndoEvent(ctx, event) {
    await undoCompletedWeight(ctx, event);
    await undoCompletionDateWeight(ctx, event);
  },
  async onCompletionDateChange(ctx, occurrenceId, completedOn) {
    const updated = await updateWeightDateForOccurrence(ctx.db, occurrenceId, completedOn);
    if (!updated) return null;
    const beforeIso = dateToIsoDate(updated.date_before);
    return beforeIso ? { weight_date_before: beforeIso } : null;
  },
});
