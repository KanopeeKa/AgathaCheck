import { v4 as uuidv4 } from 'uuid';

import { ensurePersonalDirectory } from './directory.js';

function vetToContactFields(vetRow) {
  const clinic = (vetRow.clinic || '').trim();
  const personName = (vetRow.name || '').trim();
  const kind = clinic ? 'organisation' : 'person';
  const name = clinic || personName || 'Vet';
  let privateNote = (vetRow.notes || '').trim();
  if (clinic && personName) {
    const prefix = `Vet contact: ${personName}`;
    privateNote = privateNote ? `${prefix}\n${privateNote}` : prefix;
  }
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
  const directoryId = await ensurePersonalDirectory(pool, userId);
  const fields = vetToContactFields(vetRow);

  const existing = await pool.query(
    'SELECT id FROM people_contacts WHERE legacy_vet_id = $1',
    [vetRow.id],
  );

  let contactId;
  if (existing.rows.length > 0) {
    contactId = existing.rows[0].id;
    await pool.query(
      `UPDATE people_contacts
       SET kind = $1, name = $2, phone = $3, email = $4, website = $5, address = $6,
           updated_at = NOW()
       WHERE id = $7`,
      [
        fields.kind,
        fields.name,
        fields.phone,
        fields.email,
        fields.website,
        fields.address,
        contactId,
      ],
    );
  } else {
    contactId = uuidv4();
    await pool.query(
      `INSERT INTO people_contacts (
         id, directory_id, kind, name, phone, email, address, website,
         legacy_vet_id, created_at, updated_at
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())`,
      [
        contactId,
        directoryId,
        fields.kind,
        fields.name,
        fields.phone,
        fields.email,
        fields.address,
        fields.website,
        vetRow.id,
      ],
    );
    await pool.query(
      'INSERT INTO people_contact_roles (contact_id, role) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [contactId, 'vet'],
    );
  }

  await pool.query(
    `INSERT INTO people_contact_private_notes (contact_id, user_id, note, updated_at)
     VALUES ($1, $2, $3, NOW())
     ON CONFLICT (contact_id, user_id)
     DO UPDATE SET note = EXCLUDED.note, updated_at = NOW()`,
    [contactId, userId, fields.privateNote],
  );

  return contactId;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} vetId
 */
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
  if (!vetId) return;
  const contact = await pool.query(
    'SELECT id FROM people_contacts WHERE legacy_vet_id = $1',
    [vetId],
  );
  if (contact.rows.length === 0) return;
  const contactId = contact.rows[0].id;
  const inUse = await pool.query(
    'SELECT 1 FROM pet_contact_relationships WHERE contact_id = $1 LIMIT 1',
    [contactId],
  );
  if (inUse.rows.length > 0) {
    await pool.query(
      'UPDATE people_contacts SET inactive_at = NOW(), updated_at = NOW() WHERE id = $1',
      [contactId],
    );
    return;
  }
  await pool.query('DELETE FROM people_contacts WHERE id = $1', [contactId]);
}
