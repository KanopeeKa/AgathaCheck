import { v4 as uuidv4 } from 'uuid';

import { withTransaction } from '../db/withTransaction.js';
import { canAttachContactToPet, getPetOwnerUserId } from './access.js';
import {
  RELATIONSHIP_KINDS,
  SLOT_RELATIONSHIP_KINDS,
} from './constants.js';
import { PeopleError, PEOPLE_ERROR_CODES } from './errors.js';
import { RELATIONSHIP_LIST_SQL, relationshipRowToMap } from './relationshipMapping.js';
import { contactIdForLegacyVet, projectPet } from './vetProjection.js';

async function assertCanAttach(pool, userId, contactId, petId) {
  if (!(await canAttachContactToPet(pool, userId, contactId, petId))) {
    throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 400, 'Contact not found');
  }
}

async function deactivateActiveSlots(client, petId, kind) {
  await client.query(
    `UPDATE pet_contact_relationships
     SET active = false, updated_at = NOW()
     WHERE pet_id = $1 AND relationship_kind = $2 AND active = true`,
    [petId, kind],
  );
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} petId
 */
export async function listForPet(pool, petId) {
  const result = await pool.query(RELATIONSHIP_LIST_SQL, [petId]);
  return result.rows.map(relationshipRowToMap);
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} petId
 * @param {string} kind primary_vet | out_of_hours_vet
 * @param {string|null} contactId null clears the slot
 * @param {string} userId
 */
export async function setSlot(pool, petId, kind, contactId, userId) {
  if (!SLOT_RELATIONSHIP_KINDS.includes(kind)) {
    throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 400, 'Invalid slot kind');
  }

  await withTransaction(pool, async (client) => {
    await deactivateActiveSlots(client, petId, kind);
    if (contactId) {
      await assertCanAttach(client, userId, contactId, petId);
      const existing = await client.query(
        `SELECT id FROM pet_contact_relationships
         WHERE pet_id = $1 AND contact_id = $2 AND relationship_kind = $3`,
        [petId, contactId, kind],
      );
      if (existing.rows.length > 0) {
        await client.query(
          `UPDATE pet_contact_relationships
           SET active = true, is_primary = true, updated_at = NOW()
           WHERE id = $1`,
          [existing.rows[0].id],
        );
      } else {
        await client.query(
          `INSERT INTO pet_contact_relationships (
             id, pet_id, contact_id, relationship_kind, is_primary, active, sort_order,
             created_at, updated_at
           ) VALUES ($1, $2, $3, $4, true, true, 0, NOW(), NOW())`,
          [uuidv4(), petId, contactId, kind],
        );
      }
    }
    if (kind === 'primary_vet') {
      await projectPet(client, petId);
    }
  });

  return listForPet(pool, petId);
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} petId
 * @param {{ contact_id: string, relationship_kind: string }} body
 * @param {string} userId
 */
export async function add(pool, petId, body, userId) {
  const kind = body.relationship_kind || body.relationshipKind;
  const contactId = body.contact_id || body.contactId;
  if (!RELATIONSHIP_KINDS.includes(kind)) {
    throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 400, `Invalid relationship_kind: ${kind}`);
  }
  if (!contactId) {
    throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 400, 'contact_id is required');
  }
  if (SLOT_RELATIONSHIP_KINDS.includes(kind)) {
    throw new PeopleError(
      PEOPLE_ERROR_CODES.SLOT_CONFLICT,
      409,
      'Use the slots endpoint for primary_vet and out_of_hours_vet',
    );
  }

  await withTransaction(pool, async (client) => {
    await assertCanAttach(client, userId, contactId, petId);
    const maxOrder = await client.query(
      `SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_order
       FROM pet_contact_relationships
       WHERE pet_id = $1 AND relationship_kind = $2`,
      [petId, kind],
    );
    const sortOrder = maxOrder.rows[0]?.next_order ?? 0;
    await client.query(
      `INSERT INTO pet_contact_relationships (
         id, pet_id, contact_id, relationship_kind, is_primary, active, sort_order,
         created_at, updated_at
       ) VALUES ($1, $2, $3, $4, false, true, $5, NOW(), NOW())`,
      [uuidv4(), petId, contactId, kind, sortOrder],
    );
  });

  return listForPet(pool, petId);
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} petId
 * @param {string} relationshipId
 * @param {string} userId
 */
export async function remove(pool, petId, relationshipId, userId) {
  let primaryCleared = false;
  await withTransaction(pool, async (client) => {
    const row = await client.query(
      `SELECT relationship_kind FROM pet_contact_relationships
       WHERE id = $1 AND pet_id = $2`,
      [relationshipId, petId],
    );
    if (row.rows.length === 0) {
      throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 404, 'Relationship not found');
    }
    const kind = row.rows[0].relationship_kind;
    await client.query('DELETE FROM pet_contact_relationships WHERE id = $1', [relationshipId]);
    primaryCleared = kind === 'primary_vet';
    if (primaryCleared) {
      await projectPet(client, petId);
    }
  });
  return listForPet(pool, petId);
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} petId
 * @param {string[]} relationshipIds ordered ids for one kind group
 */
export async function reorder(pool, petId, relationshipIds) {
  await withTransaction(pool, async (client) => {
    for (let i = 0; i < relationshipIds.length; i += 1) {
      await client.query(
        `UPDATE pet_contact_relationships
         SET sort_order = $1, updated_at = NOW()
         WHERE id = $2 AND pet_id = $3`,
        [i, relationshipIds[i], petId],
      );
    }
  });
  return listForPet(pool, petId);
}

/**
 * Legacy PUT — replace all relationships for a pet.
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} petId
 * @param {object[]} relationships normalized rows
 * @param {string} userId
 */
export async function replaceAll(pool, petId, relationships, userId) {
  const petOwnerId = await getPetOwnerUserId(pool, petId);
  if (!petOwnerId) {
    throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 404, 'Pet not found');
  }

  for (const rel of relationships) {
    await assertCanAttach(pool, userId, rel.contact_id, petId);
  }

  await withTransaction(pool, async (client) => {
    await client.query('DELETE FROM pet_contact_relationships WHERE pet_id = $1', [petId]);
    for (const rel of relationships) {
      const relId = rel.id || uuidv4();
      await client.query(
        `INSERT INTO pet_contact_relationships (
           id, pet_id, contact_id, relationship_kind, is_primary, active, sort_order,
           created_at, updated_at
         ) VALUES ($1, $2, $3, $4, $5, $6, 0, NOW(), NOW())`,
        [
          relId,
          petId,
          rel.contact_id,
          rel.relationship_kind,
          rel.is_primary,
          rel.active,
        ],
      );
    }
    await projectPet(client, petId);
  });

  return listForPet(pool, petId);
}

/**
 * Compat: pets.vet_id / legacy vet id → primary_vet relationship + projection.
 */
export async function setPrimaryVetFromLegacyVetId(pool, petId, vetId, ownerUserId) {
  if (!petId || !ownerUserId) return;

  if (!vetId) {
    await setSlot(pool, petId, 'primary_vet', null, ownerUserId);
    return;
  }

  const contactId = await contactIdForLegacyVet(pool, vetId, ownerUserId);
  if (!contactId) return;

  await setSlot(pool, petId, 'primary_vet', contactId, ownerUserId);
}

/**
 * Apply pet_links from POST /api/people/contacts in an open transaction.
 * @param {import('pg').PoolClient} client
 * @param {string} userId
 * @param {string} contactId
 * @param {object[]} petLinks
 */
export async function applyPetLinksInTransaction(client, userId, contactId, petLinks) {
  if (!Array.isArray(petLinks) || petLinks.length === 0) return;

  for (const link of petLinks) {
    const petId = link.pet_id || link.petId;
    const kind = link.relationship_kind || link.relationshipKind;
    if (!petId || !kind) {
      throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 400, 'Invalid pet_links entry');
    }
    if (!(await canAttachContactToPet(client, userId, contactId, petId))) {
      throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 400, 'Contact not attachable to pet');
    }
    if (SLOT_RELATIONSHIP_KINDS.includes(kind)) {
      await deactivateActiveSlots(client, petId, kind);
      const existing = await client.query(
        `SELECT id FROM pet_contact_relationships
         WHERE pet_id = $1 AND contact_id = $2 AND relationship_kind = $3`,
        [petId, contactId, kind],
      );
      if (existing.rows.length > 0) {
        await client.query(
          `UPDATE pet_contact_relationships
           SET active = true, is_primary = true, updated_at = NOW()
           WHERE id = $1`,
          [existing.rows[0].id],
        );
      } else {
        await client.query(
          `INSERT INTO pet_contact_relationships (
             id, pet_id, contact_id, relationship_kind, is_primary, active, sort_order,
             created_at, updated_at
           ) VALUES ($1, $2, $3, $4, true, true, 0, NOW(), NOW())`,
          [uuidv4(), petId, contactId, kind],
        );
      }
      if (kind === 'primary_vet') {
        await projectPet(client, petId);
      }
    } else if (RELATIONSHIP_KINDS.includes(kind)) {
      await client.query(
        `INSERT INTO pet_contact_relationships (
           id, pet_id, contact_id, relationship_kind, is_primary, active, sort_order,
           created_at, updated_at
         ) VALUES ($1, $2, $3, $4, false, true, 0, NOW(), NOW())`,
        [uuidv4(), petId, contactId, kind],
      );
    } else {
      throw new PeopleError(PEOPLE_ERROR_CODES.VALIDATION_FAILED, 400, `Invalid relationship_kind: ${kind}`);
    }
  }
}
