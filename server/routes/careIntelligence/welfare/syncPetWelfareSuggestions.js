import { upsertWelfareSuggestionCandidate } from '../welfareSuggestionsService.js';
import { WELFARE_SYNC_SUBJECTS } from './welfareSyncSubjects.js';

async function withdrawPendingByDedupe(pool, petId, dedupeKey) {
  await pool.query(
    `UPDATE welfare_suggestions
     SET status = 'completed',
         primary_outcome = 'withdrawn',
         responded_at = NOW(),
         updated_at = NOW()
     WHERE pet_id = $1 AND dedupe_key = $2 AND status = 'pending'`,
    [petId, dedupeKey],
  );
}

/**
 * Reconcile welfare rows from profile facts (PR-07+ subjects).
 */
export async function syncPetWelfareSuggestions(pool, pet, now = new Date()) {
  for (const subject of WELFARE_SYNC_SUBJECTS) {
    const candidate = subject.evaluate(pet);
    const dedupe = subject.dedupeKey(pet.id);
    if (candidate) {
      await upsertWelfareSuggestionCandidate(pool, pet.id, candidate, now);
    } else {
      await withdrawPendingByDedupe(pool, pet.id, dedupe);
    }
  }
}
