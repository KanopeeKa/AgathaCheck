import { v4 as uuidv4 } from 'uuid';

import { publicError } from '../../config/security.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import { recordPetActivityForPet } from '../../lib/petActivity.js';
import { hasPetCapability, PET_CAPABILITIES } from '../../lib/petCapabilityPolicy.js';
import { accessiblePetSql, userCanManageHealthEntry } from '../../lib/petAccess.js';
import { refreshPetWeightCache } from '../../lib/petWeightSync.js';
import {
  materialiseAfterOccurrenceClose,
  occurrenceToMap,
  resolveCompletedOn,
} from '../../lib/occurrenceScheduling.js';
import { dateToIsoDate } from '../../lib/calendarDate.js';
import { extractUserId } from '../pets/shared.js';
import { loadOccurrence } from './occurrencesRouter.js';
import { maybePersistWeightEstablishment } from '../../lib/care/progression/weightEstablishmentService.js';
import {
  isWeightMonitoringEntry,
  newWeightEntryId,
  parseWeightObservationBody,
  weightEntryToCompletionMap,
  weightPayloadsSemanticallyEqual,
} from './weightOccurrenceCompletion.js';

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

async function findLinkedWeight(pool, occurrenceId) {
  const result = await pool.query(
    `SELECT * FROM weight_entries WHERE health_occurrence_id = $1 LIMIT 1`,
    [occurrenceId],
  );
  return result.rows[0] || null;
}

function buildCompletionResponse(weightRow, occurrenceRow, nextDueDate) {
  return {
    weight_entry: weightEntryToCompletionMap(weightRow),
    occurrence: occurrenceToMap(occurrenceRow),
    next_due_date: dateToIsoDate(nextDueDate),
  };
}

/**
 * Transactional weight observation + occurrence completion (CP-2).
 */
export async function completeWeightOccurrence(pool, {
  petId,
  entryId,
  occurrenceId,
  userId,
  body,
  req,
}) {
  if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.WEIGHT_EDIT))) {
    return { status: 403, body: { error: 'Forbidden' } };
  }

  const petResult = await pool.query(
    `SELECT p.id FROM pets p
     WHERE p.id = $1 AND ${accessiblePetSql('p', '$2')}`,
    [petId, userId],
  );
  if (petResult.rows.length === 0) {
    return { status: 404, body: { error: 'Pet not found' } };
  }

  const entry = await loadEntryForPet(pool, entryId, petId, userId);
  if (!entry) {
    return { status: 404, body: { error: 'Entry not found' } };
  }
  if (!isWeightMonitoringEntry(entry)) {
    return { status: 400, body: { error: 'Entry is not a weight monitoring rhythm' } };
  }

  const parsed = parseWeightObservationBody(body);
  if (parsed.error) {
    return { status: 400, body: { error: parsed.error } };
  }
  const payload = parsed.value;

  const occ = await loadOccurrence(pool, entryId, occurrenceId);
  if (!occ) {
    return { status: 404, body: { error: 'Occurrence not found' } };
  }

  const existingWeight = await findLinkedWeight(pool, occurrenceId);
  if (existingWeight) {
    if (weightPayloadsSemanticallyEqual(existingWeight, payload)) {
      const refreshedEntry = await pool.query(
        'SELECT next_due_date FROM health_entries WHERE id = $1',
        [entryId],
      );
      await maybePersistWeightEstablishment(pool, { petId, healthEntryId: entryId });
      return {
        status: 200,
        body: buildCompletionResponse(
          existingWeight,
          occ,
          refreshedEntry.rows[0]?.next_due_date,
        ),
      };
    }
    return {
      status: 409,
      body: { error: 'Occurrence already linked to a different weight observation' },
    };
  }

  if (occ.status !== 'pending') {
    return { status: 404, body: { error: 'Occurrence not found' } };
  }

  const completedOn = resolveCompletedOn(body.completed_on || body.completedOn || payload.date);
  const markedAt = new Date();
  const weightId = newWeightEntryId();
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const weightResult = await client.query(
      `INSERT INTO weight_entries
        (id, pet_id, user_id, weight, unit, date, notes, measurement_source, health_occurrence_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [
        weightId,
        petId,
        userId,
        payload.weight,
        payload.unit,
        payload.date,
        payload.notes,
        payload.measurement_source,
        occurrenceId,
      ],
    );

    const occResult = await client.query(
      `UPDATE health_occurrences SET status = 'completed', completed_on = $1,
        marked_at = $2, marked_by_user_id = $3, notes = $4, updated_at = NOW()
       WHERE id = $5 AND health_entry_id = $6 AND status = 'pending'
       RETURNING *`,
      [completedOn, markedAt, userId, payload.notes, occurrenceId, entryId],
    );
    if (occResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return { status: 404, body: { error: 'Occurrence not found' } };
    }

    await materialiseAfterOccurrenceClose(client, entry);

    await client.query('COMMIT');

    await refreshPetWeightCache(pool, petId);

    const refreshedEntry = await pool.query(
      'SELECT next_due_date FROM health_entries WHERE id = $1',
      [entryId],
    );

    logAuditEventSafe(pool, {
      actorUserId: userId,
      action: 'weight_occurrence.completed',
      resourceType: 'health_entry',
      resourceId: entryId,
      petId,
      metadata: {
        occurrence_id: occurrenceId,
        weight_entry_id: weightId,
      },
      req,
    });
    recordPetActivityForPet(pool, {
      petId,
      actorUserId: userId,
      eventType: 'health_log',
      metadata: { action: 'complete_weight_occurrence', entry_type: entry.type },
    });

    await maybePersistWeightEstablishment(pool, { petId, healthEntryId: entryId });

    return {
      status: 201,
      body: buildCompletionResponse(
        weightResult.rows[0],
        occResult.rows[0],
        refreshedEntry.rows[0]?.next_due_date,
      ),
    };
  } catch (err) {
    await client.query('ROLLBACK');
    if (err.code === '23505') {
      const linked = await findLinkedWeight(pool, occurrenceId);
      if (linked && weightPayloadsSemanticallyEqual(linked, payload)) {
        const refreshedEntry = await pool.query(
          'SELECT next_due_date FROM health_entries WHERE id = $1',
          [entryId],
        );
        await maybePersistWeightEstablishment(pool, { petId, healthEntryId: entryId });
        return {
          status: 200,
          body: buildCompletionResponse(
            linked,
            occ,
            refreshedEntry.rows[0]?.next_due_date,
          ),
        };
      }
      return {
        status: 409,
        body: { error: 'Occurrence already linked to a different weight observation' },
      };
    }
    throw err;
  } finally {
    client.release();
  }
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
        const result = await completeWeightOccurrence(pool, {
          petId: req.params.id,
          entryId: req.params.entryId,
          occurrenceId: req.params.occurrenceId,
          userId,
          body: req.body || {},
          req,
        });
        return res.status(result.status).json(result.body);
      } catch (err) {
        return res.status(500).json({ error: publicError(err) });
      }
    },
  );
}
