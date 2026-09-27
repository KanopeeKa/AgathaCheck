import { normalizeCalendarDateInput } from '../calendarDate.js';
import {
  absenceHasActiveGuestGrants,
  detectGuestAccessWiden,
  extendGuestGrantsToPets,
} from './absenceGuestGrants.js';

/**
 * D16 — block PATCH until guest access widen is confirmed when grants exist.
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} params
 */
export async function evaluateGuestAccessWidenGate(pool, {
  existing,
  body,
  oldPetIds,
  newPetIds,
  window,
}) {
  const hasGrants = await absenceHasActiveGuestGrants(pool, existing.id);
  const widen = detectGuestAccessWiden({
    existing: {
      ...existing,
      ends_on: normalizeCalendarDateInput(existing.ends_on),
    },
    newStartsOn: window.starts_on,
    newEndsOn: window.ends_on,
    oldPetIds,
    newPetIds,
    hasActiveGrants: hasGrants,
  });
  const confirmed = body.confirm_guest_access_widen === true
    || body.confirmGuestAccessWiden === true;
  if (widen.needsConfirm && !confirmed) {
    return {
      ok: false,
      status: 409,
      payload: {
        error: 'Confirm widening absence guest access',
        code: 'guest_access_widen_required',
        extends_dates: widen.extendsDates,
        added_pet_ids: widen.addedPetIds,
      },
    };
  }
  return { ok: true, widen, confirmed };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} client
 */
export async function applyGuestAccessWidenAfterPatch(client, {
  absenceId,
  widen,
  confirmed,
  actorUserId,
}) {
  if (widen.addedPetIds.length > 0 && confirmed) {
    await extendGuestGrantsToPets(client, absenceId, widen.addedPetIds, actorUserId);
  }
}
