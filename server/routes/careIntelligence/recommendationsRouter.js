import { v4 as uuidv4 } from 'uuid';

import { publicError } from '../../config/security.js';
import { normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import { hasPetCapability, PET_CAPABILITIES } from '../../lib/petCapabilityPolicy.js';
import { accessiblePetSql } from '../../lib/petAccess.js';
import { materialiseInitialOccurrences } from '../../lib/occurrenceScheduling.js';
import { extractUserId } from '../pets/shared.js';
import {
  RESPONSE_ACTIONS,
  recommendationToMap,
} from './shared.js';
import {
  buildAcceptedHealthEntry,
  buildRecommendationInsertValues,
  evaluateCareRecommendationCandidates,
} from './ruleEngine.js';

async function loadPetContext(pool, userId, petId) {
  const petResult = await pool.query(
    `SELECT p.* FROM pets p
     WHERE p.id = $1 AND ${accessiblePetSql('p', '$2')}`,
    [petId, userId],
  );
  if (petResult.rows.length === 0) return null;
  const entriesResult = await pool.query(
    `SELECT he.* FROM health_entries he
     WHERE he.pet_id = $1`,
    [petId],
  );
  const recsResult = await pool.query(
    `SELECT * FROM care_recommendations WHERE pet_id = $1`,
    [petId],
  );
  return {
    pet: petResult.rows[0],
    healthEntries: entriesResult.rows,
    existingRecommendations: recsResult.rows,
  };
}

async function syncPendingRecommendations(pool, petId, candidates) {
  const pending = [];
  for (const candidate of candidates) {
    const existing = await pool.query(
      `SELECT * FROM care_recommendations
       WHERE pet_id = $1 AND care_family = $2 AND suggestion_key = $3`,
      [petId, candidate.care_family, candidate.suggestion_key],
    );
    if (existing.rows.length > 0) {
      const row = existing.rows[0];
      if (row.status === 'pending') pending.push(row);
      continue;
    }
    const id = uuidv4();
    const inserted = await pool.query(
      `INSERT INTO care_recommendations (
         id, pet_id, care_family, suggestion_key, status,
         engine_version, knowledge_version, suggested_name,
         suggested_frequency, suggested_frequency_interval,
         suggested_health_entry_type, rationale_key
       ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
       RETURNING *`,
      buildRecommendationInsertValues(petId, candidate, id),
    );
    pending.push(inserted.rows[0]);
  }
  return pending;
}

async function createRhythmFromRecommendation(pool, recommendation, userId, adjust) {
  const entryId = uuidv4();
  const payload = buildAcceptedHealthEntry({
    petId: recommendation.pet_id,
    userId,
    recommendation,
    adjust,
  });
  const startDate = normalizeCalendarDateInput(payload.startDate);
  const nextDueDate = normalizeCalendarDateInput(payload.nextDueDate);
  const result = await pool.query(
    `INSERT INTO health_entries (
       id, pet_id, user_id, name, type, dosage, frequency, frequency_interval,
       start_date, next_due_date, recurrence_anchor, remind_days_before,
       status, care_family, care_source
     ) VALUES ($1,$2,$3,$4,$5,'',$6,$7,$8,$9,'from_completion',7,'active',$10,$11)
     RETURNING *`,
    [
      entryId,
      payload.petId,
      payload.userId,
      payload.name,
      payload.type,
      payload.frequency,
      payload.frequencyInterval,
      startDate,
      nextDueDate,
      payload.careFamily,
      payload.careSource,
    ],
  );
  const entry = result.rows[0];
  await materialiseInitialOccurrences(pool, entry);
  return entryId;
}

export function registerCareIntelligenceRoutes(router, pool) {
  router.get('/:id/care-recommendations', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    try {
      if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_VIEW))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const context = await loadPetContext(pool, userId, petId);
      if (!context) return res.status(404).json({ error: 'Pet not found' });

      const candidates = evaluateCareRecommendationCandidates({
        pet: context.pet,
        healthEntries: context.healthEntries,
        existingRecommendations: context.existingRecommendations,
      });
      const pending = await syncPendingRecommendations(pool, petId, candidates);
      res.json(pending.map(recommendationToMap));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/care-recommendations/:recommendationId/respond', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id: petId, recommendationId } = req.params;
    const action = (req.body?.action || '').trim();
    if (!RESPONSE_ACTIONS.has(action)) {
      return res.status(400).json({ error: 'Invalid action' });
    }
    try {
      if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_EDIT))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const recResult = await pool.query(
        `SELECT * FROM care_recommendations WHERE id = $1 AND pet_id = $2`,
        [recommendationId, petId],
      );
      if (recResult.rows.length === 0) {
        return res.status(404).json({ error: 'Recommendation not found' });
      }
      const recommendation = recResult.rows[0];

      if (action === 'accept' || action === 'adjust') {
        if (recommendation.health_entry_id) {
          return res.json(recommendationToMap(recommendation));
        }
        const healthEntryId = await createRhythmFromRecommendation(
          pool,
          recommendation,
          userId,
          action === 'adjust' ? req.body?.adjust : null,
        );
        const status = action === 'adjust' ? 'adjusted' : 'accepted';
        const updated = await pool.query(
          `UPDATE care_recommendations
           SET status = $1, health_entry_id = $2, responded_at = NOW(), updated_at = NOW()
           WHERE id = $3
           RETURNING *`,
          [status, healthEntryId, recommendationId],
        );
        return res.json(recommendationToMap(updated.rows[0]));
      }

      const status = action === 'not_relevant' ? 'not_relevant' : 'dismissed';
      const updated = await pool.query(
        `UPDATE care_recommendations
         SET status = $1, responded_at = NOW(), updated_at = NOW()
         WHERE id = $2
         RETURNING *`,
        [status, recommendationId],
      );
      return res.json(recommendationToMap(updated.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
