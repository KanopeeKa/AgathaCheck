import { v4 as uuidv4 } from 'uuid';

import { logAuditEventSafe } from '../../audit.js';
import { accessiblePetSql } from '../../petAccess.js';
import { recordPetActivityForPet } from '../../petActivity.js';
import { normalizeCalendarDateInput } from '../../calendarDate.js';
import { withTransaction } from '../../db/withTransaction.js';
import {
  getLatestWeightEntry,
  refreshPetWeightCache,
  weightsDiffer,
} from '../../petWeightSync.js';
import { loadPetHomeTimezone } from '../../petHomeTimezone.js';
import {
  careAsOfForZone,
  careClockFromRequest,
} from '../occurrence/careAsOf.js';
import {
  CareCommandError,
  completeOccurrenceCommand,
  runCareCommand,
  undoCompletionOfOccurrence,
} from '../occurrence/index.js';
import {
  occurrenceToMap,
  resolveCompletedOn,
} from '../item/index.js';
import { dateToIsoDate } from '../../calendarDate.js';
import { maybePersistWeightEstablishment } from '../progression/weightEstablishmentService.js';
import { parseWeightInput } from './weightUnits.js';
import {
  deleteWeightEntryById,
  findWeightEntryById,
  findWeightEntryByOccurrenceId,
  insertWeightEntry,
  updateWeightEntry,
} from './weightObservationRepository.js';
import {
  isWeightMonitoringEntry,
  parseWeightObservationBody,
  weightEntryToCompletionMap,
  weightPayloadsSemanticallyEqual,
} from '../../../routes/healthEntries/weightOccurrenceCompletion.js';

export class WeightValidationError extends Error {
  /**
   * @param {string} message
   * @param {{ code?: string, status?: number }} [opts]
   */
  constructor(message, opts = {}) {
    super(message);
    this.name = 'WeightValidationError';
    this.status = opts.status ?? 400;
    this.code = opts.code;
    this.body = this.code
      ? { error: message, code: this.code }
      : { error: message };
  }
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {string} petId
 * @param {unknown} dateInput
 * @param {import('express').Request|null|undefined} req
 */
export async function resolveWeightDateForPet(db, petId, dateInput, req) {
  const timeZone = await loadPetHomeTimezone(db, petId);
  const asOf = careAsOfForZone(timeZone, careClockFromRequest(req));
  const dateVal = normalizeCalendarDateInput(dateInput) || asOf.todayIso;
  if (dateVal > asOf.todayIso) {
    throw new WeightValidationError('date cannot be in the future', { code: 'date_in_future' });
  }
  return dateVal;
}

/**
 * @param {import('pg').Pool} pool
 * @param {{
 *   petId: string,
 *   userId: string,
 *   weight: unknown,
 *   unit?: unknown,
 *   date?: unknown,
 *   notes?: string,
 *   measurementSource: string,
 *   entryId?: string,
 *   req?: import('express').Request,
 * }} params
 */
export async function recordWeight(pool, params) {
  const parsed = parseWeightInput({ weight: params.weight, unit: params.unit });
  if (parsed.error) {
    throw new WeightValidationError(parsed.error);
  }
  const dateVal = await resolveWeightDateForPet(
    pool,
    params.petId,
    params.date,
    params.req,
  );
  const id = params.entryId || uuidv4();

  const result = await withTransaction(pool, async (db) => {
    const row = await insertWeightEntry(db, {
      id,
      petId: params.petId,
      userId: params.userId,
      weightKg: parsed.kg,
      date: dateVal,
      notes: params.notes,
      measurementSource: params.measurementSource,
    });
    await refreshPetWeightCache(db, params.petId);
    return row;
  });
  return result;
}

/**
 * @param {import('pg').Pool} pool
 * @param {{
 *   entryId: string,
 *   userId: string,
 *   weight: unknown,
 *   unit?: unknown,
 *   date?: unknown,
 *   notes?: string,
 *   measurementSource: string,
 *   req?: import('express').Request,
 * }} params
 */
export async function updateWeight(pool, params) {
  const existing = await findWeightEntryById(pool, params.entryId);
  if (!existing) {
    return null;
  }
  const parsed = parseWeightInput({ weight: params.weight, unit: params.unit });
  if (parsed.error) {
    throw new WeightValidationError(parsed.error);
  }
  const dateVal = await resolveWeightDateForPet(
    pool,
    existing.pet_id,
    params.date,
    params.req,
  );

  const result = await withTransaction(pool, async (db) => {
    const row = await updateWeightEntry(db, {
      id: params.entryId,
      weightKg: parsed.kg,
      date: dateVal,
      notes: params.notes ?? '',
      measurementSource: params.measurementSource,
    });
    if (!row) return null;
    await refreshPetWeightCache(db, row.pet_id);
    return row;
  });
  return result;
}

/**
 * @param {import('pg').Pool} pool
 * @param {{ entryId: string, userId: string, req?: import('express').Request }} params
 */
export async function deleteWeight(pool, params) {
  const existing = await findWeightEntryById(pool, params.entryId);
  if (!existing) {
    return { found: false };
  }
  const deleteWeightFn = (db) => deleteWeightEntryById(db, params.entryId);
  const linked = existing.health_occurrence_id
    ? await pool.query(
      'SELECT health_entry_id FROM health_occurrences WHERE id = $1',
      [existing.health_occurrence_id],
    )
    : { rows: [] };
  const careEntryId = linked.rows[0]?.health_entry_id;
  if (careEntryId) {
    await runCareCommand(pool, {
      entryId: careEntryId,
      userId: params.userId,
      req: params.req,
      beforeCommand: deleteWeightFn,
    }, (ctx) => undoCompletionOfOccurrence(ctx, {
      occurrenceId: existing.health_occurrence_id,
    }));
  } else {
    await deleteWeightFn(pool);
  }
  if (existing.pet_id) {
    await refreshPetWeightCache(pool, existing.pet_id);
  }
  return {
    found: true,
    petId: existing.pet_id,
    reopenedOccurrenceId: existing.health_occurrence_id || null,
  };
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {{
 *   petId: string,
 *   userId: string,
 *   weight: unknown,
 *   date?: string,
 *   req?: import('express').Request,
 * }} params
 */
export async function recordWeightFromPetPayload(db, params) {
  if (params.weight == null || params.weight === '') {
    return { ok: true, skipped: true };
  }
  const parsed = parseWeightInput({ weight: params.weight, unit: 'kg' });
  if (parsed.error) {
    return {
      ok: false,
      status: 400,
      body: { error: 'weight must be a positive number', code: 'invalid_weight' },
    };
  }

  let dateVal;
  try {
    dateVal = await resolveWeightDateForPet(db, params.petId, params.date, params.req);
  } catch (err) {
    if (err instanceof WeightValidationError) {
      return { ok: false, status: err.status, body: err.body };
    }
    throw err;
  }

  const latest = await getLatestWeightEntry(db, params.petId);
  if (!weightsDiffer(parsed.kg, latest?.weight)) {
    return { ok: true, skipped: true };
  }

  await insertWeightEntry(db, {
    id: uuidv4(),
    petId: params.petId,
    userId: params.userId,
    weightKg: parsed.kg,
    date: dateVal,
    notes: '',
    measurementSource: 'guardian',
  });
  await refreshPetWeightCache(db, params.petId);
  return { ok: true, recorded: true };
}

function buildCompletionResponse(weightRow, occurrenceRow, nextDueDate) {
  return {
    weight_entry: weightEntryToCompletionMap(weightRow),
    occurrence: occurrenceToMap(occurrenceRow),
    next_due_date: dateToIsoDate(nextDueDate),
  };
}

function runPostCommitWeightCompletionSideEffects(pool, {
  petId,
  entryId,
  entry,
  occurrenceId,
  weightId,
  userId,
  req,
}) {
  void Promise.resolve()
    .then(() => {
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
      return recordPetActivityForPet(pool, {
        petId,
        actorUserId: userId,
        eventType: 'health_log',
        metadata: { action: 'complete_weight_occurrence', entry_type: entry.type },
      });
    })
    .catch((err) => {
      console.warn('weight completion post-commit side effect failed', {
        action: 'complete_weight_occurrence',
        petId,
        entryId,
        occurrenceId,
        weightId,
        userId,
      }, err);
    });
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
  loadOccurrence,
  loadEntryForPet,
  hasPetWeightEdit,
}) {
  if (!(await hasPetWeightEdit(pool, userId, petId))) {
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
  let payload = parsed.value;

  try {
    const dateVal = await resolveWeightDateForPet(pool, petId, payload.date, req);
    payload = { ...payload, date: dateVal };
  } catch (err) {
    if (err instanceof WeightValidationError) {
      return { status: err.status, body: err.body };
    }
    throw err;
  }

  const occ = await loadOccurrence(pool, entryId, occurrenceId);
  if (!occ) {
    return { status: 404, body: { error: 'Occurrence not found' } };
  }

  const existingWeight = await findWeightEntryByOccurrenceId(pool, occurrenceId);
  if (existingWeight) {
    if (weightPayloadsSemanticallyEqual(existingWeight, payload)) {
      const refreshedEntry = await pool.query(
        'SELECT next_due_date FROM health_entries WHERE id = $1',
        [entryId],
      );
      runPostCommitWeightCompletionSideEffects(pool, {
        petId,
        entryId,
        entry,
        occurrenceId,
        weightId: existingWeight.id,
        userId,
        req,
      });
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
  const weightId = uuidv4();
  let committedResponse;

  try {
    let weightRow = null;
    const out = await runCareCommand(pool, {
      entryId,
      userId,
      req,
      beforeCommand: async (db) => {
        weightRow = await insertWeightEntry(db, {
          id: weightId,
          petId,
          userId,
          weightKg: payload.weight,
          date: payload.date,
          notes: payload.notes,
          measurementSource: payload.measurement_source,
          healthOccurrenceId: occurrenceId,
        });
        await refreshPetWeightCache(db, petId);
        await maybePersistWeightEstablishment(db, { petId, healthEntryId: entryId });
      },
    }, (ctx) => completeOccurrenceCommand(ctx, {
      occurrenceId,
      completedOn,
      notes: payload.notes || '',
      nextChoice: body.next_choice || body.nextChoice || null,
      rememberChoice: Boolean(body.remember_choice ?? body.rememberChoice),
      earlierChoice: body.earlier_choice || body.earlierChoice || null,
      body,
    }));
    if (!out) {
      return { status: 404, body: { error: 'Occurrence not found' } };
    }
    committedResponse = {
      status: 201,
      body: {
        ...buildCompletionResponse(weightRow, out.occurrence, out.entry.next_due_date),
        next_choice_applied: out.appliedChoice ?? null,
        undo_token: out.undoToken,
      },
    };
  } catch (err) {
    if (err instanceof CareCommandError) {
      return { status: err.status, body: err.toBody() };
    }
    if (err.code === '23505') {
      const linked = await findWeightEntryByOccurrenceId(pool, occurrenceId);
      if (linked && weightPayloadsSemanticallyEqual(linked, payload)) {
        const refreshedEntry = await pool.query(
          'SELECT next_due_date FROM health_entries WHERE id = $1',
          [entryId],
        );
        const idempotentResponse = {
          status: 200,
          body: buildCompletionResponse(
            linked,
            occ,
            refreshedEntry.rows[0]?.next_due_date,
          ),
        };
        runPostCommitWeightCompletionSideEffects(pool, {
          petId,
          entryId,
          entry,
          occurrenceId,
          weightId: linked.id,
          userId,
          req,
        });
        return idempotentResponse;
      }
      return {
        status: 409,
        body: { error: 'Occurrence already linked to a different weight observation' },
      };
    }
    throw err;
  }

  runPostCommitWeightCompletionSideEffects(pool, {
    petId,
    entryId,
    entry,
    occurrenceId,
    weightId,
    userId,
    req,
  });

  return committedResponse;
}
