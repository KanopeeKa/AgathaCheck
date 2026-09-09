import { v4 as uuidv4 } from 'uuid';

import { dateToIsoDate } from '../../calendarDate.js';
import { createMilestonesOnEstablishment } from './careMilestoneService.js';
import {
  evaluateWeightEstablishment,
  WEIGHT_ESTABLISHMENT_POLICY_VERSION,
} from './weightEstablishmentPolicy.js';

/**
 * @param {object} row
 */
export function establishmentToDto(row) {
  return {
    id: row.id,
    care_family: row.care_family,
    health_entry_id: row.health_entry_id,
    established_at: row.established_at instanceof Date
      ? row.established_at.toISOString()
      : row.established_at,
    policy_version: row.policy_version,
  };
}

/**
 * @param {import('pg').Pool} pool
 * @param {string} petId
 */
export async function loadEstablishmentsForPet(pool, petId) {
  const result = await pool.query(
    `SELECT id, pet_id, care_family, health_entry_id, established_at, policy_version, created_at
     FROM care_establishments
     WHERE pet_id = $1
     ORDER BY established_at ASC`,
    [petId],
  );
  return result.rows.map(establishmentToDto);
}

/**
 * @param {import('pg').Pool} pool
 * @param {string} petId
 * @param {string} healthEntryId
 */
export async function loadWeightEstablishmentFacts(pool, petId, healthEntryId) {
  const entryResult = await pool.query(
    `SELECT id, pet_id, care_family, status, frequency, frequency_interval, frequency_days
     FROM health_entries
     WHERE id = $1 AND pet_id = $2`,
    [healthEntryId, petId],
  );
  const entry = entryResult.rows[0] || null;

  const establishmentResult = await pool.query(
    `SELECT id, pet_id, care_family, health_entry_id, established_at, policy_version, created_at
     FROM care_establishments
     WHERE health_entry_id = $1`,
    [healthEntryId],
  );
  const existingEstablishment = establishmentResult.rows[0] || null;

  let completedEvidence = [];
  let skippedCount = 0;
  let legacyCompletedWithoutWeight = 0;

  if (entry) {
    const occResult = await pool.query(
      `SELECT ho.id, ho.status, ho.completed_on, ho.scheduled_date,
              we.id AS weight_id, we.date, we.weight, we.unit, we.measurement_source
       FROM health_occurrences ho
       LEFT JOIN weight_entries we ON we.health_occurrence_id = ho.id
       WHERE ho.health_entry_id = $1
       ORDER BY COALESCE(ho.completed_on, ho.scheduled_date)`,
      [healthEntryId],
    );

    for (const row of occResult.rows) {
      if (row.status === 'skipped') {
        skippedCount += 1;
        continue;
      }
      if (row.status !== 'completed') continue;
      if (!row.weight_id) {
        legacyCompletedWithoutWeight += 1;
        continue;
      }
      completedEvidence.push({
        occurrenceId: row.id,
        completedOn: row.completed_on,
        scheduledDate: row.scheduled_date,
        measurement: {
          date: dateToIsoDate(row.date),
          weight: row.weight,
          unit: row.unit || 'kg',
          measurement_source: row.measurement_source || 'guardian',
        },
      });
    }
  }

  return {
    entry,
    existingEstablishment,
    completedEvidence,
    skippedCount,
    legacyCompletedWithoutWeight,
  };
}

/**
 * @param {import('pg').Pool} pool
 * @param {{ petId: string, healthEntryId: string }} params
 */
export async function maybePersistWeightEstablishment(pool, { petId, healthEntryId }) {
  const facts = await loadWeightEstablishmentFacts(pool, petId, healthEntryId);
  const evaluation = evaluateWeightEstablishment(petId, healthEntryId, facts);

  if (facts.existingEstablishment) {
    return {
      persisted: false,
      establishment: establishmentToDto(facts.existingEstablishment),
      evaluation,
    };
  }

  if (evaluation.maturity !== 'established') {
    return { persisted: false, establishment: null, evaluation };
  }

  if (!facts.entry) {
    return { persisted: false, establishment: null, evaluation };
  }

  const id = uuidv4();
  const establishedAt = new Date();
  const insertResult = await pool.query(
    `INSERT INTO care_establishments
      (id, pet_id, care_family, health_entry_id, established_at, policy_version)
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (health_entry_id) DO NOTHING
     RETURNING id, pet_id, care_family, health_entry_id, established_at, policy_version, created_at`,
    [
      id,
      petId,
      facts.entry.care_family,
      healthEntryId,
      establishedAt,
      evaluation.policyVersion || WEIGHT_ESTABLISHMENT_POLICY_VERSION,
    ],
  );

  if (insertResult.rows.length > 0) {
    const establishment = establishmentToDto(insertResult.rows[0]);
    const milestones = await createMilestonesOnEstablishment(pool, {
      petId,
      careFamily: facts.entry.care_family,
      healthEntryId,
      achievedAt: insertResult.rows[0].established_at,
    });
    return {
      persisted: true,
      establishment,
      evaluation,
      milestones,
    };
  }

  const existingResult = await pool.query(
    `SELECT id, pet_id, care_family, health_entry_id, established_at, policy_version, created_at
     FROM care_establishments
     WHERE health_entry_id = $1`,
    [healthEntryId],
  );

  return {
    persisted: false,
    establishment: existingResult.rows[0]
      ? establishmentToDto(existingResult.rows[0])
      : null,
    evaluation: {
      ...evaluation,
      reasonCodes: ['already_established'],
      maturity: null,
    },
  };
}

/**
 * @param {import('pg').Pool} pool
 * @param {string} petId
 * @param {string | null | undefined} healthEntryId
 */
export async function reEvaluateWeightEstablishments(pool, petId, healthEntryId) {
  const entryIds = healthEntryId
    ? [healthEntryId]
    : (await pool.query(
      `SELECT id FROM health_entries
       WHERE pet_id = $1 AND care_family = 'weight_monitoring'`,
      [petId],
    )).rows.map((row) => row.id);

  const results = [];
  for (const id of entryIds) {
    results.push({
      health_entry_id: id,
      ...(await maybePersistWeightEstablishment(pool, { petId, healthEntryId: id })),
    });
  }
  return results;
}
