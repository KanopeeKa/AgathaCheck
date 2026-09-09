import { createHash } from 'crypto';
import { v4 as uuidv4 } from 'uuid';

import { accessiblePetSql } from '../../lib/petAccess.js';
import { weightContextFromPetRow } from './provenance.js';
import { evaluateWeightSafeguard } from './weightSafeguardEvaluator.js';

export const SAFEGUARD_STATUSES = new Set(['active', 'dismissed']);

export function evidenceFingerprint(evidence) {
  const payload = {
    measurement_count: evidence?.measurement_count ?? null,
    direction: evidence?.direction ?? null,
    classification: evidence?.classification ?? null,
  };
  return createHash('sha256').update(JSON.stringify(payload)).digest('hex');
}

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
 * Evaluate and upsert active safeguard when criteria met; remove stale active rows.
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
    await pool.query(
      `DELETE FROM care_safeguards WHERE pet_id = $1 AND status = 'active'`,
      [petId],
    );
    return [];
  }

  const fingerprint = evidenceFingerprint(candidate.evidence);
  const existing = existingByKey.get(candidate.safeguard_key);
  if (existing) {
    if (existing.status === 'dismissed') {
      const dismissedFingerprint = existing.evidence_json?._dismiss_fingerprint;
      if (dismissedFingerprint === fingerprint) {
        return [];
      }
      const reactivated = await pool.query(
        `UPDATE care_safeguards
         SET status = 'active',
             dismissed_at = NULL,
             evidence_json = $1::jsonb,
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
      return [reactivated.rows[0]];
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
     ON CONFLICT (pet_id, safeguard_key) DO UPDATE SET
       status = EXCLUDED.status,
       policy_version = EXCLUDED.policy_version,
       copy_key = EXCLUDED.copy_key,
       evidence_json = EXCLUDED.evidence_json,
       updated_at = NOW()
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

  const active = await pool.query(
    `SELECT * FROM care_safeguards
     WHERE id = $1 AND pet_id = $2 AND status = 'active'`,
    [safeguardId, petId],
  );
  if (active.rows.length === 0) return undefined;

  const row = active.rows[0];
  const evidence = {
    ...(row.evidence_json || {}),
    _dismiss_fingerprint: evidenceFingerprint(row.evidence_json || {}),
  };

  const result = await pool.query(
    `UPDATE care_safeguards
     SET status = 'dismissed',
         dismissed_at = NOW(),
         evidence_json = $1::jsonb,
         updated_at = NOW()
     WHERE id = $2 AND pet_id = $3 AND status = 'active'
     RETURNING *`,
    [JSON.stringify(evidence), safeguardId, petId],
  );
  if (result.rows.length === 0) return undefined;
  return safeguardToMap(result.rows[0]);
}
