import { v4 as uuidv4 } from 'uuid';

import { dateToIsoDate } from '../../calendarDate.js';
import { loadPetHomeTimezone } from '../../petHomeTimezone.js';
import {
  careAsOfForZone,
  careClockFromRequest,
} from '../occurrence/careAsOf.js';
import {
  CareCommandError,
  completeOccurrenceCommand,
  runCareCommand,
} from '../occurrence/index.js';
import { occurrenceToMap } from '../item/index.js';
import { occurrenceStatus } from '../schedule/occurrenceStatus.js';
import { refreshPetWeightCache } from '../../petWeightSync.js';
import { maybePersistWeightEstablishment } from '../progression/weightEstablishmentService.js';
import { normalizeCalendarDateInput } from '../../calendarDate.js';
import {
  findWeightEntryById,
  insertWeightEntry,
  linkWeightToOccurrence,
  loadFulfilmentContext,
  loadWeightOverviewContext,
} from './weightObservationRepository.js';
import { isFulfilmentEligible } from './weightFulfilment.js';
import { parseWeightInput } from './weightUnits.js';
import { WeightValidationError } from './weightObservationService.js';

export class FulfilmentError extends Error {
  /**
   * @param {'fulfilment_not_eligible'|'already_linked'|'occurrence_not_open'} code
   */
  constructor(code) {
    super(code);
    this.name = 'FulfilmentError';
    this.status = 409;
    this.body = { code };
  }
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {{ petId: string, dateIso: string, asOf: object }} params
 */
export async function findFulfilmentCandidates(db, { petId, dateIso, asOf }) {
  const ctx = await loadFulfilmentContext(db, petId);
  const candidates = [];
  for (const item of ctx.items) {
    const latestCompletedOn = ctx.latestCompletedOnByEntry.get(item.id) ?? null;
    const pending = ctx.pendingByEntry.get(item.id) || [];
    for (const occ of pending) {
      if (isFulfilmentEligible({
        entry: item,
        occurrence: occ,
        dateIso,
        todayIso: asOf.todayIso,
        latestCompletedOn,
      })) {
        candidates.push({
          entry_id: item.id,
          entry_name: item.name,
          occurrence_id: occ.id,
          scheduled_date: dateToIsoDate(occ.scheduled_date),
          status: occurrenceStatus({ occurrence: occ, entry: item, asOf }),
        });
        break;
      }
    }
  }
  return {
    date: dateIso,
    candidates,
    default_occurrence_id: candidates.length === 1 ? candidates[0].occurrence_id : null,
  };
}

/**
 * @param {import('pg').Pool} pool
 * @param {string} petId
 * @param {import('express').Request} [req]
 */
export async function loadWeightOverview(pool, petId, req) {
  const timeZone = await loadPetHomeTimezone(pool, petId);
  const asOf = careAsOfForZone(timeZone, careClockFromRequest(req));
  const ctx = await loadWeightOverviewContext(pool, petId);
  const routines = ctx.items.map((item) => {
    const pending = ctx.pendingByEntry.get(item.id) || [];
    const nextOcc = pending[0] || null;
    return {
      entry_id: item.id,
      name: item.name,
      status: item.status,
      frequency: item.frequency,
      frequency_interval: item.frequency_interval,
      frequency_days: item.frequency_days,
      next: nextOcc
        ? {
          occurrence_id: nextOcc.id,
          scheduled_date: dateToIsoDate(nextOcc.scheduled_date),
          status: occurrenceStatus({ occurrence: nextOcc, entry: item, asOf }),
        }
        : null,
    };
  });
  routines.sort((a, b) => {
    const ad = a.next?.scheduled_date ?? '9999-12-31';
    const bd = b.next?.scheduled_date ?? '9999-12-31';
    return ad.localeCompare(bd);
  });
  const pet = ctx.pet;
  const reference = pet?.weight_reference_value != null
    ? {
      value: pet.weight_reference_value,
      authority: pet.weight_reference_authority,
      management_context: pet.weight_management_context || 'none',
    }
    : null;
  return {
    pet_id: petId,
    as_of: {
      date: asOf.todayIso,
      time: asOf.nowTimeIso ?? null,
      timezone: timeZone,
    },
    reference,
    routines,
  };
}

async function assertEligibleForOccurrence(db, {
  entry,
  occurrence,
  dateIso,
  asOf,
  latestCompletedOn,
}) {
  if (!isFulfilmentEligible({
    entry,
    occurrence,
    dateIso,
    todayIso: asOf.todayIso,
    latestCompletedOn,
  })) {
    throw new FulfilmentError('fulfilment_not_eligible');
  }
}

/**
 * @param {import('pg').Pool} pool
 * @param {{
 *   petId: string,
 *   userId: string,
 *   occurrenceId: string,
 *   weight: unknown,
 *   unit?: unknown,
 *   date?: unknown,
 *   notes?: string,
 *   measurementSource: string,
 *   entryId?: string,
 *   req?: import('express').Request,
 * }} params
 */
export async function recordWeightWithFulfilment(pool, params) {
  const parsed = parseWeightInput({ weight: params.weight, unit: params.unit });
  if (parsed.error) {
    throw new WeightValidationError(parsed.error);
  }
  const timeZone = await loadPetHomeTimezone(pool, params.petId);
  const asOf = careAsOfForZone(timeZone, careClockFromRequest(params.req));
  const dateVal = normalizeCalendarDateInput(params.date) || asOf.todayIso;
  if (dateVal > asOf.todayIso) {
    throw new WeightValidationError('date cannot be in the future', { code: 'date_in_future' });
  }

  const ctx = await loadFulfilmentContext(pool, params.petId);
  let targetEntry = null;
  let targetOcc = null;
  for (const item of ctx.items) {
    const pending = ctx.pendingByEntry.get(item.id) || [];
    const match = pending.find((o) => o.id === params.occurrenceId);
    if (match) {
      targetEntry = item;
      targetOcc = match;
      break;
    }
  }
  if (!targetEntry || !targetOcc) {
    throw new FulfilmentError('fulfilment_not_eligible');
  }

  const latestCompletedOn = ctx.latestCompletedOnByEntry.get(targetEntry.id) ?? null;
  const weightId = params.entryId || uuidv4();
  let weightRow = null;
  let commandOut = null;

  try {
    commandOut = await runCareCommand(pool, {
      entryId: targetEntry.id,
      userId: params.userId,
      req: params.req,
      beforeCommand: async (db) => {
        await assertEligibleForOccurrence(db, {
          entry: targetEntry,
          occurrence: targetOcc,
          dateIso: dateVal,
          asOf,
          latestCompletedOn,
        });
        weightRow = await insertWeightEntry(db, {
          id: weightId,
          petId: params.petId,
          userId: params.userId,
          weightKg: parsed.kg,
          date: dateVal,
          notes: params.notes || '',
          measurementSource: params.measurementSource,
          healthOccurrenceId: params.occurrenceId,
        });
        await refreshPetWeightCache(db, params.petId);
        await maybePersistWeightEstablishment(db, {
          petId: params.petId,
          healthEntryId: targetEntry.id,
        });
      },
    }, async (cmdCtx) => {
      const out = await completeOccurrenceCommand(cmdCtx, {
        occurrenceId: params.occurrenceId,
        completedOn: dateVal,
        notes: params.notes || '',
      });
      if (out?.event) {
        out.event.extra = {
          ...(out.event.extra || {}),
          observation: { kind: 'numeric_weight', id: weightId, created: true },
        };
      }
      return out;
    });
  } catch (err) {
    if (err instanceof CareCommandError) {
      const body = err.toBody();
      throw new WeightValidationError(body.error, {
        status: err.status,
        code: body.code,
      });
    }
    if (err.code === '23505') {
      throw new FulfilmentError('already_linked');
    }
    throw err;
  }

  if (!commandOut) {
    throw new FulfilmentError('occurrence_not_open');
  }

  return {
    weightRow,
    fulfilment: buildFulfilmentPayload(targetEntry.id, commandOut),
  };
}

/**
 * @param {import('pg').Pool} pool
 * @param {{
 *   weightEntryId: string,
 *   userId: string,
 *   occurrenceId: string,
 *   req?: import('express').Request,
 * }} params
 */
export async function fulfilExistingWeight(pool, params) {
  const existing = await findWeightEntryById(pool, params.weightEntryId);
  if (!existing) {
    return null;
  }
  if (existing.health_occurrence_id) {
    throw new FulfilmentError('already_linked');
  }
  const dateVal = dateToIsoDate(existing.date);
  const timeZone = await loadPetHomeTimezone(pool, existing.pet_id);
  const asOf = careAsOfForZone(timeZone, careClockFromRequest(params.req));

  const ctx = await loadFulfilmentContext(pool, existing.pet_id);
  let targetEntry = null;
  let targetOcc = null;
  for (const item of ctx.items) {
    const pending = ctx.pendingByEntry.get(item.id) || [];
    const match = pending.find((o) => o.id === params.occurrenceId);
    if (match) {
      targetEntry = item;
      targetOcc = match;
      break;
    }
  }
  if (!targetEntry || !targetOcc) {
    throw new FulfilmentError('fulfilment_not_eligible');
  }

  const latestCompletedOn = ctx.latestCompletedOnByEntry.get(targetEntry.id) ?? null;
  let commandOut = null;

  try {
    commandOut = await runCareCommand(pool, {
      entryId: targetEntry.id,
      userId: params.userId,
      req: params.req,
      beforeCommand: async (db) => {
        await assertEligibleForOccurrence(db, {
          entry: targetEntry,
          occurrence: targetOcc,
          dateIso: dateVal,
          asOf,
          latestCompletedOn,
        });
        const linked = await linkWeightToOccurrence(db, params.weightEntryId, params.occurrenceId);
        if (!linked) {
          throw new FulfilmentError('already_linked');
        }
        await refreshPetWeightCache(db, existing.pet_id);
        await maybePersistWeightEstablishment(db, {
          petId: existing.pet_id,
          healthEntryId: targetEntry.id,
        });
      },
    }, async (cmdCtx) => {
      const out = await completeOccurrenceCommand(cmdCtx, {
        occurrenceId: params.occurrenceId,
        completedOn: dateVal,
        notes: existing.notes || '',
      });
      if (out?.event) {
        out.event.extra = {
          ...(out.event.extra || {}),
          observation: { kind: 'numeric_weight', id: params.weightEntryId, created: false },
        };
      }
      return out;
    });
  } catch (err) {
    if (err instanceof FulfilmentError) throw err;
    if (err instanceof CareCommandError) {
      const body = err.toBody();
      throw new WeightValidationError(body.error, {
        status: err.status,
        code: body.code,
      });
    }
    if (err.code === '23505') {
      throw new FulfilmentError('already_linked');
    }
    throw err;
  }

  if (!commandOut) {
    throw new FulfilmentError('occurrence_not_open');
  }

  const refreshed = await findWeightEntryById(pool, params.weightEntryId);
  return {
    weightRow: refreshed,
    fulfilment: buildFulfilmentPayload(targetEntry.id, commandOut),
  };
}

function buildFulfilmentPayload(entryId, commandOut) {
  return {
    entry_id: entryId,
    occurrence: occurrenceToMap(commandOut.occurrence),
    next_due_date: dateToIsoDate(commandOut.entry.next_due_date),
    undo_token: commandOut.undoToken,
  };
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {string[]} occurrenceIds
 * @returns {Promise<Map<string, { value: number, unit: string, date: string }>>}
 */
export async function loadLinkedWeightsForOccurrences(db, occurrenceIds) {
  if (occurrenceIds.length === 0) return new Map();
  const result = await db.query(
    `SELECT health_occurrence_id, weight, unit, date
     FROM weight_entries
     WHERE health_occurrence_id = ANY($1::uuid[])`,
    [occurrenceIds],
  );
  const map = new Map();
  for (const row of result.rows) {
    map.set(row.health_occurrence_id, {
      value: row.weight,
      unit: 'kg',
      date: dateToIsoDate(row.date),
    });
  }
  return map;
}
