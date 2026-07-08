/**
 * Organisation pet custody transfers (Inc 7).
 */
import { createNotification, userDisplayName } from './notificationHelper.js';
import {
  requestCustodyTransfer,
  TRANSFER_INDIVIDUAL,
} from './custodyTransfers.js';
import { setOrgGuardianAndCare } from './petCustody.js';

export async function transferOrgPetToUser(
  pool,
  {
    orgId,
    petId,
    adminId,
    recipientId,
    transferType = 'adoption',
    notes = '',
  },
) {
  const petResult = await pool.query(
    'SELECT id, name, species, user_id, organization_id FROM pets WHERE id = $1 AND organization_id = $2',
    [petId, orgId],
  );
  if (petResult.rows.length === 0) {
    const err = new Error('Pet not found');
    err.statusCode = 404;
    throw err;
  }
  const pet = petResult.rows[0];

  if (recipientId === pet.user_id) {
    const err = new Error('Recipient already owns this pet');
    err.statusCode = 400;
    throw err;
  }

  const recipientResult = await pool.query(
    'SELECT id, first_name, last_name, email FROM users WHERE id = $1',
    [recipientId],
  );
  if (recipientResult.rows.length === 0) {
    const err = new Error('User not found');
    err.statusCode = 404;
    throw err;
  }
  const recipient = recipientResult.rows[0];
  const recipientName = userDisplayName(recipient);

  const result = await requestCustodyTransfer(pool, {
    petId,
    transferKind: TRANSFER_INDIVIDUAL,
    requestedByUserId: adminId,
    requestingOrgId: orgId,
    toUserId: recipientId,
    notes: notes || transferType,
  });

  return {
    pending: true,
    transfer_id: result.id,
    pet_id: petId,
    recipient_id: recipientId,
    transfer_type: transferType,
    recipient_name: recipientName,
  };
}

export async function transferPetToOrganization(
  pool,
  {
    petId,
    ownerId,
    orgId,
    transferType = 'transfer',
    notes = '',
  },
) {
  const type = transferType || 'transfer';

  const petResult = await pool.query(
    'SELECT id, name, species, user_id, organization_id FROM pets WHERE id = $1 AND user_id = $2',
    [petId, ownerId],
  );
  if (petResult.rows.length === 0) {
    const err = new Error('Pet not found');
    err.statusCode = 404;
    throw err;
  }
  const pet = petResult.rows[0];
  if (pet.organization_id) {
    const err = new Error('Pet already belongs to an organization');
    err.statusCode = 400;
    throw err;
  }

  const orgResult = await pool.query(
    `SELECT 1 FROM organization_users
     WHERE organization_id = $1 AND user_id = $2
       AND role IN ('super_admin', 'admin')
     LIMIT 1`,
    [orgId, ownerId],
  );
  if (orgResult.rows.length === 0) {
    const err = new Error('Forbidden');
    err.statusCode = 403;
    throw err;
  }

  await setOrgGuardianAndCare(pool, petId, orgId);

  return {
    transferred: true,
    pet_id: petId,
    organization_id: orgId,
    transfer_type: type,
    notes: notes || '',
  };
}
