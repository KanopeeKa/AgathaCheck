import { publicError } from '../../config/security.js';
import { normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import { logger } from '../../lib/logger.js';
import { recordPetActivityForPet } from '../../lib/petActivity.js';
import { userCanManageHealthEntry } from '../../lib/petAccess.js';
import {
  completeOccurrenceCommand,
  listOpenRows,
  openOccurrenceToWire,
  planAnotherDateCommand,
  recordAsGivenCommand,
  resolveCareAsOfForRead,
  resolveStackCommand,
  runCareCommand,
  sendCareCommandError,
  skipOccurrenceCommand,
  undoCommand,
} from '../../lib/care/occurrence/index.js';
import { markSkipped } from '../../lib/care/occurrence/occurrenceRepository.js';
import { slotIsPastDue } from '../../lib/care/schedule/occurrenceStatus.js';
import { occurrenceToMap } from '../../lib/occurrenceScheduling.js';
import { commandResponse } from './careItemWire.js';
import { extractUserId } from './shared.js';
import {
  isWeightMonitoringEntry,
  WEIGHT_GENERIC_COMPLETE_ERROR,
} from './weightOccurrenceCompletion.js';

const PAST_STATUSES = new Set(['overdue', 'not_recorded']);
const CLIENT_TAG = /^[a-z][a-z_]{0,31}$/;

/**
 * Optional client `source` / `path` for audit metadata (§18.10): short
 * snake_case tags only, never free text.
 */
function clientTags(req) {
  const body = req.body || {};
  const tags = {};
  if (typeof body.source === 'string' && CLIENT_TAG.test(body.source)) tags.source = body.source;
  if (typeof body.path === 'string' && CLIENT_TAG.test(body.path)) tags.path = body.path;
  return tags;
}

export async function loadEntry(pool, entryId, userId) {
  if (!(await userCanManageHealthEntry(pool, entryId, userId))) {
    return null;
  }
  const result = await pool.query(
    'SELECT * FROM health_entries WHERE id = $1',
    [entryId]
  );
  return result.rows[0] || null;
}

export async function loadOccurrence(pool, entryId, occId) {
  const result = await pool.query(
    `SELECT ho.*,
      TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS marked_by_name
     FROM health_occurrences ho
     LEFT JOIN users u ON u.id = ho.marked_by_user_id
     WHERE ho.id = $1 AND ho.health_entry_id = $2`,
    [occId, entryId]
  );
  return result.rows[0] || null;
}

function logOccurrenceAction(pool, req, { userId, entry, action, metadata = {}, activity = null }) {
  logAuditEventSafe(pool, {
    actorUserId: userId,
    action,
    resourceType: 'health_entry',
    resourceId: entry.id,
    petId: entry.pet_id,
    metadata: { ...metadata, ...clientTags(req) },
    req,
  });
  if (activity) {
    recordPetActivityForPet(pool, {
      petId: entry.pet_id,
      actorUserId: userId,
      eventType: 'health_log',
      metadata: { action: activity, entry_type: entry.type },
    });
  }
}

/**
 * Parse, authorise, run one command, answer. Shared by every occurrence route.
 */
async function handleCommand(pool, req, res, { command, respond, audit, guard }) {
  const userId = extractUserId(req);
  if (!userId) return res.status(401).json({ error: 'Unauthorized' });
  try {
    const entry = await loadEntry(pool, req.params.id, userId);
    if (!entry) return res.status(404).json({ error: 'Entry not found' });
    if (guard) {
      const blocked = guard(entry);
      if (blocked) return res.status(400).json({ error: blocked });
    }
    const out = await runCareCommand(pool, { entryId: entry.id, userId, req }, command);
    if (!out) return res.status(404).json({ error: 'Entry not found' });
    if (audit) logOccurrenceAction(pool, req, { userId, entry, ...audit(out) });
    const { status = 200, body } = await respond(out);
    return res.status(status).json(body);
  } catch (err) {
    if (sendCareCommandError(res, err)) {
      logger.warn({
        requestId: req.requestId || req.headers?.['x-request-id'] || null,
        status: err.status,
        code: err.code,
        route: req.route?.path || null,
      }, 'care command refused');
      return undefined;
    }
    return res.status(500).json({ error: publicError(err) });
  }
}

function weightGuard(entry) {
  return isWeightMonitoringEntry(entry) ? WEIGHT_GENERIC_COMPLETE_ERROR : null;
}

/**
 * Compat `skip_earlier_missed`: skip earlier past-due open dates in the same command.
 */
function withEarlierPastDueSkipped(occurrenceId, run) {
  return async (ctx) => {
    const target = ctx.openRows.find((o) => o.id === occurrenceId);
    if (!target) return run(ctx);
    const skippedIds = new Set();
    for (const row of ctx.openRows) {
      if (row.id === occurrenceId) continue;
      const earlier = row.scheduled_date < target.scheduled_date
        || (row.scheduled_date === target.scheduled_date
          && (row.scheduled_time ?? '') < (target.scheduled_time ?? ''));
      if (!earlier || !slotIsPastDue({ date: row.scheduled_date, time: row.scheduled_time }, ctx.asOf)) continue;
      await markSkipped(ctx.db, {
        entryId: ctx.entry.id, occurrenceId: row.id, closeReason: 'user', userId: ctx.userId,
      });
      ctx.trace.closedRow(row);
      skippedIds.add(row.id);
    }
    return run({ ...ctx, openRows: ctx.openRows.filter((o) => !skippedIds.has(o.id)) });
  };
}

export function registerOccurrenceRoutes(router, pool) {
  router.get('/:id/occurrences', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entry = await loadEntry(pool, req.params.id, userId);
      if (!entry) return res.status(404).json({ error: 'Entry not found' });
      const status = req.query.status || 'open';
      if (status === 'open') {
        const asOf = await resolveCareAsOfForRead(pool, entry, req);
        const rows = await listOpenRows(pool, entry.id);
        const names = await pool.query(
          `SELECT ho.id, TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS marked_by_name
           FROM health_occurrences ho LEFT JOIN users u ON u.id = ho.marked_by_user_id
           WHERE ho.health_entry_id = $1 AND ho.status = 'pending'`,
          [entry.id],
        );
        const nameById = new Map(names.rows.map((r) => [r.id, r.marked_by_name]));
        const wire = rows.map((row) => {
          const status = openOccurrenceToWire(row, entry, asOf);
          return {
            ...occurrenceToMap({ ...row, marked_by_name: nameById.get(row.id) }),
            status: 'pending',
            occurrence_status: status.status,
            origin: status.origin,
            missed: PAST_STATUSES.has(status.status),
          };
        });
        wire.sort((a, b) => `${b.scheduled_date}|${b.scheduled_time ?? ''}`
          .localeCompare(`${a.scheduled_date}|${a.scheduled_time ?? ''}`));
        return res.json(wire);
      }
      const result = await pool.query(
        `SELECT ho.*,
          TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS marked_by_name
         FROM health_occurrences ho
         LEFT JOIN users u ON u.id = ho.marked_by_user_id
         WHERE ho.health_entry_id = $1 AND ho.status IN ('completed', 'skipped')
         ORDER BY ho.scheduled_date DESC,
           COALESCE(ho.scheduled_time, '00:00:00'::time) DESC`,
        [entry.id]
      );
      return res.json(result.rows.map(occurrenceToMap));
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/occurrences/:occId/complete', (req, res) => {
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
  });

  router.post('/:id/occurrences/:occId/skip', (req, res) => {
    const body = req.body || {};
    const occurrenceId = req.params.occId;
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
  });

  router.post('/:id/occurrences', (req, res) => {
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
  });

  router.post('/:id/occurrences/:occId/record', (req, res) => {
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
  });

  router.post('/:id/occurrences/resolve-stack', (req, res) => {
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
        body: await commandResponse(pool, out, req, { given: out.given, not_given: out.notGiven }),
      }),
    });
  });

  // Compatibility (deleted in child F): per-occurrence undo.
  router.post('/:id/occurrences/:occId/undo', (req, res) => handleCommand(pool, req, res, {
    command: (ctx) => undoCommand(ctx, {}),
    audit: (out) => ({
      action: 'health_occurrence.undone',
      metadata: { occurrence_id: req.params.occId, action_type: out.undoneType },
    }),
    respond: async (out) => ({
      body: out.occurrence ? occurrenceToMap(out.occurrence) : { undone: out.undoneType },
    }),
  }));
}

export { handleCommand, logOccurrenceAction };
