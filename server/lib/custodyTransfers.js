import { v4 as uuidv4 } from 'uuid';

import { findActiveConnection } from './orgConnections.js';
import {
  createOrgPetShadow,
  deleteShadowForPetAndOrg,
} from './orgPetShadow.js';
import {
  clearOrgPetHomeHiddenForPet,
  setIndividualGuardianAndCare,
  setOrgGuardianAndCare,
  userIsOrgAdmin,
} from './petCustody.js';
import { createNotification, userDisplayName } from './notificationHelper.js';
import { closeActivePlacementForPet } from './fosterPlacements.js';

export const TRANSFER_INDIVIDUAL = 'individual_guardianship';
export const TRANSFER_ORG_TO_ORG = 'org_to_org';
export const TRANSFER_RETURN = 'return_to_org';

export async function requestCustodyTransfer(db, {
  petId,
  transferKind,
  requestedByUserId,
  requestingOrgId,
  toUserId = null,
  toOrgId = null,
  notes = '',
}) {
  const petResult = await db.query('SELECT * FROM pets WHERE id = $1', [petId]);
  if (petResult.rows.length === 0) {
    const err = new Error('Pet not found');
    err.statusCode = 404;
    throw err;
  }
  const pet = petResult.rows[0];

  if (transferKind === TRANSFER_ORG_TO_ORG) {
    if (!requestingOrgId || !toOrgId) {
      const err = new Error('to_org_id is required');
      err.statusCode = 400;
      throw err;
    }
    if (String(pet.organization_id) !== String(requestingOrgId)) {
      const err = new Error('Pet is not in this organisation');
      err.statusCode = 400;
      throw err;
    }
    if (!(await findActiveConnection(db, requestingOrgId, toOrgId))) {
      const err = new Error('Organisations must be connected before transfer');
      err.statusCode = 400;
      throw err;
    }
    if (!(await userIsOrgAdmin(db, requestingOrgId, requestedByUserId))) {
      const err = new Error('Forbidden');
      err.statusCode = 403;
      throw err;
    }
  } else if (transferKind === TRANSFER_INDIVIDUAL) {
    if (!requestingOrgId || !toUserId) {
      const err = new Error('to_user_id is required');
      err.statusCode = 400;
      throw err;
    }
    if (String(pet.organization_id) !== String(requestingOrgId)) {
      const err = new Error('Pet is not in this organisation');
      err.statusCode = 400;
      throw err;
    }
    if (!(await userIsOrgAdmin(db, requestingOrgId, requestedByUserId))) {
      const err = new Error('Forbidden');
      err.statusCode = 403;
      throw err;
    }
  } else if (transferKind === TRANSFER_RETURN) {
    if (!toOrgId) {
      const err = new Error('to_org_id is required');
      err.statusCode = 400;
      throw err;
    }
    const isUserGuardian = !pet.organization_id && String(pet.user_id) === String(requestedByUserId);
    const isOrgGuardian =
      pet.organization_id &&
      (await userIsOrgAdmin(db, pet.organization_id, requestedByUserId));
    if (!isUserGuardian && !isOrgGuardian) {
      const err = new Error('Forbidden');
      err.statusCode = 403;
      throw err;
    }
  } else {
    const err = new Error('Invalid transfer kind');
    err.statusCode = 400;
    throw err;
  }

  const pending = await db.query(
    `SELECT 1 FROM custody_transfers WHERE pet_id = $1 AND status = 'pending' LIMIT 1`,
    [petId],
  );
  if (pending.rows.length > 0) {
    const err = new Error('A custody transfer is already pending for this pet');
    err.statusCode = 409;
    throw err;
  }

  const id = uuidv4();
  await db.query(
    `INSERT INTO custody_transfers (
       id, pet_id, transfer_kind, from_org_id, from_user_id,
       to_org_id, to_user_id, requested_by_user_id, requesting_org_id, notes
     ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
    [
      id,
      petId,
      transferKind,
      pet.organization_id || null,
      pet.organization_id ? null : pet.user_id,
      toOrgId,
      toUserId,
      requestedByUserId,
      requestingOrgId || pet.organization_id || null,
      notes || '',
    ],
  );

  if (toUserId) {
    const requester = await db.query(
      'SELECT first_name, last_name, email FROM users WHERE id = $1',
      [requestedByUserId],
    );
    await createNotification(db, {
      userId: toUserId,
      petId,
      petName: pet.name,
      title: 'Custody transfer request',
      message: `${userDisplayName(requester.rows[0] || {})} requested a custody transfer for ${pet.name}.`,
      type: 'general',
    });
  }
  if (toOrgId && transferKind !== TRANSFER_RETURN) {
    const admins = await db.query(
      `SELECT user_id FROM organization_users
       WHERE organization_id = $1 AND role IN ('super_admin', 'admin')`,
      [toOrgId],
    );
    for (const row of admins.rows) {
      await createNotification(db, {
        userId: row.user_id,
        petId,
        petName: pet.name,
        title: 'Org custody transfer request',
        message: `A custody transfer for ${pet.name} is awaiting your organisation's approval.`,
        type: 'general',
      });
    }
  }
  if (toOrgId && transferKind === TRANSFER_RETURN) {
    const admins = await db.query(
      `SELECT user_id FROM organization_users
       WHERE organization_id = $1 AND role IN ('super_admin', 'admin')`,
      [toOrgId],
    );
    for (const row of admins.rows) {
      await createNotification(db, {
        userId: row.user_id,
        petId,
        petName: pet.name,
        title: 'Pet return request',
        message: `A return request for ${pet.name} is awaiting your organisation's approval.`,
        type: 'general',
      });
    }
  }

  return { id, transfer_kind: transferKind, status: 'pending' };
}

export async function acceptCustodyTransfer(db, transferId, acceptingUserId) {
  const tr = await db.query(
    'SELECT * FROM custody_transfers WHERE id = $1 FOR UPDATE',
    [transferId],
  );
  if (tr.rows.length === 0) {
    const err = new Error('Transfer not found');
    err.statusCode = 404;
    throw err;
  }
  const transfer = tr.rows[0];
  if (transfer.status !== 'pending') {
    const err = new Error('Transfer is not pending');
    err.statusCode = 400;
    throw err;
  }

  const petResult = await db.query('SELECT * FROM pets WHERE id = $1', [transfer.pet_id]);
  if (petResult.rows.length === 0) {
    const err = new Error('Pet not found');
    err.statusCode = 404;
    throw err;
  }
  const pet = petResult.rows[0];

  if (transfer.transfer_kind === TRANSFER_INDIVIDUAL) {
    if (String(transfer.to_user_id) !== String(acceptingUserId)) {
      const err = new Error('Forbidden');
      err.statusCode = 403;
      throw err;
    }
    await completeIndividualGuardianshipTransfer(db, {
      pet,
      fromOrgId: transfer.from_org_id,
      toUserId: transfer.to_user_id,
      actorUserId: acceptingUserId,
      notes: transfer.notes,
    });
  } else if (transfer.transfer_kind === TRANSFER_ORG_TO_ORG) {
    if (!(await userIsOrgAdmin(db, transfer.to_org_id, acceptingUserId))) {
      const err = new Error('Forbidden');
      err.statusCode = 403;
      throw err;
    }
    await completeOrgToOrgTransfer(db, {
      pet,
      fromOrgId: transfer.from_org_id,
      toOrgId: transfer.to_org_id,
      actorUserId: acceptingUserId,
      notes: transfer.notes,
    });
  } else if (transfer.transfer_kind === TRANSFER_RETURN) {
    if (!(await userIsOrgAdmin(db, transfer.to_org_id, acceptingUserId))) {
      const err = new Error('Forbidden');
      err.statusCode = 403;
      throw err;
    }
    await completeReturnToOrg(db, {
      pet,
      toOrgId: transfer.to_org_id,
      actorUserId: acceptingUserId,
    });
  }

  await db.query(
    `UPDATE custody_transfers
     SET status = 'accepted', responded_at = NOW(), responded_by_user_id = $2
     WHERE id = $1`,
    [transferId, acceptingUserId],
  );

  return { accepted: true, pet_id: pet.id };
}

export async function cancelCustodyTransfer(db, transferId, userId, reason = '') {
  const result = await db.query(
    `UPDATE custody_transfers
     SET status = 'cancelled', cancel_reason = $3, responded_at = NOW(), responded_by_user_id = $2
     WHERE id = $1 AND status = 'pending'
     RETURNING *`,
    [transferId, userId, reason],
  );
  if (result.rows.length === 0) {
    const err = new Error('Transfer not found');
    err.statusCode = 404;
    throw err;
  }
  return result.rows[0];
}

export async function completeIndividualGuardianshipTransfer(db, {
  pet,
  fromOrgId,
  toUserId,
  actorUserId,
  notes = '',
  closePlacements = true,
}) {
  if (closePlacements) {
    await closeActivePlacementForPet(db, pet.id);
  }
  await applyIndividualGuardianshipTransfer(db, {
    pet,
    fromOrgId,
    toUserId,
    actorUserId,
    notes,
  });
}

export async function applyIndividualGuardianshipTransfer(db, {
  pet,
  fromOrgId,
  toUserId,
  actorUserId,
  notes = '',
}) {
  await createOrgPetShadow(db, {
    organizationId: fromOrgId,
    pet,
    transferType: 'adoption',
    transferredToUserId: toUserId,
    actorUserId,
    notes,
  });
  await setIndividualGuardianAndCare(db, pet.id, toUserId);
  await db.query('DELETE FROM pet_access WHERE pet_id = $1 AND user_id = $2', [
    pet.id,
    toUserId,
  ]);
  await clearOrgPetHomeHiddenForPet(db, pet.id);
}

export async function completeOrgToOrgTransfer(db, {
  pet,
  fromOrgId,
  toOrgId,
  actorUserId,
  notes = '',
}) {
  await closeActivePlacementForPet(db, pet.id);
  await createOrgPetShadow(db, {
    organizationId: fromOrgId,
    pet,
    transferType: 'org_to_org',
    transferredToOrgId: toOrgId,
    actorUserId,
    notes,
  });
  await setOrgGuardianAndCare(db, pet.id, toOrgId);
  await clearOrgPetHomeHiddenForPet(db, pet.id);
}

export async function completeReturnToOrg(db, { pet, toOrgId, actorUserId }) {
  await deleteShadowForPetAndOrg(db, pet.id, toOrgId);
  await setOrgGuardianAndCare(db, pet.id, toOrgId);
  await clearOrgPetHomeHiddenForPet(db, pet.id);
}
