import { asyncHandler } from '../../lib/http/asyncHandler.js';
import express from 'express';

import { extractUserId } from '../../lib/requireAuth.js';
import { normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import {
  accessiblePetSql,
  userCanManageCare,
} from '../../lib/petAccess.js';
import { hasPetCapability, PET_CAPABILITIES } from '../../lib/petCapabilityPolicy.js';
import { loadPetHomeTimezone } from '../../lib/petHomeTimezone.js';
import {
  careAsOfForZone,
  careClockFromRequest,
} from '../../lib/care/occurrence/careAsOf.js';
import {
  findLatestWeightEntry,
  listWeightEntries,
} from '../../lib/care/observations/weightObservationRepository.js';
import {
  findFulfilmentCandidates,
  loadWeightOverview,
} from '../../lib/care/observations/weightFulfilmentService.js';
import { weightEntryToMap } from './wire.js';

export function createWeightEntriesReadRouter(pool) {
  const router = express.Router();

  router.get('/', asyncHandler(async (req, res) => {
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
      throw err;
    }
  }));

  router.get('/fulfilment-candidates', asyncHandler(async (req, res) => {
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
      const timeZone = await loadPetHomeTimezone(pool, petId);
      const asOf = careAsOfForZone(timeZone, careClockFromRequest(req));
      const rawDate = req.query.date;
      const dateInput = rawDate ? normalizeCalendarDateInput(rawDate) : null;
      if (rawDate && !dateInput) {
        return res.status(400).json({ error: 'invalid date' });
      }
      const dateIso = dateInput || asOf.todayIso;
      if (dateIso > asOf.todayIso) {
        return res.status(400).json({ error: 'invalid date' });
      }
      if (!(await userCanManageCare(pool, petId, userId))) {
        return res.json({
          date: dateIso,
          candidates: [],
          default_occurrence_id: null,
        });
      }
      const payload = await findFulfilmentCandidates(pool, { petId, dateIso, asOf });
      res.json(payload);
    } catch (err) {
      throw err;
    }
  }));

  router.get('/overview', asyncHandler(async (req, res) => {
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
      const payload = await loadWeightOverview(pool, petId, req);
      res.json(payload);
    } catch (err) {
      throw err;
    }
  }));

  router.get('/latest', asyncHandler(async (req, res) => {
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
      throw err;
    }
  }));

  return router;
}
