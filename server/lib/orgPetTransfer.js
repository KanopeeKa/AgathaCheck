/**
 * Organisation pet custody transfers (Inc 7).
 */
import { v4 as uuidv4 } from 'uuid';

import { createNotification, userDisplayName } from './notificationHelper.js';
import {
  closeActivePlacementForPet,
  PLACEMENT_STATUS_NOT_IN_FOSTER,
} from './fosterPlacements.js';

const ALLOWED_TRANSFER_TYPES = new Set([
  'adoption',
  'transfer',
  'release',
  'other',
]);

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
  const type = ALLOWED_TRANSFER_TYPES.has(transferType) ? transferType : 'other';

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

  const adminResult = await pool.query(
    'SELECT first_name, last_name, email FROM users WHERE id = $1',
    [adminId],
  );
  const adminName = userDisplayName(adminResult.rows[0] || {});
  const recipientName = userDisplayName(recipient);

  const client = typeof pool.connect === 'function' ? await pool.connect() : null;
  const db = client || pool;

  try {
    if (client) await client.query('BEGIN');

    await closeActivePlacementForPet(db, petId);

    await db.query(
      `UPDATE pets
       SET user_id = $1, organization_id = NULL, updated_at = NOW()
       WHERE id = $2`,
      [recipientId, petId],
    );

    await db.query(
      'DELETE FROM pet_access WHERE pet_id = $1 AND user_id = $2',
      [petId, recipientId],
    );

    const archiveId = uuidv4();
    await db.query(
      `INSERT INTO archived_pets (
         id, organization_id, user_id, pet_id, pet_name, species,
         transfer_type, transferred_to_user_id, notes
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
      [
        archiveId,
        orgId,
        adminId,
        petId,
        pet.name,
        pet.species || '',
        type,
        recipientId,
        notes || '',
      ],
    );

    if (client) await client.query('COMMIT');

    await createNotification(pool, {
      userId: recipientId,
      petId,
      petName: pet.name,
      title: 'Pet transferred to you',
      message: `${adminName} transferred ${pet.name} to you from the organisation.`,
      type: 'general',
    });

    return {
      transferred: true,
      pet_id: petId,
      new_owner_id: recipientId,
      transfer_type: type,
      recipient_name: recipientName,
    };
  } catch (err) {
    if (client) await client.query('ROLLBACK');
    throw err;
  } finally {
    if (client) client.release();
  }
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
  const type = ALLOWED_TRANSFER_TYPES.has(transferType) ? transferType : 'transfer';

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

  await pool.query(
    `UPDATE pets
     SET organization_id = $1, updated_at = NOW()
     WHERE id = $2`,
    [orgId, petId],
  );

  const archiveId = uuidv4();
  await pool.query(
    `INSERT INTO archived_pets (
       id, organization_id, user_id, pet_id, pet_name, species,
       transfer_type, transferred_to_org_id, notes
     ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
    [
      archiveId,
      orgId,
      ownerId,
      petId,
      pet.name,
      pet.species || '',
      type,
      orgId,
      notes || '',
    ],
  );

  return {
    transferred: true,
    pet_id: petId,
    organization_id: orgId,
    transfer_type: type,
  };
}
