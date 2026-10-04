import { normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import { syncResolutionAfterAbsenceReschedule } from '../../lib/care/absence/syncResolutionAfterSchedule.js';
import { changeDateCommand } from '../../lib/care/occurrence/index.js';
import { occurrenceToMap } from '../../lib/occurrenceScheduling.js';
import { commandResponse } from './careItemWire.js';
import { handleCommand } from './occurrencesRouter.js';

export function registerRescheduleOccurrenceRoutes(router, pool) {
  router.post('/:id/occurrences/:occId/reschedule', (req, res) => {
    const body = req.body || {};
    const occurrenceId = req.params.occId;
    const scheduledDate = normalizeCalendarDateInput(body.scheduled_date || body.scheduledDate);
    if (!scheduledDate) {
      return res.status(400).json({ error: 'scheduled_date is required' });
    }
    return handleCommand(pool, req, res, {
      command: (ctx) => changeDateCommand(ctx, {
        occurrenceId,
        newDate: scheduledDate,
        scope: body.scope || 'this',
        reasonCode: body.reason_code || body.reasonCode || null,
        reasonNote: body.reason_note || body.reasonNote || body.notes || null,
      }),
      audit: (out) => ({
        action: 'health_occurrence.rescheduled',
        metadata: { occurrence_id: occurrenceId, scheduled_date: scheduledDate, scope: out.scope },
      }),
      respond: async (out) => {
        const absenceId = body.absence_id || body.absenceId || null;
        if (absenceId && out.occurrence?.scheduled_date) {
          await syncResolutionAfterAbsenceReschedule(pool, {
            healthEntryId: req.params.id,
            petId: out.entry.pet_id,
            absenceId,
            newScheduledDate: out.occurrence.scheduled_date,
            body: {
              looked_after_by: body.looked_after_by ?? body.lookedAfterBy,
              absence_note: body.absence_note ?? body.absenceNote,
            },
          });
        }
        return {
          body: await commandResponse(pool, out, req, {
            occurrence: out.occurrence ? occurrenceToMap(out.occurrence) : null,
            warnings: out.warnings,
            scope: out.scope,
          }),
        };
      },
    });
  });
}
