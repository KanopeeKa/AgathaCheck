import { v4 as uuidv4 } from 'uuid';

/**
 * Low-level SQL writes for People tables — import only from contactsRepo.js.
 */

export async function ensurePersonalDirectory(pool, userId) {
  const existing = await pool.query(
    'SELECT id FROM people_directories WHERE owner_user_id = $1',
    [userId],
  );
  if (existing.rows.length > 0) return existing.rows[0].id;

  const id = uuidv4();
  const inserted = await pool.query(
    `INSERT INTO people_directories (id, owner_user_id, created_at, updated_at)
     VALUES ($1, $2, NOW(), NOW())
     ON CONFLICT (owner_user_id) WHERE (owner_user_id IS NOT NULL) DO UPDATE
       SET updated_at = people_directories.updated_at
     RETURNING id`,
    [id, userId],
  );
  return inserted.rows[0].id;
}

export async function insertContactRow(client, fields) {
  await client.query(
    `INSERT INTO people_contacts (
       id, directory_id, kind, name, phone, email, address, website,
       works_at_contact_id, linked_user_id, legacy_vet_id, inactive_at,
       created_at, updated_at
     ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW(), NOW())`,
    [
      fields.id,
      fields.directory_id,
      fields.kind,
      fields.name,
      fields.phone ?? null,
      fields.email ?? null,
      fields.address ?? null,
      fields.website ?? null,
      fields.works_at_contact_id ?? null,
      fields.linked_user_id ?? null,
      fields.legacy_vet_id ?? null,
      fields.inactive_at ?? null,
    ],
  );
}

export async function updateContactRow(client, contactId, fields) {
  await client.query(
    `UPDATE people_contacts SET
       kind = COALESCE($1, kind),
       name = COALESCE($2, name),
       phone = $3,
       email = $4,
       address = $5,
       website = $6,
       works_at_contact_id = $7,
       inactive_at = $8,
       legacy_vet_id = COALESCE($9, legacy_vet_id),
       linked_user_id = COALESCE($10, linked_user_id),
       updated_at = NOW()
     WHERE id = $11`,
    [
      fields.kind ?? null,
      fields.name ?? null,
      fields.phone,
      fields.email,
      fields.address,
      fields.website,
      fields.works_at_contact_id,
      fields.inactive_at,
      fields.legacy_vet_id ?? null,
      fields.linked_user_id ?? null,
      contactId,
    ],
  );
}

export async function updateContactIdentityFromVet(pool, contactId, fields) {
  await pool.query(
    `UPDATE people_contacts
     SET name = $1, phone = $2, email = $3, website = $4, address = $5,
         updated_at = NOW()
     WHERE id = $6`,
    [
      fields.name,
      fields.phone,
      fields.email,
      fields.website,
      fields.address,
      contactId,
    ],
  );
}

export async function replaceContactRoles(client, contactId, roles) {
  await client.query('DELETE FROM people_contact_roles WHERE contact_id = $1', [contactId]);
  for (const role of roles) {
    await insertContactRole(client, contactId, role);
  }
}

export async function insertContactRole(client, contactId, role, { onConflict = false } = {}) {
  const suffix = onConflict ? ' ON CONFLICT DO NOTHING' : '';
  await client.query(
    `INSERT INTO people_contact_roles (contact_id, role) VALUES ($1, $2)${suffix}`,
    [contactId, role],
  );
}

export async function upsertPrivateNote(client, contactId, userId, note) {
  await client.query(
    `INSERT INTO people_contact_private_notes (contact_id, user_id, note, updated_at)
     VALUES ($1, $2, $3, NOW())
     ON CONFLICT (contact_id, user_id)
     DO UPDATE SET note = EXCLUDED.note, updated_at = NOW()`,
    [contactId, userId, String(note)],
  );
}

export async function insertPrivateNote(client, contactId, userId, note) {
  await client.query(
    `INSERT INTO people_contact_private_notes (contact_id, user_id, note, updated_at)
     VALUES ($1, $2, $3, NOW())`,
    [contactId, userId, note],
  );
}

export async function deleteContactRow(client, contactId) {
  await client.query('DELETE FROM people_contacts WHERE id = $1', [contactId]);
}

export async function deactivateContactRow(client, contactId) {
  await client.query(
    'UPDATE people_contacts SET inactive_at = NOW(), updated_at = NOW() WHERE id = $1',
    [contactId],
  );
}

export async function linkContactLegacyVet(client, contactId, vetId) {
  await client.query(
    'UPDATE people_contacts SET legacy_vet_id = $1, updated_at = NOW() WHERE id = $2',
    [vetId, contactId],
  );
}

export async function linkContactToUser(client, contactId, userId) {
  await client.query(
    `UPDATE people_contacts
     SET linked_user_id = $2, updated_at = NOW()
     WHERE id = $1 AND linked_user_id IS NULL`,
    [contactId, userId],
  );
}
