import { asyncHandler } from '../../lib/http/asyncHandler.js';
import { normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import { commandResponse, occurrenceToMap } from '../../lib/care/item/index.js';
import {
  completeOccurrenceCommand,
  confirmSkipCommand,
  planAnotherDateCommand,
  recordAsGivenCommand,
  resolveStackCommand,
  skipOccurrenceCommand,
  undoCommand,
} from '../../lib/care/occurrence/index.js';
import { validateSkipReasonForFamily } from '../../lib/care/capabilities.js';
import { extractUserId } from './shared.js';
import {
  handleCommand,
  loadEntry,
  weightGuard,
  withEarlierPastDueSkipped,
} from './occurrenceHttpBridge.js';

export function registerOccurrenceCommandRoutes(router, pool) {
router.post('/:id/occurrences/:occId/complete', asyncHandler(async (req, res) => {
    const body = req.body || {};
    const occurrenceId = req.params.occId;
    const run = (ctx) => completeOccurrenceCommand(ctx, {
      occurrenceId,
      completedOn: normalizeCalendarDateInput(body.completed_on || body.completedOn),
      notes: body.notes || '',
      nextChoice: body.next_choice || body.nextChoice || null,
      rememberChoice: Boolean(body.remember_choice ?? body.rememberChoice),
      earlierChoice: body.earlier_choice || body.earlierChoice || null,
      body,
    });
    const skipEarlier = Boolean(body.skip_earlier_missed || body.skipEarlierMissed);
    return handleCommand(pool, req, res, {
      guard: weightGuard,
      command: skipEarlier ? withEarlierPastDueSkipped(occurrenceId, run) : run,
      audit: () => ({
        action: 'health_occurrence.completed',
        metadata: { occurrence_id: occurrenceId },
        activity: 'complete_occurrence',
      }),
      respond: async (out) => ({
        body: await commandResponse(pool, out, req, {
          occurrence: occurrenceToMap(out.occurrence),
          next_choice_applied: out.appliedChoice ?? null,
        }),
      }),
    });
  }));

  router.post('/:id/occurrences/:occId/skip', asyncHandler(async (req, res) => {
    const body = req.body || {};
    const occurrenceId = req.params.occId;
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const entry = await loadEntry(pool, req.params.id, userId);
    if (!entry) return res.status(404).json({ error: 'Entry not found' });
    const skipCheck = validateSkipReasonForFamily(
      entry.care_family,
      body.reason_code || body.reasonCode || null,
      body.notes || '',
    );
    if (!skipCheck.ok) {
      return res.status(skipCheck.status).json(skipCheck.body);
    }
    return handleCommand(pool, req, res, {
      command: (ctx) => skipOccurrenceCommand(ctx, {
        occurrenceId,
        notes: body.notes || '',
        reasonCode: body.reason_code || body.reasonCode || null,
      }),
      audit: () => ({ action: 'health_occurrence.skipped', metadata: { occurrence_id: occurrenceId } }),
      respond: async (out) => {
        const occurrence = occurrenceToMap(out.occurrence);
        return { body: { ...occurrence, ...(await commandResponse(pool, out, req, { occurrence })) } };
      },
    });
  }));

  router.post('/:id/occurrences', asyncHandler(async (req, res) => {
    const body = req.body || {};
    return handleCommand(pool, req, res, {
      command: (ctx) => planAnotherDateCommand(ctx, {
        date: normalizeCalendarDateInput(body.scheduled_date || body.scheduledDate),
        time: body.scheduled_time || body.scheduledTime || null,
        reasonCode: body.reason_code || body.reasonCode || null,
      }),
      audit: (out) => ({
        action: 'health_occurrence.planned',
        metadata: { occurrence_id: out.occurrenceId },
        activity: 'plan_date',
      }),
      respond: async (out) => ({
        status: 201,
        body: await commandResponse(pool, out, req, {
          occurrence_id: out.occurrenceId,
          warnings: out.warnings,
        }),
      }),
    });
  }));

  router.post('/:id/occurrences/:occId/record', asyncHandler(async (req, res) => {
    const body = req.body || {};
    const occurrenceId = req.params.occId;
    return handleCommand(pool, req, res, {
      guard: weightGuard,
      command: (ctx) => recordAsGivenCommand(ctx, {
        occurrenceId,
        completedOn: normalizeCalendarDateInput(body.completed_on || body.completedOn),
      }),
      audit: () => ({ action: 'health_occurrence.recorded', metadata: { occurrence_id: occurrenceId } }),
      respond: async (out) => ({
        body: await commandResponse(pool, out, req, { occurrence: occurrenceToMap(out.occurrence) }),
      }),
    });
  }));

  router.post('/:id/occurrences/:occId/confirm-skip', asyncHandler(async (req, res) => {
    const occurrenceId = req.params.occId;
    return handleCommand(pool, req, res, {
      guard: weightGuard,
      command: (ctx) => confirmSkipCommand(ctx, { occurrenceId }),
      audit: () => ({
        action: 'health_occurrence.confirm_skipped',
        metadata: { occurrence_id: occurrenceId },
        activity: 'skip',
      }),
      respond: async (out) => ({
        body: await commandResponse(pool, out, req, { occurrence: occurrenceToMap(out.occurrence) }),
      }),
    });
  }));

  router.post('/:id/occurrences/resolve-stack', asyncHandler(async (req, res) => {
    const body = req.body || {};
    const given = Array.isArray(body.given) ? body.given : [];
    const notGiven = Array.isArray(body.not_given ?? body.notGiven) ? (body.not_given ?? body.notGiven) : [];
    return handleCommand(pool, req, res, {
      guard: weightGuard,
      command: (ctx) => resolveStackCommand(ctx, { given, notGiven }),
      audit: () => ({
        action: 'health_occurrence.stack_resolved',
        metadata: { given: given.length, not_given: notGiven.length },
        activity: 'record_doses',
      }),
      respond: async (out) => ({
        body: await commandResponse(pool, out, req, {
          given: out.given,
          not_given: out.notGiven,
          ignored: out.ignored,
        }),
      }),
    });
  }));

  // Compatibility (deleted in child F): per-occurrence undo.
  router.post('/:id/occurrences/:occId/undo', asyncHandler(async (req, res) => handleCommand(pool, req, res, {
    command: (ctx) => undoCommand(ctx, {}),
    audit: (out) => ({
      action: 'health_occurrence.undone',
      metadata: { occurrence_id: req.params.occId, action_type: out.undoneType },
    }),
    respond: async (out) => ({
      body: out.occurrence ? occurrenceToMap(out.occurrence) : { undone: out.undoneType },
    }),
  })));
}

