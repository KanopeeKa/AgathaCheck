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
import { loadAbsenceForViewer } from '../../lib/care/absence/absenceVisibility.js';
import { loadPerPetAwayPlan } from '../../lib/care/awayPlan/loadPerPetAwayPlan.js';
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
  updateAbsenceCarers,
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

function buildPerPetCarerPatchItem(petId, body) {
  const item = { pet_id: petId, petId };
  const keys = [
    'contact_id',
    'contactId',
    'carer_kind',
    'carerKind',
    'carer_user_id',
    'carerUserId',
    'carer_name',
    'carerName',
    'carer_note',
    'carerNote',
    'pet_note',
    'petNote',
  ];
  let any = false;
  for (const key of keys) {
    if (Object.hasOwn(body, key)) {
      item[key] = body[key];
      any = true;
    }
  }
  if (!any) {
    return { ok: false, status: 400, error: 'No editable fields in body' };
  }
  return { ok: true, item };
}

/**
 * Full-access co-parent (or declarer) updates one pet's carer / pet note on a visible absence.
 */
export async function patchPerPetPlannedAbsence(pool, actorUserId, absenceId, petId, body) {
  const viewed = await loadAbsenceForViewer(pool, absenceId, actorUserId);
  if (!viewed) return { status: 404, error: 'Not found' };

  const petRow = viewed.petRows.find((row) => row.pet_id === petId);
  if (!petRow) return { status: 404, error: 'Not found' };

  if (!(await userCanManageProfile(pool, petId, actorUserId))) {
    return { status: 404, error: 'Not found' };
  }

  if (viewed.row.status === PLANNED_ABSENCE_STATUS_CANCELLED) {
    return { status: 400, error: 'Cannot edit a cancelled absence' };
  }

  const built = buildPerPetCarerPatchItem(petId, body || {});
  if (!built.ok) return { status: built.status, error: built.error };

  const travellerUserId = viewed.row.user_id;
  const carerResult = await updateAbsenceCarers(
    pool,
    absenceId,
    [built.item],
    [petId],
    { actorUserId, travellerUserId },
  );
  if (!carerResult.ok) {
    return { status: carerResult.status, error: carerResult.error };
  }

  await pool.query(
    'UPDATE planned_absences SET updated_at = NOW() WHERE id = $1',
    [absenceId],
  );

  const updatedRows = await loadAbsencePets(pool, absenceId);
  const updatedPetRow = updatedRows.find((row) => row.pet_id === petId);
  const payload = await loadPerPetAwayPlan(pool, viewed.row, updatedPetRow, actorUserId);
  return { status: 200, body: payload };
}
