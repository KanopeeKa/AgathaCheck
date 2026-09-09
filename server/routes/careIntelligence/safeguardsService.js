import { v4 as uuidv4 } from 'uuid';

import { accessiblePetSql } from '../../lib/petAccess.js';
import { weightContextFromPetRow } from './provenance.js';
import { evaluateWeightSafeguard } from './weightSafeguardEvaluator.js';

export const SAFEGUARD_STATUSES = new Set(['active', 'dismissed']);

export function safeguardToMap(row) {
  return {
    id: row.id,
    pet_id: row.pet_id,
    safeguard_type: row.safeguard_type,
    safeguard_key: row.safeguard_key,
    status: row.status,
    policy_version: row.policy_version,
    copy_key: row.copy_key,
    evidence: row.evidence_json || {},
    dismissed_at: row.dismissed_at,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

async function loadWeightMeasurements(pool, petId) {
  const result = await pool.query(
    `SELECT weight, unit, date, measurement_source
     FROM weight_entries
     WHERE pet_id = $1
     ORDER BY date ASC`,
    [petId],
  );
  return result.rows.map((row) => ({
    weight: Number(row.weight),
    unit: row.unit || 'kg',
    date: row.date,
    measurement_source: row.measurement_source,
  }));
}

async function loadPetRow(pool, userId, petId) {
  const petResult = await pool.query(
    `SELECT p.* FROM pets p
     WHERE p.id = $1 AND ${accessiblePetSql('p', '$2')}`,
    [petId, userId],
  );
  return petResult.rows[0] || null;
}

/**
 * Evaluate and upsert active safeguard when criteria met; clear stale active rows.
 */
export async function syncPetSafeguards(pool, userId, petId) {
  const pet = await loadPetRow(pool, userId, petId);
  if (!pet) return null;

  const measurements = await loadWeightMeasurements(pool, petId);
  const weightContext = weightContextFromPetRow(pet);
  const candidate = evaluateWeightSafeguard({
    pet,
    measurements,
    weightContext,
  });

  const existingResult = await pool.query(
    `SELECT * FROM care_safeguards WHERE pet_id = $1`,
    [petId],
  );
  const existingByKey = new Map(
    existingResult.rows.map((row) => [row.safeguard_key, row]),
  );

  if (!candidate) {
    const activeRows = existingResult.rows.filter((row) => row.status === 'active');
    for (const row of activeRows) {
      await pool.query(
        `UPDATE care_safeguards
         SET status = 'dismissed', dismissed_at = NOW(), updated_at = NOW()
         WHERE id = $1`,
        [row.id],
      );
    }
    return [];
  }

  const existing = existingByKey.get(candidate.safeguard_key);
  if (existing) {
    if (existing.status === 'dismissed') {
      return [];
    }
    const updated = await pool.query(
      `UPDATE care_safeguards
       SET evidence_json = $1::jsonb,
           policy_version = $2,
           copy_key = $3,
           updated_at = NOW()
       WHERE id = $4
       RETURNING *`,
      [
        JSON.stringify(candidate.evidence),
        candidate.policy_version,
        candidate.copy_key,
        existing.id,
      ],
    );
    return [updated.rows[0]];
  }

  const id = uuidv4();
  const inserted = await pool.query(
    `INSERT INTO care_safeguards (
       id, pet_id, safeguard_type, safeguard_key, status,
       policy_version, copy_key, evidence_json
     ) VALUES ($1,$2,$3,$4,'active',$5,$6,$7::jsonb)
     RETURNING *`,
    [
      id,
      petId,
      candidate.safeguard_type,
      candidate.safeguard_key,
      candidate.policy_version,
      candidate.copy_key,
      JSON.stringify(candidate.evidence),
    ],
  );
  return [inserted.rows[0]];
}

export async function listActiveSafeguards(pool, userId, petId) {
  const synced = await syncPetSafeguards(pool, userId, petId);
  if (synced === null) return null;
  return synced.filter((row) => row.status === 'active').map(safeguardToMap);
}

export async function dismissSafeguard(pool, userId, petId, safeguardId) {
  const pet = await loadPetRow(pool, userId, petId);
  if (!pet) return null;

  const result = await pool.query(
    `UPDATE care_safeguards
     SET status = 'dismissed', dismissed_at = NOW(), updated_at = NOW()
     WHERE id = $1 AND pet_id = $2 AND status = 'active'
     RETURNING *`,
    [safeguardId, petId],
  );
  if (result.rows.length === 0) return undefined;
  return safeguardToMap(result.rows[0]);
}
