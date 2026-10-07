import { NOTIFICATION_KIND_SUGGESTION } from '../notificationKind.js';
import {
  isAgathaSuggestionsInAppEnabled,
  isSuggestionTypeEnabled,
  loadNotificationPreferences,
} from '../notificationPreferences.js';
import {
  isSuggestionDedupeSuppressedForUser,
  listSuggestionRecipientUserIds,
} from '../notifications/suggestionInbox.js';
import { evaluateS1MissingRecurringCare, buildS1DedupeKey } from './s1MissingRecurringCare.js';
import { evaluateS2WeightTrend } from './s2WeightTrend.js';
import { canCreateNewSuggestion } from './suggestionRateLimits.js';
import {
  completeSuggestionsForDedupeKeys,
  expireStaleSuggestions,
  upsertWave1Suggestion,
} from './suggestionUpsert.js';
import { MIN_SUGGESTION_CONFIDENCE } from './suggestionConstants.js';

async function loadEligiblePets(pool, { petId = null, limit = 200 } = {}) {
  const params = [];
  let filter = 'WHERE COALESCE(p.passed_away, false) = false';
  if (petId) {
    filter += ' AND p.id = $1';
    params.push(petId);
  }
  params.push(limit);
  const limitIdx = params.length;
  const result = await pool.query(
    `SELECT p.id, p.name, p.species, p.date_of_birth, p.passed_away, p.user_id
     FROM pets p
     ${filter}
     ORDER BY p.updated_at DESC NULLS LAST, p.created_at DESC
     LIMIT $${limitIdx}`,
    params,
  );
  return result.rows;
}

async function loadHealthEntries(pool, petId) {
  const result = await pool.query(
    `SELECT care_family, frequency, care_source FROM health_entries WHERE pet_id = $1`,
    [petId],
  );
  return result.rows;
}

async function loadWeightEntries(pool, petId) {
  const result = await pool.query(
    `SELECT weight, unit, date, created_at FROM weight_entries
     WHERE pet_id = $1
     ORDER BY date DESC, created_at DESC
     LIMIT 24`,
    [petId],
  );
  return result.rows;
}

function isRecurringParasitePrevention(entries) {
  return entries.some(
    (e) => e.care_family === 'parasite_prevention'
      && e.frequency
      && e.frequency !== 'once',
  );
}

/**
 * Run wave-1 suggestion generation (S1, S2) for one or all pets.
 */
export async function runSuggestionGeneration(pool, options = {}) {
  const now = options.now || new Date();
  await expireStaleSuggestions(pool, now);

  const pets = await loadEligiblePets(pool, options);
  const stats = { pets: pets.length, upserted: 0, skipped_rate: 0, completed: 0 };

  for (const pet of pets) {
    const healthEntries = await loadHealthEntries(pool, pet.id);
    const weightEntries = await loadWeightEntries(pool, pet.id);

    const toComplete = [];
    if (isRecurringParasitePrevention(healthEntries)) {
      toComplete.push(buildS1DedupeKey(pet.id));
    }
    if (toComplete.length) {
      await completeSuggestionsForDedupeKeys(pool, toComplete);
      stats.completed += toComplete.length;
    }

    const candidates = [];
    const s1 = evaluateS1MissingRecurringCare(pet, healthEntries, now);
    if (s1 && s1.confidence >= MIN_SUGGESTION_CONFIDENCE) candidates.push(s1);
    const s2 = evaluateS2WeightTrend(pet, weightEntries);
    if (s2 && s2.confidence >= MIN_SUGGESTION_CONFIDENCE) candidates.push(s2);

    if (!candidates.length) continue;

    const recipientIds = await listSuggestionRecipientUserIds(pool, pet.id);
    for (const userId of recipientIds) {
      const prefs = await loadNotificationPreferences(pool, userId);
      if (!isAgathaSuggestionsInAppEnabled(prefs)) continue;
      const muted = prefs.muted_pet_ids || [];
      if (muted.includes(String(pet.id))) continue;

      for (const candidate of candidates) {
        if (!isSuggestionTypeEnabled(prefs, candidate.wireType)) continue;
        if (await isSuggestionDedupeSuppressedForUser(
          pool,
          userId,
          candidate.dedupeKey,
          now,
        )) {
          continue;
        }

        const existingActive = await pool.query(
          `SELECT id FROM notifications
           WHERE user_id = $1 AND suggestion_dedupe_key = $2
             AND kind = $3 AND archived_at IS NULL
             AND suggestion_state IN ('new', 'seen')
           LIMIT 1`,
          [userId, candidate.dedupeKey, NOTIFICATION_KIND_SUGGESTION],
        );
        const isUpdate = existingActive.rows.length > 0;
        if (!isUpdate) {
          const rate = await canCreateNewSuggestion(pool, {
            userId,
            petId: pet.id,
          });
          if (!rate.allowed) {
            stats.skipped_rate += 1;
            continue;
          }
        }

        const { created } = await upsertWave1Suggestion(pool, {
          userId,
          petId: pet.id,
          petName: pet.name,
          wireType: candidate.wireType,
          dedupeKey: candidate.dedupeKey,
          title: candidate.title,
          message: candidate.message,
          confidence: candidate.confidence,
          payload: candidate.payload,
        });

        if (created || isUpdate) stats.upserted += 1;
      }
    }
  }

  return stats;
}
