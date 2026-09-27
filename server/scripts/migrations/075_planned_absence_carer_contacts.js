import { v4 as uuidv4 } from 'uuid';

import { formatCarerCandidateDisplayName } from '../../lib/care/plannedAbsence.js';
import { ensurePersonalDirectory } from '../../lib/people/directory.js';

/**
 * Dedupe key for note_only → contact (same creator, name, private note).
 * @param {string} ownerUserId
 * @param {string} name
 * @param {string|null|undefined} note
 */
function noteOnlyContactKey(ownerUserId, name, note) {
  return `${ownerUserId}|${name}|${note ?? ''}`;
}

/**
 * @param {import('pg').PoolClient} client
 * @param {string} ownerUserId
 * @param {string} name
 * @param {string|null|undefined} note
 * @param {Map<string, string>} cache
 */
async function findOrCreateNoteOnlyContact(client, ownerUserId, name, note, cache) {
  const key = noteOnlyContactKey(ownerUserId, name, note);
  const cached = cache.get(key);
  if (cached) return cached;

  const directoryId = await ensurePersonalDirectory(client, ownerUserId);
  const existing = await client.query(
    `SELECT pc.id
     FROM people_contacts pc
     INNER JOIN people_contact_private_notes pcpn
       ON pcpn.contact_id = pc.id AND pcpn.user_id = $2
     WHERE pc.directory_id = $1
       AND pc.kind = 'person'
       AND pc.name = $3
       AND COALESCE(pcpn.note, '') = COALESCE($4, '')
     LIMIT 1`,
    [directoryId, ownerUserId, name, note ?? ''],
  );
  if (existing.rows.length > 0) {
    cache.set(key, existing.rows[0].id);
    return existing.rows[0].id;
  }

  const contactId = uuidv4();
  await client.query(
    `INSERT INTO people_contacts (
       id, directory_id, kind, name, created_at, updated_at
     ) VALUES ($1, $2, 'person', $3, NOW(), NOW())`,
    [contactId, directoryId, name],
  );
  await client.query(
    `INSERT INTO people_contact_roles (contact_id, role) VALUES ($1, 'sitter')`,
    [contactId],
  );
  if (note != null && note !== '') {
    await client.query(
      `INSERT INTO people_contact_private_notes (contact_id, user_id, note, updated_at)
       VALUES ($1, $2, $3, NOW())`,
      [contactId, ownerUserId, note],
    );
  }
  cache.set(key, contactId);
  return contactId;
}

/**
 * @param {import('pg').PoolClient} client
 * @param {string} ownerUserId
 * @param {string} linkedUserId
 * @param {Map<string, string>} cacheByUser
 */
async function findOrCreateLinkedUserContact(client, ownerUserId, linkedUserId, cacheByUser) {
  const cached = cacheByUser.get(`${ownerUserId}|${linkedUserId}`);
  if (cached) return cached;

  const directoryId = await ensurePersonalDirectory(client, ownerUserId);
  const existing = await client.query(
    `SELECT id FROM people_contacts
     WHERE directory_id = $1 AND linked_user_id = $2
     LIMIT 1`,
    [directoryId, linkedUserId],
  );
  if (existing.rows.length > 0) {
    cacheByUser.set(`${ownerUserId}|${linkedUserId}`, existing.rows[0].id);
    return existing.rows[0].id;
  }

  const userRow = await client.query(
    'SELECT id, first_name, last_name, email FROM users WHERE id = $1',
    [linkedUserId],
  );
  const displayName = userRow.rows[0]
    ? formatCarerCandidateDisplayName(userRow.rows[0])
    : 'User';

  const contactId = uuidv4();
  await client.query(
    `INSERT INTO people_contacts (
       id, directory_id, kind, name, linked_user_id, created_at, updated_at
     ) VALUES ($1, $2, 'person', $3, $4, NOW(), NOW())`,
    [contactId, directoryId, displayName, linkedUserId],
  );
  await client.query(
    `INSERT INTO people_contact_roles (contact_id, role) VALUES ($1, 'sitter')`,
    [contactId],
  );
  cacheByUser.set(`${ownerUserId}|${linkedUserId}`, contactId);
  return contactId;
}

/**
 * Migrate legacy note_only / shared_user rows to directory contacts.
 * @param {import('pg').PoolClient} client
 */
export async function migratePlannedAbsenceCarerContacts(client) {
  const rows = await client.query(
    `SELECT pap.planned_absence_id, pap.pet_id, pap.carer_kind,
            pap.carer_user_id, pap.carer_name, pap.carer_note, pap.contact_id,
            pa.user_id AS absence_owner_id
     FROM planned_absence_pets pap
     INNER JOIN planned_absences pa ON pa.id = pap.planned_absence_id
     WHERE pap.carer_kind IS NOT NULL
       AND pap.contact_id IS NULL`,
  );

  const noteCache = new Map();
  const linkedCache = new Map();

  for (const row of rows.rows) {
    if (row.carer_kind === 'shared_user' && !row.carer_user_id) {
      continue;
    }

    let contactId = null;
    if (row.carer_kind === 'note_only') {
      const name = (row.carer_name || '').trim();
      if (!name) continue;
      contactId = await findOrCreateNoteOnlyContact(
        client,
        row.absence_owner_id,
        name,
        row.carer_note,
        noteCache,
      );
    } else if (row.carer_kind === 'shared_user' && row.carer_user_id) {
      contactId = await findOrCreateLinkedUserContact(
        client,
        row.absence_owner_id,
        row.carer_user_id,
        linkedCache,
      );
    }

    if (!contactId) continue;

    await client.query(
      `UPDATE planned_absence_pets
       SET contact_id = $1
       WHERE planned_absence_id = $2 AND pet_id = $3`,
      [contactId, row.planned_absence_id, row.pet_id],
    );
  }
}
