import express from 'express';

import { publicError } from '../../config/security.js';
import { extractUserId } from '../../lib/requireAuth.js';
import {
  accessiblePetSql,
} from '../../lib/petAccess.js';
import { hasPetCapability, PET_CAPABILITIES } from '../../lib/petCapabilityPolicy.js';
import {
  findLatestWeightEntry,
  listWeightEntries,
} from '../../lib/care/observations/weightObservationRepository.js';
import { weightEntryToMap } from './wire.js';

export function createWeightEntriesReadRouter(pool) {
  const router = express.Router();

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const petId = req.query.pet_id || req.query.petId;
      if (petId) {
        if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.WEIGHT_VIEW))) {
          return res.status(403).json({ error: 'Forbidden' });
        }
      }
      const result = await listWeightEntries(
        pool,
        accessiblePetSql('p', petId ? '$2' : '$1'),
        userId,
        petId || null,
      );
      res.json(result.rows.map(weightEntryToMap));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/latest', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const petId = req.query.pet_id || req.query.petId;
      if (!petId) {
        return res.status(400).json({ error: 'pet_id is required' });
      }
      if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.WEIGHT_VIEW))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const row = await findLatestWeightEntry(
        pool,
        accessiblePetSql('p', '$2'),
        petId,
        userId,
      );
      if (!row) return res.status(404).json({ error: 'No weight entries found' });
      res.json(weightEntryToMap(row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
