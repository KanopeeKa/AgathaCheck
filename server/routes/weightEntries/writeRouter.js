import { asyncHandler } from '../../lib/http/asyncHandler.js';
import express from 'express';
import { v4 as uuidv4 } from 'uuid';

import { logAuditEventSafe } from '../../lib/audit.js';
import { extractUserId } from '../../lib/requireAuth.js';
import { normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import { userCanManageHealthEntry, userCanManageWeightEntry } from '../../lib/petAccess.js';
import { hasPetCapability, PET_CAPABILITIES } from '../../lib/petCapabilityPolicy.js';
import {
  recordWeight,
  updateWeight,
  deleteWeight,
  WeightValidationError,
} from '../../lib/care/observations/weightObservationService.js';
import {
  FulfilmentError,
  fulfilExistingWeight,
  recordWeightWithFulfilment,
} from '../../lib/care/observations/weightFulfilmentService.js';
import { validateMeasurementSource } from '../careIntelligence/provenance.js';
import { fulfilmentToMap, weightEntryToMap } from './wire.js';

export function createWeightEntriesWriteRouter(pool) {
  const router = express.Router();

  router.post('/', asyncHandler(async (req, res) => {
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
      const fulfilsOccurrenceId = data.fulfils_occurrence_id || data.fulfilsOccurrenceId || null;
      if (fulfilsOccurrenceId) {
        const occLink = await pool.query(
          'SELECT health_entry_id FROM health_occurrences WHERE id = $1',
          [fulfilsOccurrenceId],
        );
        const careEntryId = occLink.rows[0]?.health_entry_id;
        if (!careEntryId || !(await userCanManageHealthEntry(pool, careEntryId, userId))) {
          return res.status(403).json({ error: 'Forbidden' });
        }
        const outcome = await recordWeightWithFulfilment(pool, {
          petId,
          userId,
          occurrenceId: fulfilsOccurrenceId,
          weight: data.weight,
          unit: data.unit,
          date: dateInput,
          notes: data.notes || '',
          measurementSource: sourceResult.value,
          entryId: data.id || uuidv4(),
          req,
        });
        const row = outcome.weightRow;
        logAuditEventSafe(pool, {
          actorUserId: userId,
          action: 'weight_entry.created',
          resourceType: 'weight_entry',
          resourceId: row.id,
          petId,
          metadata: { weight: row.weight, unit: 'kg', fulfils_occurrence_id: fulfilsOccurrenceId },
          req,
        });
        return res.status(201).json({
          ...weightEntryToMap(row),
          fulfilment: fulfilmentToMap(outcome.fulfilment),
        });
      }
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
      if (err instanceof FulfilmentError) {
        return res.status(err.status).json(err.body);
      }
      if (err instanceof WeightValidationError) {
        return res.status(err.status).json(err.body);
      }
      throw err;
    }
  }));

  router.post('/:id/fulfil', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageWeightEntry(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Not found' });
      }
      const occurrenceId = req.body.occurrence_id || req.body.occurrenceId;
      if (!occurrenceId) {
        return res.status(400).json({ error: 'occurrence_id is required' });
      }
      const occLink = await pool.query(
        'SELECT health_entry_id FROM health_occurrences WHERE id = $1',
        [occurrenceId],
      );
      const careEntryId = occLink.rows[0]?.health_entry_id;
      if (!careEntryId || !(await userCanManageHealthEntry(pool, careEntryId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const outcome = await fulfilExistingWeight(pool, {
        weightEntryId: req.params.id,
        userId,
        occurrenceId,
        req,
      });
      if (!outcome) {
        return res.status(404).json({ error: 'Not found' });
      }
      res.json({
        ...weightEntryToMap(outcome.weightRow),
        fulfilment: fulfilmentToMap(outcome.fulfilment),
      });
    } catch (err) {
      if (err instanceof FulfilmentError) {
        return res.status(err.status).json(err.body);
      }
      if (err instanceof WeightValidationError) {
        return res.status(err.status).json(err.body);
      }
      throw err;
    }
  }));

  router.put('/:id', asyncHandler(async (req, res) => {
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
      const outcome = await updateWeight(pool, {
        entryId: req.params.id,
        userId,
        weight: data.weight,
        unit: data.unit,
        date: dateInput,
        notes: data.notes || '',
        measurementSource: sourceResult.value,
        req,
      });
      if (!outcome?.row) return res.status(404).json({ error: 'Not found' });
      const row = outcome.row;
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'weight_entry.updated',
        resourceType: 'weight_entry',
        resourceId: req.params.id,
        petId: row.pet_id,
        metadata: { weight: row.weight, unit: 'kg' },
        req,
      });
      res.json({
        ...weightEntryToMap(row),
        ...(outcome.undoToken ? { undo_token: outcome.undoToken } : {}),
      });
    } catch (err) {
      if (err instanceof WeightValidationError) {
        return res.status(err.status).json(err.body);
      }
      throw err;
    }
  }));

  router.delete('/:id', asyncHandler(async (req, res) => {
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
          reopened_occurrence: outcome.reopenedOccurrence || null,
        },
        req,
      });
      res.json({
        deleted: true,
        reopened_occurrence: outcome.reopenedOccurrence || null,
      });
    } catch (err) {
      throw err;
    }
  }));

  return router;
}
