import { normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import { syncResolutionAfterAbsencePostpone } from '../../lib/care/absence/syncResolutionAfterSchedule.js';
import {
  adjustCadenceCommand,
  postponeCommand,
  resumeCommand,
  undoCommand,
} from '../../lib/care/occurrence/index.js';
import { commandResponse } from './careItemWire.js';
import { handleCommand } from './occurrencesRouter.js';

/** Postpone until / Pause / Resume / cadence / whole-command undo (D-CSM-028, D-CSM-029). */
export function registerScheduleRoutes(router, pool) {
  router.post('/:id/postpone', (req, res) => {
    const body = req.body || {};
    const rawUntil = body.until ?? null;
    const until = rawUntil == null || rawUntil === '' ? null : normalizeCalendarDateInput(rawUntil);
    if (rawUntil && !until) return res.status(400).json({ error: 'Invalid until date' });
    const absenceId = body.absence_id || body.absenceId || null;
    const reason = body.reason || (until ? 'manual' : 'pause');
    return handleCommand(pool, req, res, {
      command: (ctx) => postponeCommand(ctx, {
        until,
        reason,
        absenceId,
        occurrenceId: body.occurrence_id || body.occurrenceId || null,
      }),
      audit: () => ({
        action: until ? 'health_entry.postponed' : 'health_entry.paused',
        metadata: { until, reason },
        activity: until ? 'postpone' : 'pause',
      }),
      respond: async (out) => {
        if (until && reason === 'absence' && absenceId) {
          await syncResolutionAfterAbsencePostpone(pool, {
            healthEntryId: req.params.id,
            petId: out.entry.pet_id,
            absenceId,
            until,
            lookedAfterBy: body.looked_after_by ?? body.lookedAfterBy ?? null,
            absenceNote: body.absence_note ?? body.absenceNote ?? null,
          });
        }
        return { body: await commandResponse(pool, out, req, { until: out.until }) };
      },
    });
  });

  router.post('/:id/resume', (req, res) => {
    const body = req.body || {};
    const date = normalizeCalendarDateInput(body.date || body.resume_on || body.resumeOn);
    return handleCommand(pool, req, res, {
      command: (ctx) => resumeCommand(ctx, {
        date,
        reasonNote: body.reason_note || body.reasonNote || body.notes || null,
      }),
      audit: (out) => ({ action: 'health_entry.resumed', metadata: { resume_on: out.resumeOn } }),
      respond: async (out) => {
        const wire = await commandResponse(pool, out, req, { resume_on: out.resumeOn });
        return { body: { ...wire.entry, ...wire } };
      },
    });
  });

  router.post('/:id/adjust-cadence', (req, res) => {
    const body = req.body || {};
    return handleCommand(pool, req, res, {
      command: (ctx) => adjustCadenceCommand(ctx, {
        effectiveFrom: body.effective_from || body.effectiveFrom,
        frequency: body.frequency,
        frequencyInterval: body.frequency_interval ?? body.frequencyInterval,
        frequencyDays: body.frequency_days ?? body.frequencyDays,
        recurrenceAnchor: body.recurrence_anchor ?? body.recurrenceAnchor,
        reasonCode: body.reason_code || body.reasonCode || null,
        reasonNote: body.reason_note || body.reasonNote || body.notes || null,
      }),
      audit: () => ({
        action: 'health_entry.cadence_adjusted',
        metadata: { effective_from: body.effective_from || body.effectiveFrom },
        activity: 'adjust_cadence',
      }),
      respond: async (out) => ({ body: await commandResponse(pool, out, req) }),
    });
  });

  router.post('/:id/schedule/undo', (req, res) => {
    const body = req.body || {};
    return handleCommand(pool, req, res, {
      command: (ctx) => undoCommand(ctx, { undoToken: body.undo_token || body.undoToken || null }),
      audit: (out) => ({
        action: 'health_entry.schedule_undone',
        metadata: { action_type: out.undoneType },
        activity: 'schedule_undo',
      }),
      respond: async (out) => ({
        body: await commandResponse(pool, out, req, {
          action_type: out.undoneType === 'completed' ? 'complete' : out.undoneType,
          occurrence: out.occurrence ? {
            id: out.occurrence.id,
            status: out.occurrence.status,
            scheduled_date: out.occurrence.scheduled_date,
          } : null,
        }),
      }),
    });
  });
}
