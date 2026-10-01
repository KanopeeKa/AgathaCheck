import { publicError } from '../../config/security.js';
import { normalizeCalendarDateInput, dateToIsoDate } from '../../lib/calendarDate.js';
import { userCanManageHealthEntry } from '../../lib/petAccess.js';
import {
  closeSeriesCommand,
  completeOccurrenceCommand,
  createInitialOccurrences,
  listOpenRows,
  reopenSeriesCommand,
  undoCommand,
} from '../../lib/care/occurrence/index.js';
import { seriesStep } from '../../lib/care/schedule/seriesDates.js';
import { careItemWire } from './careItemWire.js';
import { extractUserId, historyToMap } from './shared.js';
import { handleCommand } from './occurrencesRouter.js';
import {
  isWeightMonitoringEntry,
  WEIGHT_GENERIC_COMPLETE_ERROR,
} from './weightOccurrenceCompletion.js';

async function entryBody(pool, out, req) {
  return careItemWire(pool, out.entry, req, { openRows: out.openOccurrences, asOf: out.asOf });
}

export function registerCompletionRoutes(router, pool) {
  // Compatibility (deleted in child F): completes the earliest open date;
  // never 400 for an active planned item (D-CSM-019). A needed next-date
  // choice defaults to Keep.
  router.post('/:id/mark-taken', (req, res) => {
    const body = req.body || {};
    return handleCommand(pool, req, res, {
      guard: (entry) => (isWeightMonitoringEntry(entry) ? WEIGHT_GENERIC_COMPLETE_ERROR : null),
      command: async (ctx) => {
        let openRows = ctx.openRows;
        if (
          openRows.length === 0
          && ctx.entry.status === 'paused'
        ) {
          return { event: null, result: { occurrence: null, paused: true } };
        }

        // The command runner's normal sync materialises recurring heads. Legacy
        // one-off rows can still lack an occurrence (for example, imported
        // rows), so create their canonical date inside this command transaction.
        if (
          openRows.length === 0
          && ctx.entry.status === 'active'
          && (ctx.entry.care_planning || 'planned') !== 'unplanned'
          && !seriesStep(ctx.entry)
        ) {
          const firstDate = dateToIsoDate(ctx.initialDates.next_due_date)
            || dateToIsoDate(ctx.initialDates.start_date)
            || ctx.asOf.todayIso;
          await createInitialOccurrences(ctx, { firstDate });
          openRows = await listOpenRows(ctx.db, ctx.entry.id);
        }

        const target = openRows[0];
        if (!target) return { event: null, result: { occurrence: null } };
        return completeOccurrenceCommand({ ...ctx, openRows }, {
          occurrenceId: target.id,
          completedOn: normalizeCalendarDateInput(body.completed_on || body.completedOn),
          notes: body.notes || '',
          nextChoice: 'keep',
          earlierChoice: 'keep',
          body,
        });
      },
      audit: (out) => ({
        action: 'health_entry.marked_complete',
        metadata: { occurrence_id: out.occurrence?.id ?? null, via: 'mark-taken' },
        activity: 'complete',
      }),
      respond: async (out) => {
        if (!out.occurrence) {
          return {
            status: 400,
            body: { error: out.paused ? 'Care item is paused' : 'No open date to complete' },
          };
        }
        return { body: await entryBody(pool, out, req) };
      },
    });
  });

  // Compatibility (deleted in child F).
  router.post('/:id/undo-complete', (req, res) => handleCommand(pool, req, res, {
    command: (ctx) => undoCommand(ctx, {}),
    audit: () => ({ action: 'health_entry.completion_undone', metadata: { via: 'undoCommand' }, activity: 'undo_complete' }),
    respond: async (out) => {
      if (out.undoneType !== 'completed') {
        return { status: 400, body: { error: 'Last action is not a completion; use POST /:id/schedule/undo instead' } };
      }
      return { body: await entryBody(pool, out, req) };
    },
  }));

  router.post('/:id/close', (req, res) => handleCommand(pool, req, res, {
    command: (ctx) => closeSeriesCommand(ctx),
    audit: () => ({ action: 'health_entry.closed', metadata: {}, activity: 'close' }),
    respond: async (out) => ({ body: await entryBody(pool, out, req) }),
  }));

  router.post('/:id/reopen', (req, res) => handleCommand(pool, req, res, {
    command: (ctx) => reopenSeriesCommand(ctx),
    audit: () => ({ action: 'health_entry.reopened', metadata: {}, activity: 'reopen' }),
    respond: async (out) => ({ body: await entryBody(pool, out, req) }),
  }));

  router.get('/:id/history', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageHealthEntry(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      const result = await pool.query(
        `SELECT hh.*,
          TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS marked_by_name
         FROM health_history hh
         LEFT JOIN users u ON u.id = hh.marked_by_user_id
         WHERE hh.health_entry_id = $1 AND hh.status IN ('completed', 'skipped')
         ORDER BY hh.changed_at DESC`,
        [req.params.id]
      );
      res.json(result.rows.map(historyToMap));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
