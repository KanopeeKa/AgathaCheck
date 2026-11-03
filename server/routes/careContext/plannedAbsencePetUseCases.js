/**
 * Add/remove pets on a saved absence (declarer-only writes).
 */

import { withTransaction } from '../../lib/db/withTransaction.js';
import {
  cancelPlannedAbsenceInTransaction,
  countAbsencePets,
  deleteAbsencePetRow,
  deleteAbsenceResolutionsForPet,
  revokeGuestGrantsForAbsencePet,
  trimCarerInvitesForAbsencePet,
} from '../../lib/care/absence/absencePetLifecycle.js';
import {
  PLANNED_ABSENCE_STATUS_CANCELLED,
  resolvePlannedAbsenceTodayIso,
} from '../../lib/care/plannedAbsence.js';
import { userCanManageProfile } from '../../lib/petAccess.js';
import {
  applyGuestAccessWidenAfterPatch,
  evaluateGuestAccessWidenGate,
} from '../../lib/people/absenceGuestPatch.js';
import { absenceResponse } from './plannedAbsenceHandoverFields.js';
import {
  loadAbsenceForUser,
  loadAbsencePets,
} from './plannedAbsenceStore.js';
import {
  findOverlapWarnings,
} from './plannedAbsenceOverlap.js';

async function assertFullAccessToPet(pool, userId, petId) {
  if (!(await userCanManageProfile(pool, petId, userId))) {
    return { ok: false, status: 403, error: 'Forbidden' };
  }
  return { ok: true };
}

export async function addPetToPlannedAbsence(pool, userId, absenceId, body) {
  const existing = await loadAbsenceForUser(pool, absenceId, userId);
  if (!existing) return { status: 404, error: 'Not found' };
  if (existing.status === PLANNED_ABSENCE_STATUS_CANCELLED) {
    return { status: 400, error: 'Cannot edit a cancelled absence' };
  }

  const petId = body.pet_id || body.petId;
  if (!petId) return { status: 400, error: 'pet_id is required' };

  const access = await assertFullAccessToPet(pool, userId, petId);
  if (!access.ok) return { status: access.status, error: access.error };

  const petRows = await loadAbsencePets(pool, absenceId);
  const originalPetIds = petRows.map((row) => row.pet_id);
  if (originalPetIds.includes(petId)) {
    return { status: 400, error: 'Pet is already on this absence' };
  }

  const newPetIds = [...originalPetIds, petId];
  const todayIso = await resolvePlannedAbsenceTodayIso(pool, userId);
  const overlapWarnings = await findOverlapWarnings(
    pool,
    userId,
    [petId],
    existing.starts_on,
    existing.ends_on,
    absenceId,
    todayIso,
  );

  const window = {
    starts_on: String(existing.starts_on).split(/[T ]/)[0],
    ends_on: String(existing.ends_on).split(/[T ]/)[0],
  };
  const widenGate = await evaluateGuestAccessWidenGate(pool, {
    existing,
    body,
    oldPetIds: originalPetIds,
    newPetIds,
    window,
  });
  if (!widenGate.ok) {
    return { status: widenGate.status, payload: widenGate.payload };
  }

  await withTransaction(pool, async (client) => {
    await client.query(
      `INSERT INTO planned_absence_pets (planned_absence_id, pet_id)
       VALUES ($1, $2)
       ON CONFLICT (planned_absence_id, pet_id) DO NOTHING`,
      [absenceId, petId],
    );
    await client.query(
      `UPDATE planned_absences SET updated_at = NOW() WHERE id = $1`,
      [absenceId],
    );
    await applyGuestAccessWidenAfterPatch(client, {
      absenceId,
      widen: widenGate.widen,
      confirmed: widenGate.confirmed,
      actorUserId: userId,
    });
  });

  const updatedPetRows = await loadAbsencePets(pool, absenceId);
  const refreshed = await loadAbsenceForUser(pool, absenceId, userId);
  return {
    body: {
      absence: absenceResponse(refreshed, updatedPetRows),
      overlap_warnings: overlapWarnings,
    },
  };
}

export async function removePetFromPlannedAbsence(pool, userId, absenceId, petId, body) {
  const existing = await loadAbsenceForUser(pool, absenceId, userId);
  if (!existing) return { status: 404, error: 'Not found' };
  if (existing.status === PLANNED_ABSENCE_STATUS_CANCELLED) {
    return { status: 400, error: 'Cannot edit a cancelled absence' };
  }

  const petRows = await loadAbsencePets(pool, absenceId);
  if (!petRows.some((row) => row.pet_id === petId)) {
    return { status: 404, error: 'Pet is not on this absence' };
  }

  const isLastPet = petRows.length === 1;
  const confirmed = body.confirm_delete_absence === true
    || body.confirmDeleteAbsence === true;
  if (isLastPet && !confirmed) {
    return {
      status: 409,
      payload: {
        error: 'Confirm deleting this absence',
        code: 'last_pet_removal_requires_confirm',
        pets_remaining: 1,
      },
    };
  }

  let cancelledAbsence = null;
  await withTransaction(pool, async (client) => {
    await revokeGuestGrantsForAbsencePet(client, absenceId, petId);
    await trimCarerInvitesForAbsencePet(client, absenceId, petId);
    await deleteAbsenceResolutionsForPet(client, absenceId, petId);
    await deleteAbsencePetRow(client, absenceId, petId);

    const remaining = await countAbsencePets(client, absenceId);
    if (remaining === 0) {
      cancelledAbsence = await cancelPlannedAbsenceInTransaction(
        client,
        absenceId,
        userId,
      );
    } else {
      await client.query(
        `UPDATE planned_absences SET updated_at = NOW() WHERE id = $1`,
        [absenceId],
      );
    }
  });

  if (cancelledAbsence) {
    return {
      body: {
        absence_deleted: true,
        absence_id: absenceId,
        pet_id: petId,
      },
    };
  }

  const updatedPetRows = await loadAbsencePets(pool, absenceId);
  const refreshed = await loadAbsenceForUser(pool, absenceId, userId);
  return {
    body: {
      absence_deleted: false,
      absence: absenceResponse(refreshed, updatedPetRows),
      pet_id: petId,
    },
  };
}
