import { v4 as uuidv4 } from 'uuid';

import {
  deactivateOrDeleteContactForVet,
  linkContactLegacyVet,
  upsertContactFromVetFields,
} from './contactsRepo.js';

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

/**
 * Create or update people_contact linked to a vet row.
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} vetRow vets RETURNING row
 * @param {string} userId
 */
export async function upsertContactFromVet(pool, vetRow, userId) {
  if (!vetRow?.id || !userId) return null;
  const fields = vetToContactFields(vetRow);
  return upsertContactFromVetFields(pool, {
    ...fields,
    legacy_vet_id: vetRow.id,
  }, userId);
}

/**
 * When a People contact is created with role vet, ensure a legacy vets row exists.
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} contactRow loadContactForViewer row (with roles[])
 * @param {string} userId
 */
export async function ensureLegacyVetForContact(pool, contactRow, userId) {
  if (!contactRow?.id || !userId) return null;
  const roles = contactRow.roles || [];
  if (!roles.includes('vet')) return null;
  if (contactRow.legacy_vet_id) return contactRow.legacy_vet_id;

  const vetId = uuidv4();
  const kind = contactRow.kind || 'person';
  const clinic = kind === 'organisation' ? (contactRow.name || '').trim() : '';
  const personName =
    kind === 'organisation'
      ? (contactRow.name || 'Vet').trim()
      : (contactRow.name || 'Vet').trim();

  await pool.query(
    `INSERT INTO vets (id, user_id, name, clinic, phone, email, website, address, notes, created_at, updated_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())`,
    [
      vetId,
      userId,
      personName,
      clinic,
      contactRow.phone || null,
      contactRow.email || null,
      contactRow.website || '',
      contactRow.address || '',
      '',
    ],
  );

  await linkContactLegacyVet(pool, contactRow.id, vetId);

  return vetId;
}

/**
 * Push People contact fields onto the linked legacy vets row.
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} contactRow loadContactForViewer row
 * @param {string} userId
 */
export async function syncVetRowFromContact(pool, contactRow, userId) {
  const legacyVetId = contactRow.legacy_vet_id;
  if (!legacyVetId || !userId) return;

  const existing = await pool.query(
    'SELECT name FROM vets WHERE id = $1 AND user_id = $2',
    [legacyVetId, userId],
  );
  if (existing.rows.length === 0) return;

  const kind = contactRow.kind || 'person';
  const clinic = kind === 'organisation' ? (contactRow.name || '').trim() : '';
  const name =
    kind === 'organisation'
      ? (existing.rows[0].name || contactRow.name || '').trim()
      : (contactRow.name || '').trim();

  await pool.query(
    `UPDATE vets
     SET name = $1, clinic = $2, phone = $3, email = $4, address = $5, website = $6,
         updated_at = NOW()
     WHERE id = $7 AND user_id = $8`,
    [
      name || 'Vet',
      clinic,
      contactRow.phone || null,
      contactRow.email || null,
      contactRow.address || '',
      contactRow.website || '',
      legacyVetId,
      userId,
    ],
  );
}

export async function deleteContactForVet(pool, vetId) {
  await deactivateOrDeleteContactForVet(pool, vetId);
}

/**
 * Remove the legacy vets row when an unused vet-linked contact is deleted (B3).
 * @param {import('pg').Pool|import('pg').PoolClient} client
 * @param {string} legacyVetId
 * @param {string} userId
 */
export async function deleteLegacyVetRowForContact(client, legacyVetId, userId) {
  if (!legacyVetId || !userId) return;
  await client.query('DELETE FROM vets WHERE id = $1 AND user_id = $2', [legacyVetId, userId]);
}
