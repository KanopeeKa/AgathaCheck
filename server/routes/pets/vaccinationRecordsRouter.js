import { publicError } from '../../config/security.js';
import { asyncHandler } from '../../lib/http/asyncHandler.js';
import { hasPetCapability, PET_CAPABILITIES } from '../../lib/petCapabilityPolicy.js';
import {
  createPetVaccinationRecord,
  listPetVaccinationRecords,
} from '../../lib/pets/vaccinationRecords.js';
import { extractUserId } from './shared.js';

export function registerVaccinationRecordsRoutes(router, pool) {
  router.get('/:id/vaccination-records', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_VIEW))) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    const pet = await pool.query('SELECT id FROM pets WHERE id = $1', [petId]);
    if (pet.rows.length === 0) return res.status(404).json({ error: 'Pet not found' });
    const payload = await listPetVaccinationRecords(pool, petId);
    res.json(payload);
  }));

  router.post('/:id/vaccination-records', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_EDIT))) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    try {
      const result = await createPetVaccinationRecord(pool, userId, petId, req.body || {});
      if (result === null) return res.status(404).json({ error: 'Pet not found' });
      if (result.error) return res.status(400).json({ error: result.error });
      return res.status(201).json(result.record);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  }));
}
