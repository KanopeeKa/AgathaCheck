import { v4 as uuidv4 } from 'uuid';

import { ensurePersonalDirectory } from '../../../lib/people/directory.js';
import { upsertContactFromVet } from '../../../lib/people/vetSync.js';

/**
 * Seed a clinic organisation contact (from legacy vet row) plus an optional
 * named vet person linked via works_at_contact_id.
 *
 * @param {import('pg').PoolClient} client
 * @param {string} userId
 * @param {object} vetRow
 * @param {{ personContactId?: string, personName?: string, organisationNote?: string, personNote?: string }} [opts]
 * @returns {Promise<{ organisationContactId: string, personContactId?: string }>}
 */
export async function seedPeopleVetClinicAndPerson(client, userId, vetRow, opts = {}) {
  const organisationContactId = await upsertContactFromVet(client, vetRow, userId);
  if (!organisationContactId) {
    return { organisationContactId: '' };
  }

  const orgNote = opts.organisationNote ?? (vetRow.notes || '').trim();
  if (orgNote) {
    await client.query(
      `INSERT INTO people_contact_private_notes (contact_id, user_id, note, updated_at)
       VALUES ($1, $2, $3, NOW())
       ON CONFLICT (contact_id, user_id)
       DO UPDATE SET note = EXCLUDED.note, updated_at = NOW()`,
      [organisationContactId, userId, orgNote],
    );
  }

  const personName = (opts.personName ?? vetRow.name ?? '').trim();
  const clinic = (vetRow.clinic || '').trim();
  if (!personName || !clinic) {
    return { organisationContactId, personContactId: undefined };
  }

  const directoryId = await ensurePersonalDirectory(client, userId);
  const personContactId = opts.personContactId || uuidv4();

  await client.query(
    `INSERT INTO people_contacts (
       id, directory_id, kind, name, phone, email, address, website,
       works_at_contact_id, created_at, updated_at
     ) VALUES ($1, $2, 'person', $3, $4, $5, $6, $7, $8, NOW(), NOW())
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       works_at_contact_id = EXCLUDED.works_at_contact_id,
       updated_at = NOW()`,
    [
      personContactId,
      directoryId,
      personName,
      vetRow.phone || null,
      vetRow.email || null,
      vetRow.address || null,
      vetRow.website || '',
      organisationContactId,
    ],
  );

  await client.query(
    'DELETE FROM people_contact_roles WHERE contact_id = $1',
    [personContactId],
  );
  await client.query(
    'INSERT INTO people_contact_roles (contact_id, role) VALUES ($1, $2)',
    [personContactId, 'vet'],
  );

  const personNote = (opts.personNote || '').trim();
  if (personNote) {
    await client.query(
      `INSERT INTO people_contact_private_notes (contact_id, user_id, note, updated_at)
       VALUES ($1, $2, $3, NOW())
       ON CONFLICT (contact_id, user_id)
       DO UPDATE SET note = EXCLUDED.note, updated_at = NOW()`,
      [personContactId, userId, personNote],
    );
  }

  return { organisationContactId, personContactId };
}
