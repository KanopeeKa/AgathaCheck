import { logAuditEventSafe } from '../../lib/audit.js';
import { logger } from '../../lib/logger.js';
import { recordPetActivityForPet } from '../../lib/petActivity.js';
import { userCanManageHealthEntry } from '../../lib/petAccess.js';
import {
  runCareCommand,
  sendCareCommandError,
} from '../../lib/care/occurrence/index.js';
import { markSkipped } from '../../lib/care/occurrence/occurrenceRepository.js';
import { slotIsPastDue } from '../../lib/care/schedule/occurrenceStatus.js';
import { extractUserId } from './shared.js';
import {
  isWeightMonitoringEntry,
  WEIGHT_GENERIC_COMPLETE_ERROR,
} from './weightOccurrenceCompletion.js';

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
    [entryId],
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
    [occId, entryId],
  );
  return result.rows[0] || null;
}

export function logOccurrenceAction(pool, req, { userId, entry, action, metadata = {}, activity = null }) {
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
export async function handleCommand(pool, req, res, { command, respond, audit, guard, afterCommand }) {
  const userId = extractUserId(req);
  if (!userId) return res.status(401).json({ error: 'Unauthorized' });
  try {
    const entry = await loadEntry(pool, req.params.id, userId);
    if (!entry) return res.status(404).json({ error: 'Entry not found' });
    if (guard) {
      const blocked = guard(entry);
      if (blocked) return res.status(400).json({ error: blocked });
    }
    const out = await runCareCommand(pool, {
      entryId: entry.id,
      userId,
      req,
      afterCommand: afterCommand
        ? async (db, lockedEntry, cmdOut) => afterCommand(db, lockedEntry, cmdOut, { userId, req })
        : null,
    }, command);
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
    throw err;
  }
}

export function weightGuard(entry) {
  return isWeightMonitoringEntry(entry) ? WEIGHT_GENERIC_COMPLETE_ERROR : null;
}

/**
 * Compat `skip_earlier_missed`: skip earlier past-due open dates in the same command.
 */
export function withEarlierPastDueSkipped(occurrenceId, run) {
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
