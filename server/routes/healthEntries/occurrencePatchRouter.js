import { publicError } from '../../config/security.js';
import { updateCompletedDetails } from '../../lib/care/occurrence/index.js';
import { resolveProviderUsedPatch } from '../../lib/care/providerUsed.js';
import { occurrenceToMap } from '../../lib/occurrenceScheduling.js';
import { extractUserId } from './shared.js';
import { loadEntry, loadOccurrence } from './occurrencesRouter.js';

export function registerOccurrencePatchRoutes(router, pool) {
  router.patch('/:id/occurrences/:occId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entryId = req.params.id;
      const entry = await loadEntry(pool, entryId, userId);
      if (!entry) return res.status(404).json({ error: 'Entry not found' });
      const occ = await loadOccurrence(pool, entryId, req.params.occId);
      if (!occ || occ.status !== 'completed') {
        return res.status(404).json({ error: 'Occurrence not found' });
      }
      const body = req.body || {};
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
      const updated = { rows: updatedRow ? [updatedRow] : [] };
      if (updated.rows.length === 0) {
        return res.status(404).json({ error: 'Occurrence not found' });
      }
      const row = updated.rows[0];
      row.marked_by_name = occ.marked_by_name || null;
      res.json(occurrenceToMap(row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
