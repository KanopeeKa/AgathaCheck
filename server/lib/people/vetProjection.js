import { v4 as uuidv4 } from 'uuid';

import { withTransaction } from '../db/withTransaction.js';
import { loadContactForViewer } from './contactMapping.js';
import {
  deactivateOrDeleteContactForVet,
  upsertContactFromVetFields,
} from './contactsRepo.js';
import { linkContactLegacyVet } from './contactsRepoSql.js';

function vetToContactFields(vetRow) {
  const clinic = (vetRow.clinic || '').trim();
  const personName = (vetRow.name || '').trim();
  const kind = clinic ? 'organisation' : 'person';
  const name = clinic || personName || 'Vet';
  const privateNote = (vetRow.notes || '').trim();
  return {
    kind,
    name,
    phone: vetRow.phone || null,
    email: vetRow.email || null,
    website: vetRow.website || '',
    address: vetRow.address || '',
    privateNote,
  };
}

function vetDisplayFields(contactRow, existingVetName = null) {
  const kind = contactRow.kind || 'person';
  const clinic = kind === 'organisation' ? (contactRow.name || '').trim() : '';
  const name = kind === 'organisation'
    ? (existingVetName || contactRow.name || 'Vet').trim()
    : (contactRow.name || '').trim();
  return { name: name || 'Vet', clinic };
}

/**
 * Write or update the legacy vets row for a vet contact (only writer for vets table).
 * @param {import('pg').PoolClient} client
 * @param {object} contactRow loadContactForViewer row (roles[], legacy_vet_id)
 * @param {string} userId
 * @param {{ organization_id?: string|null, notes?: string, existingVetName?: string }} [opts]
 * @returns {Promise<string|null>} legacy vet id
 */
export async function upsertVetRowForContact(client, contactRow, userId, opts = {}) {
  if (!contactRow?.id || !userId) return null;
  const roles = contactRow.roles || [];
  if (!roles.includes('vet') && !contactRow.legacy_vet_id) return null;

  let legacyVetId = contactRow.legacy_vet_id;
  const organizationId = opts.organization_id ?? opts.organizationId ?? null;
  const notes = opts.notes ?? '';
  const { name, clinic } = vetDisplayFields(contactRow, opts.existingVetName);

  if (!legacyVetId) {
    legacyVetId = uuidv4();
    await client.query(
      `INSERT INTO vets (
         id, user_id, name, clinic, phone, email, website, address, notes,
         organization_id, created_at, updated_at
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW(), NOW())`,
      [
        legacyVetId,
        userId,
        name,
        clinic,
        contactRow.phone || null,
        contactRow.email || null,
        contactRow.website || '',
        contactRow.address || '',
        notes,
        organizationId,
      ],
    );
    await linkContactLegacyVet(client, contactRow.id, legacyVetId);
    return legacyVetId;
  }

  const existing = await client.query(
    'SELECT name FROM vets WHERE id = $1 AND user_id = $2',
    [legacyVetId, userId],
  );
  const existingName = existing.rows[0]?.name;
  const fields = vetDisplayFields(contactRow, existingName);

  await client.query(
    `UPDATE vets
     SET name = $1, clinic = $2, phone = $3, email = $4, address = $5, website = $6,
         organization_id = COALESCE($7, organization_id), updated_at = NOW()
     WHERE id = $8 AND user_id = $9`,
    [
      fields.name,
      fields.clinic,
      contactRow.phone || null,
      contactRow.email || null,
      contactRow.address || '',
      contactRow.website || '',
      organizationId,
      legacyVetId,
      userId,
    ],
  );
  return legacyVetId;
}

/**
 * @param {import('pg').PoolClient} client
 * @param {string} legacyVetId
 * @param {string} userId
 */
export async function deleteVetRowForContact(client, legacyVetId, userId) {
  if (!legacyVetId || !userId) return;
  await client.query('DELETE FROM vets WHERE id = $1 AND user_id = $2', [legacyVetId, userId]);
}

/**
 * Sync pets.vet_id from the active primary_vet relationship (I5).
 * @param {import('pg').Pool|import('pg').PoolClient} db
 * @param {string} petId
 */
export async function projectPet(db, petId) {
  const slot = await db.query(
    `SELECT p.user_id AS owner_user_id, pc.id AS contact_id
     FROM pets p
     LEFT JOIN pet_contact_relationships pcr
       ON pcr.pet_id = p.id
      AND pcr.relationship_kind = 'primary_vet'
      AND pcr.active = true
     LEFT JOIN people_contacts pc ON pc.id = pcr.contact_id
     WHERE p.id = $1
     ORDER BY pcr.updated_at DESC NULLS LAST
     LIMIT 1`,
    [petId],
  );
  const row = slot.rows[0];
  if (!row) return;

  let legacyVetId = null;
  if (row.contact_id && row.owner_user_id) {
    let contact = await loadContactForViewer(db, row.contact_id, row.owner_user_id);
    if (contact) {
      legacyVetId = contact.legacy_vet_id;
      if (!legacyVetId) {
        legacyVetId = await upsertVetRowForContact(db, contact, row.owner_user_id);
      }
    }
  }

  await db.query(
    'UPDATE pets SET vet_id = $1, updated_at = NOW() WHERE id = $2',
    [legacyVetId, petId],
  );
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} contactId
 * @param {string} userId
 */
export async function projectContact(pool, contactId, userId) {
  const contact = await loadContactForViewer(pool, contactId, userId);
  if (!contact) return;

  await withTransaction(pool, async (client) => {
    await upsertVetRowForContact(client, contact, userId);
    const pets = await client.query(
      `SELECT DISTINCT pet_id FROM pet_contact_relationships
       WHERE contact_id = $1 AND relationship_kind = 'primary_vet' AND active = true`,
      [contactId],
    );
    for (const { pet_id } of pets.rows) {
      await projectPet(client, pet_id);
    }
  });
}

function vetRowToMap(row) {
  return {
    id: row.id,
    user_id: row.user_id,
    name: row.name,
    clinic: row.clinic,
    phone: row.phone,
    email: row.email,
    website: row.website || '',
    address: row.address || '',
    notes: row.notes || '',
    organization_id: row.organization_id ?? null,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

/**
 * Compat POST /api/vets — contact is authoritative; vets row is projection.
 */
export async function createCompatVet(pool, userId, body) {
  const id = uuidv4();
  const vetPayload = {
    id,
    user_id: userId,
    name: body.name,
    clinic: body.clinic || null,
    phone: body.phone || null,
    email: body.email || null,
    website: body.website || '',
    address: body.address || '',
    notes: body.notes || '',
    organization_id: body.organization_id ?? body.organizationId ?? null,
  };
  const fields = vetToContactFields(vetPayload);

  await withTransaction(pool, async (client) => {
    await client.query(
      `INSERT INTO vets (
         id, user_id, name, clinic, phone, email, website, address, notes,
         organization_id, created_at, updated_at
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW(), NOW())`,
      [
        id,
        userId,
        vetPayload.name,
        vetPayload.clinic,
        fields.phone,
        fields.email,
        fields.website,
        fields.address,
        vetPayload.notes,
        vetPayload.organization_id,
      ],
    );
    await upsertContactFromVetFields(client, {
      ...fields,
      legacy_vet_id: id,
    }, userId);
  });

  const result = await pool.query(
    'SELECT * FROM vets WHERE id = $1 AND user_id = $2',
    [id, userId],
  );
  return result.rows[0] ? vetRowToMap(result.rows[0]) : null;
}

/**
 * Compat PUT /api/vets/:id
 */
export async function updateCompatVet(pool, userId, vetId, body) {
  const existing = await pool.query(
    'SELECT * FROM vets WHERE id = $1 AND user_id = $2',
    [vetId, userId],
  );
  if (existing.rows.length === 0) return null;

  const merged = {
    ...existing.rows[0],
    name: body.name,
    clinic: body.clinic,
    phone: body.phone,
    email: body.email,
    website: body.website ?? existing.rows[0].website,
    address: body.address ?? existing.rows[0].address,
    notes: body.notes ?? existing.rows[0].notes,
    organization_id: body.organization_id ?? body.organizationId ?? existing.rows[0].organization_id,
  };

  const fields = vetToContactFields(merged);
  await upsertContactFromVetFields(pool, {
    ...fields,
    legacy_vet_id: vetId,
  }, userId);

  let updatedRow = null;
  await withTransaction(pool, async (client) => {
    const result = await client.query(
      `UPDATE vets
       SET name = $1, clinic = $2, phone = $3, email = $4, website = $5, address = $6,
           notes = $7, organization_id = $8, updated_at = NOW()
       WHERE id = $9 AND user_id = $10
       RETURNING *`,
      [
        merged.name,
        merged.clinic,
        merged.phone,
        merged.email,
        merged.website || '',
        merged.address || '',
        merged.notes || '',
        merged.organization_id,
        vetId,
        userId,
      ],
    );
    updatedRow = result.rows[0] ?? null;
  });

  return updatedRow ? vetRowToMap(updatedRow) : null;
}

/**
 * Compat DELETE /api/vets/:id — clears projections and contact when unused.
 */
export async function deleteCompatVet(pool, userId, vetId) {
  const owned = await pool.query(
    'SELECT id FROM vets WHERE id = $1 AND user_id = $2',
    [vetId, userId],
  );
  if (owned.rows.length === 0) return false;

  const contact = await pool.query(
    'SELECT id FROM people_contacts WHERE legacy_vet_id = $1',
    [vetId],
  );
  const contactId = contact.rows[0]?.id;

  if (contactId) {
    const pets = await pool.query(
      `SELECT pet_id FROM pet_contact_relationships
       WHERE contact_id = $1 AND relationship_kind = 'primary_vet' AND active = true`,
      [contactId],
    );
    await withTransaction(pool, async (client) => {
      await client.query(
        `UPDATE pet_contact_relationships
         SET active = false, updated_at = NOW()
         WHERE contact_id = $1 AND relationship_kind = 'primary_vet' AND active = true`,
        [contactId],
      );
      for (const { pet_id } of pets.rows) {
        await projectPet(client, pet_id);
      }
    });
  }

  await deactivateOrDeleteContactForVet(pool, vetId);
  await deleteVetRowForContact(pool, vetId, userId);
  return true;
}

/**
 * Idempotent People → vets + pets.vet_id repair (replaces reconcilePeopleVets).
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 */
export async function rebuildAll(pool) {
  const vetContacts = await pool.query(
    `SELECT DISTINCT pc.id, pd.owner_user_id AS user_id
     FROM people_contacts pc
     INNER JOIN people_directories pd ON pd.id = pc.directory_id
     INNER JOIN people_contact_roles pcr ON pcr.contact_id = pc.id AND pcr.role = 'vet'
     ORDER BY pc.created_at, pc.id`,
  );

  for (const row of vetContacts.rows) {
    await projectContact(pool, row.id, row.user_id);
  }

  const legacyVets = await pool.query(
    `SELECT v.* FROM vets v
     WHERE v.user_id IS NOT NULL
     ORDER BY v.created_at, v.id`,
  );
  for (const vet of legacyVets.rows) {
    const fields = vetToContactFields(vet);
    await upsertContactFromVetFields(pool, { ...fields, legacy_vet_id: vet.id }, vet.user_id);
  }

  const petsNeedingLink = await pool.query(
    `SELECT p.id AS pet_id, p.vet_id, p.user_id AS owner_user_id
     FROM pets p
     WHERE p.vet_id IS NOT NULL
       AND NOT EXISTS (
         SELECT 1 FROM pet_contact_relationships pcr
         WHERE pcr.pet_id = p.id
           AND pcr.relationship_kind = 'primary_vet'
           AND pcr.active = true
       )`,
  );

  for (const pet of petsNeedingLink.rows) {
    const contact = await pool.query(
      'SELECT id FROM people_contacts WHERE legacy_vet_id = $1',
      [pet.vet_id],
    );
    const contactId = contact.rows[0]?.id;
    if (!contactId) continue;

    await withTransaction(pool, async (client) => {
      await client.query(
        `UPDATE pet_contact_relationships
         SET active = false, updated_at = NOW()
         WHERE pet_id = $1 AND relationship_kind = 'primary_vet' AND active = true`,
        [pet.pet_id],
      );
      const existing = await client.query(
        `SELECT id FROM pet_contact_relationships
         WHERE pet_id = $1 AND contact_id = $2 AND relationship_kind = 'primary_vet'`,
        [pet.pet_id, contactId],
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
           ) VALUES ($1, $2, $3, 'primary_vet', true, true, 0, NOW(), NOW())`,
          [uuidv4(), pet.pet_id, contactId],
        );
      }
    });
  }

  const allPets = await pool.query('SELECT id FROM pets');
  for (const { id } of allPets.rows) {
    await projectPet(pool, id);
  }
}

/** @deprecated use upsertVetRowForContact */
export async function ensureLegacyVetForContact(pool, contactRow, userId) {
  return upsertVetRowForContact(pool, contactRow, userId);
}

/** @deprecated use upsertVetRowForContact */
export async function syncVetRowFromContact(pool, contactRow, userId) {
  return upsertVetRowForContact(pool, contactRow, userId);
}

/** @deprecated use deleteVetRowForContact */
export async function deleteLegacyVetRowForContact(client, legacyVetId, userId) {
  return deleteVetRowForContact(client, legacyVetId, userId);
}

/**
 * Compat adapter: legacy vet id → people contact id (reads vets table).
 */
export async function contactIdForLegacyVet(pool, vetId, userId) {
  if (!vetId || !userId) return null;
  const vetResult = await pool.query(
    'SELECT * FROM vets WHERE id = $1 AND user_id = $2',
    [vetId, userId],
  );
  if (vetResult.rows.length === 0) return null;
  const vetRow = vetResult.rows[0];
  const fields = vetToContactFields(vetRow);
  return upsertContactFromVetFields(pool, {
    ...fields,
    legacy_vet_id: vetRow.id,
  }, userId);
}
