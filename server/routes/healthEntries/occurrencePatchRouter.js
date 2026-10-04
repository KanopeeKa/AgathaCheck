/**
 * One occurrence: read it for the occurrence screen (§18.7.1) and edit a
 * completed one — notes, provider, and when it was done (D-CSM-034).
 */

import { publicError } from '../../config/security.js';
import { normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import {
  changeCompletionDateCommand,
  normalizeOccurrenceRow,
  openOccurrenceToWire,
  resolveCareAsOfForRead,
  updateCompletedDetails,
} from '../../lib/care/occurrence/index.js';
import { UNDOABLE_EVENT_TYPES } from '../../lib/care/schedule/scheduleEventLedger.js';
import { resolveProviderUsedPatch } from '../../lib/care/providerUsed.js';
import { careItemWire, commandResponse, occurrenceToMap } from '../../lib/care/item/index.js';
import { extractUserId } from './shared.js';
import { handleCommand, loadEntry, loadOccurrence } from './occurrencesRouter.js';

const DETAIL_FIELDS = [
  'notes', 'provider_contact_id', 'providerContactId', 'provider_typed_name', 'providerTypedName',
];

/**
 * Closed rows: done, skipped, or Not recorded. Open rows: the live status.
 */
function occurrenceStatusFor(row, entry, asOf) {
  if (row.status === 'completed') return 'done';
  if (row.status === 'skipped') return row.close_reason === 'not_recorded' ? 'not_recorded' : 'skipped';
  return openOccurrenceToWire(normalizeOccurrenceRow(row), entry, asOf).status;
}

async function lastAction(pool, entryId) {
  const result = await pool.query(
    `SELECT event_type, health_occurrence_id FROM care_schedule_events
     WHERE health_entry_id = $1 AND event_type = ANY($2::text[])
       AND undone_at IS NULL AND payload IS NOT NULL
     ORDER BY occurred_at DESC, created_at DESC
     LIMIT 1`,
    [entryId, UNDOABLE_EVENT_TYPES],
  );
  const row = result.rows[0];
  return row ? { type: row.event_type, occurrence_id: row.health_occurrence_id || null } : null;
}

async function linkedWeight(pool, occurrenceId) {
  const result = await pool.query(
    'SELECT weight, unit FROM weight_entries WHERE health_occurrence_id = $1 LIMIT 1',
    [occurrenceId],
  );
  const row = result.rows[0];
  return row ? { value: Number(row.weight), unit: row.unit || 'kg' } : null;
}

function updateCompletedOn(pool, req, res, completedOn) {
  const occurrenceId = req.params.occId;
  return handleCommand(pool, req, res, {
    command: (ctx) => changeCompletionDateCommand(ctx, { occurrenceId, completedOn }),
    audit: (out) => ({
      action: 'health_occurrence.completed_on_changed',
      metadata: {
        occurrence_id: occurrenceId,
        moved_next_id: out.movedNextId,
        next_unchanged: out.nextUnchanged,
      },
    }),
    respond: async (out) => {
      const occurrence = occurrenceToMap(out.occurrence);
      return {
        body: {
          ...occurrence,
          ...(await commandResponse(pool, out, req, {
            occurrence,
            moved_next_id: out.movedNextId,
            next_unchanged: out.nextUnchanged,
          })),
        },
      };
    },
  });
}

export function registerOccurrencePatchRoutes(router, pool) {
  router.get('/:id/occurrences/:occId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entry = await loadEntry(pool, req.params.id, userId);
      if (!entry) return res.status(404).json({ error: 'Entry not found' });
      const occ = await loadOccurrence(pool, entry.id, req.params.occId);
      if (!occ) return res.status(404).json({ error: 'Occurrence not found', code: 'occurrence_not_found' });
      const asOf = await resolveCareAsOfForRead(pool, entry, req);
      const entryWire = await careItemWire(pool, entry, req, { asOf });
      const body = {
        occurrence: { ...occurrenceToMap(occ), occurrence_status: occurrenceStatusFor(occ, entry, asOf) },
        entry: entryWire,
        last_action: await lastAction(pool, entry.id),
      };
      const weight = await linkedWeight(pool, occ.id);
      if (weight) body.linked_weight = weight;
      return res.json(body);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.patch('/:id/occurrences/:occId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const body = req.body || {};
    const hasCompletedOn =
      Object.prototype.hasOwnProperty.call(body, 'completed_on')
      || Object.prototype.hasOwnProperty.call(body, 'completedOn');
    const rawCompletedOn = body.completed_on ?? body.completedOn;
    if (hasCompletedOn) {
      const completedOn = normalizeCalendarDateInput(rawCompletedOn);
      if (!completedOn) {
        return res.status(400).json({
          error: 'completed_on must be a date (YYYY-MM-DD)', code: 'invalid_completed_on',
        });
      }
      if (DETAIL_FIELDS.some((key) => body[key] !== undefined)) {
        return res.status(400).json({
          error: 'Change completed_on on its own', code: 'completed_on_with_other_fields',
        });
      }
      return updateCompletedOn(pool, req, res, completedOn);
    }

    try {
      const entryId = req.params.id;
      const entry = await loadEntry(pool, entryId, userId);
      if (!entry) return res.status(404).json({ error: 'Entry not found' });
      const occ = await loadOccurrence(pool, entryId, req.params.occId);
      if (!occ || occ.status !== 'completed') {
        return res.status(404).json({ error: 'Occurrence not found' });
      }
      const notes = typeof body.notes === 'string' ? body.notes : occ.notes || '';
      const providerPatch = await resolveProviderUsedPatch(pool, userId, body);
      if (providerPatch?.error) {
        return res.status(400).json({ error: providerPatch.error });
      }
      const updatedRow = await updateCompletedDetails(pool, {
        entryId,
        occurrenceId: req.params.occId,
        notes,
        provider: providerPatch || null,
      });
      if (!updatedRow) {
        return res.status(404).json({ error: 'Occurrence not found' });
      }
      updatedRow.marked_by_name = occ.marked_by_name || null;
      return res.json(occurrenceToMap(updatedRow));
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });
}
