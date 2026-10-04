import { publicError } from '../../config/security.js';
import { hasPetCapability, PET_CAPABILITIES } from '../../lib/petCapabilityPolicy.js';
import { userCanManageHealthEntry } from '../../lib/petAccess.js';
import { completeWeightOccurrence as completeWeightOccurrenceService } from '../../lib/care/observations/weightObservationService.js';
import { extractUserId } from '../pets/shared.js';
import { loadOccurrence } from './occurrencesRouter.js';

async function loadEntryForPet(pool, entryId, petId, userId) {
  if (!(await userCanManageHealthEntry(pool, entryId, userId))) {
    return null;
  }
  const result = await pool.query(
    `SELECT he.* FROM health_entries he
     WHERE he.id = $1 AND he.pet_id = $2`,
    [entryId, petId],
  );
  return result.rows[0] || null;
}

/**
 * POST /api/pets/:petId/care-rhythms/:entryId/occurrences/:occurrenceId/complete-weight
 */
export function registerCompleteWeightRoutes(router, pool) {
  router.post(
    '/:id/care-rhythms/:entryId/occurrences/:occurrenceId/complete-weight',
    async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      try {
        const result = await completeWeightOccurrenceService(pool, {
          petId: req.params.id,
          entryId: req.params.entryId,
          occurrenceId: req.params.occurrenceId,
          userId,
          body: req.body || {},
          req,
          loadOccurrence,
          loadEntryForPet,
          hasPetWeightEdit: (db, uid, pid) =>
            hasPetCapability(db, uid, pid, PET_CAPABILITIES.WEIGHT_EDIT),
        });
        return res.status(result.status).json(result.body);
      } catch (err) {
        return res.status(500).json({ error: publicError(err) });
      }
    },
  );
}

/** @deprecated Import from weightObservationService — kept for tests that import this symbol. */
export async function completeWeightOccurrence(pool, params) {
  return completeWeightOccurrenceService(pool, {
    ...params,
    loadOccurrence: params.loadOccurrence || loadOccurrence,
    loadEntryForPet: params.loadEntryForPet || loadEntryForPet,
    hasPetWeightEdit: params.hasPetWeightEdit
      || ((db, uid, pid) => hasPetCapability(db, uid, pid, PET_CAPABILITIES.WEIGHT_EDIT)),
  });
}
