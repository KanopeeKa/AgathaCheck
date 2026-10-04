import express from 'express';
import { v4 as uuidv4 } from 'uuid';

import { publicError } from '../../config/security.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import { extractUserId } from '../../lib/requireAuth.js';
import { normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import { userCanManageWeightEntry } from '../../lib/petAccess.js';
import { hasPetCapability, PET_CAPABILITIES } from '../../lib/petCapabilityPolicy.js';
import {
  recordWeight,
  updateWeight,
  deleteWeight,
  WeightValidationError,
} from '../../lib/care/observations/weightObservationService.js';
import { validateMeasurementSource } from '../careIntelligence/provenance.js';
import { weightEntryToMap } from './wire.js';

export function createWeightEntriesWriteRouter(pool) {
  const router = express.Router();

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const data = req.body;
      const petId = data.pet_id || data.petId;
      if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.WEIGHT_EDIT))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const sourceInput = data.measurement_source ?? data.measurementSource;
      const sourceResult = validateMeasurementSource(sourceInput);
      if (!sourceResult.ok) {
        return res.status(400).json({ error: sourceResult.error });
      }
      const dateInput = normalizeCalendarDateInput(data.date || data.measured_at);
      const row = await recordWeight(pool, {
        petId,
        userId,
        weight: data.weight,
        unit: data.unit,
        date: dateInput,
        notes: data.notes || '',
        measurementSource: sourceResult.value,
        entryId: data.id || uuidv4(),
        req,
      });
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'weight_entry.created',
        resourceType: 'weight_entry',
        resourceId: row.id,
        petId,
        metadata: { weight: row.weight, unit: 'kg' },
        req,
      });
      res.status(201).json(weightEntryToMap(row));
    } catch (err) {
      if (err instanceof WeightValidationError) {
        return res.status(err.status).json(err.body);
      }
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageWeightEntry(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Not found' });
      }
      const data = req.body;
      const sourceInput = data.measurement_source ?? data.measurementSource;
      const sourceResult = validateMeasurementSource(sourceInput);
      if (!sourceResult.ok) {
        return res.status(400).json({ error: sourceResult.error });
      }
      const dateInput = normalizeCalendarDateInput(data.date || data.measured_at);
      const row = await updateWeight(pool, {
        entryId: req.params.id,
        userId,
        weight: data.weight,
        unit: data.unit,
        date: dateInput,
        notes: data.notes || '',
        measurementSource: sourceResult.value,
        req,
      });
      if (!row) return res.status(404).json({ error: 'Not found' });
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'weight_entry.updated',
        resourceType: 'weight_entry',
        resourceId: req.params.id,
        petId: row.pet_id,
        metadata: { weight: row.weight, unit: 'kg' },
        req,
      });
      res.json(weightEntryToMap(row));
    } catch (err) {
      if (err instanceof WeightValidationError) {
        return res.status(err.status).json(err.body);
      }
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageWeightEntry(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Not found' });
      }
      const outcome = await deleteWeight(pool, {
        entryId: req.params.id,
        userId,
        req,
      });
      if (!outcome.found) {
        return res.status(404).json({ error: 'Not found' });
      }
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'weight_entry.deleted',
        resourceType: 'weight_entry',
        resourceId: req.params.id,
        petId: outcome.petId || null,
        metadata: {
          reopened_occurrence_id: outcome.reopenedOccurrenceId || null,
        },
        req,
      });
      res.json({ deleted: true });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
