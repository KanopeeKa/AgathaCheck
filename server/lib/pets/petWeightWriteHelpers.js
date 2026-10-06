/**
 * Pet profile weight payload validation and persistence during create/update.
 * Owns the bridge from HTTP pet bodies to weight observation rows and cache refresh.
 */

import { parseWeightInput } from '../care/observations/weightUnits.js';
import { recordWeightFromPetPayload } from '../care/observations/weightObservationService.js';
import { refreshPetWeightCache, resolveWeightEntryDateFromBody } from '../petWeightSync.js';

export function rejectInvalidPetWeight(weight, res) {
  if (weight == null || weight === '') return false;
  const parsed = parseWeightInput({ weight, unit: 'kg' });
  if (parsed.error) {
    res.status(400).json({
      error: 'weight must be a positive number',
      code: 'invalid_weight',
    });
    return true;
  }
  return false;
}

export async function applyPetWeightFromPayload(db, { petId, userId, weight, body, req }) {
  if (weight == null || weight === '') {
    await refreshPetWeightCache(db, petId);
    return null;
  }
  const result = await recordWeightFromPetPayload(db, {
    petId,
    userId,
    weight,
    date: resolveWeightEntryDateFromBody(body),
    req,
  });
  if (!result.ok) {
    const err = new Error('pet weight payload rejected');
    err.status = result.status;
    err.body = result.body;
    throw err;
  }
  return result;
}
