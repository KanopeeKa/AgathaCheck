import {
  upsertWelfareSuggestionCandidate,
} from '../welfareSuggestionsService.js';
import { evaluateMicrochipWelfare } from './microchipWelfareEvaluator.js';

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
 * Reconcile welfare rows from profile facts (PR-07 microchip subject).
 */
export async function syncPetWelfareSuggestions(pool, pet, now = new Date()) {
  const microchip = evaluateMicrochipWelfare(pet);
  if (microchip) {
    await upsertWelfareSuggestionCandidate(pool, pet.id, microchip, now);
  } else {
    const dedupe = `welfare:microchip:${pet.id}`;
    await withdrawPendingByDedupe(pool, pet.id, dedupe);
  }
}
