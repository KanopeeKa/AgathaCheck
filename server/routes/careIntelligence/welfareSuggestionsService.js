import { v4 as uuidv4 } from 'uuid';

import { accessiblePetSql } from '../../lib/petAccess.js';

export const WELFARE_SUGGESTION_STATUSES = new Set([
  'pending',
  'dismissed',
  'completed',
]);

export const WELFARE_RESPONSE_ACTIONS = new Set(['dismiss', 'complete']);

export const WELFARE_DISMISS_SUPPRESS_DAYS = 30;

export function welfareSuggestionToMap(row) {
  return {
    id: row.id,
    pet_id: row.pet_id,
    subject_key: row.subject_key,
    dedupe_key: row.dedupe_key,
    status: row.status,
    primary_outcome: row.primary_outcome,
    rationale_key: row.rationale_key,
    engine_version: row.engine_version,
    severity: row.severity,
    dismissed_until: row.dismissed_until ? row.dismissed_until.toISOString() : null,
    responded_at: row.responded_at ? row.responded_at.toISOString() : null,
    created_at: row.created_at ? row.created_at.toISOString() : null,
    updated_at: row.updated_at ? row.updated_at.toISOString() : null,
  };
}

export function isWelfareDedupeSuppressed(row, now = new Date()) {
  if (!row || row.status !== 'dismissed') return false;
  if (!row.dismissed_until) return true;
  return now < new Date(row.dismissed_until);
}

function addSuppressDays(fromDate) {
  const until = new Date(fromDate);
  until.setUTCDate(until.getUTCDate() + WELFARE_DISMISS_SUPPRESS_DAYS);
  return until;
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
 * Upsert by (pet_id, dedupe_key). Refreshes copy on pending rows.
 * Does not resurface dismissed rows inside the 30d suppress window (AC-WF-03).
 */
export async function upsertWelfareSuggestionCandidate(pool, petId, candidate, now = new Date()) {
  const existing = await pool.query(
    `SELECT * FROM welfare_suggestions WHERE pet_id = $1 AND dedupe_key = $2`,
    [petId, candidate.dedupe_key],
  );
  if (existing.rows.length > 0) {
    const row = existing.rows[0];
    if (isWelfareDedupeSuppressed(row, now)) {
      return row;
    }
    if (row.status === 'completed') {
      return row;
    }
    const updated = await pool.query(
      `UPDATE welfare_suggestions
       SET subject_key = $1,
           rationale_key = $2,
           engine_version = $3,
           severity = $4,
           status = 'pending',
           dismissed_until = NULL,
           updated_at = NOW()
       WHERE id = $5
       RETURNING *`,
      [
        candidate.subject_key,
        candidate.rationale_key,
        candidate.engine_version,
        candidate.severity ?? 0,
        row.id,
      ],
    );
    return updated.rows[0];
  }

  const id = uuidv4();
  const inserted = await pool.query(
    `INSERT INTO welfare_suggestions (
       id, pet_id, subject_key, dedupe_key, status,
       rationale_key, engine_version, severity
     ) VALUES ($1,$2,$3,$4,'pending',$5,$6,$7)
     RETURNING *`,
    [
      id,
      petId,
      candidate.subject_key,
      candidate.dedupe_key,
      candidate.rationale_key,
      candidate.engine_version,
      candidate.severity ?? 0,
    ],
  );
  return inserted.rows[0];
}

export async function listPendingWelfareSuggestions(pool, userId, petId, now = new Date()) {
  const pet = await loadPetRow(pool, userId, petId);
  if (!pet) return null;
  const result = await pool.query(
    `SELECT * FROM welfare_suggestions WHERE pet_id = $1 AND status = 'pending'`,
    [petId],
  );
  return result.rows
    .filter((row) => !isWelfareDedupeSuppressed(row, now))
    .map(welfareSuggestionToMap);
}

export async function respondToWelfareSuggestion(
  pool,
  userId,
  petId,
  suggestionId,
  action,
  { primaryOutcome = null, now = new Date() } = {},
) {
  const pet = await loadPetRow(pool, userId, petId);
  if (!pet) return null;

  const recResult = await pool.query(
    `SELECT * FROM welfare_suggestions WHERE id = $1 AND pet_id = $2`,
    [suggestionId, petId],
  );
  if (recResult.rows.length === 0) return undefined;

  if (action === 'dismiss') {
    const dismissedUntil = addSuppressDays(now);
    const updated = await pool.query(
      `UPDATE welfare_suggestions
       SET status = 'dismissed',
           dismissed_until = $1,
           responded_at = $2,
           updated_at = NOW()
       WHERE id = $3
       RETURNING *`,
      [dismissedUntil, now, suggestionId],
    );
    return welfareSuggestionToMap(updated.rows[0]);
  }

  if (action === 'complete') {
    const outcome = (primaryOutcome || '').trim();
    if (!outcome) {
      return { error: 'primary_outcome_required' };
    }
    const updated = await pool.query(
      `UPDATE welfare_suggestions
       SET status = 'completed',
           primary_outcome = $1,
           responded_at = $2,
           dismissed_until = NULL,
           updated_at = NOW()
       WHERE id = $3
       RETURNING *`,
      [outcome, now, suggestionId],
    );
    return welfareSuggestionToMap(updated.rows[0]);
  }

  return { error: 'invalid_action' };
}
