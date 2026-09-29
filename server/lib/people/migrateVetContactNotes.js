import { v4 as uuidv4 } from 'uuid';

import { ensurePersonalDirectory } from './directory.js';

const VET_CONTACT_PREFIX = /^Vet contact:\s*(.+?)(?:\n|$)/;

/**
 * One-off / idempotent repair: organisation contacts with "Vet contact: Dr X" notes
 * get a linked person contact (works_at) and cleaned notes.
 *
 * @param {import('pg').Pool} pool
 * @param {string} userId
 * @returns {Promise<{ repaired: number }>}
 */
export async function migrateVetContactNotesForUser(pool, userId) {
  const directoryId = await ensurePersonalDirectory(pool, userId);
  const result = await pool.query(
    `SELECT pc.id, pc.name, pc.kind, pcpn.note
     FROM people_contacts pc
     INNER JOIN people_contact_private_notes pcpn
       ON pcpn.contact_id = pc.id AND pcpn.user_id = $2
     WHERE pc.directory_id = $1
       AND pc.kind = 'organisation'
       AND pcpn.note LIKE 'Vet contact:%'`,
    [directoryId, userId],
  );

  let repaired = 0;
  for (const row of result.rows) {
    const match = VET_CONTACT_PREFIX.exec(row.note || '');
    if (!match) continue;
    const personName = match[1].trim();
    if (!personName) continue;

    const remainder = (row.note || '').replace(VET_CONTACT_PREFIX, '').trim();

    const existingPerson = await pool.query(
      `SELECT pc.id FROM people_contacts pc
       WHERE pc.directory_id = $1
         AND pc.kind = 'person'
         AND pc.works_at_contact_id = $2
         AND lower(pc.name) = lower($3)
       LIMIT 1`,
      [directoryId, row.id, personName],
    );

    let personId = existingPerson.rows[0]?.id;
    if (!personId) {
      personId = uuidv4();
      await pool.query(
        `INSERT INTO people_contacts (
           id, directory_id, kind, name, works_at_contact_id, created_at, updated_at
         ) VALUES ($1, $2, 'person', $3, $4, NOW(), NOW())`,
        [personId, directoryId, personName, row.id],
      );
      await pool.query(
        `INSERT INTO people_contact_roles (contact_id, role) VALUES ($1, 'vet')
         ON CONFLICT DO NOTHING`,
        [personId],
      );
      if (remainder) {
        await pool.query(
          `INSERT INTO people_contact_private_notes (contact_id, user_id, note, updated_at)
           VALUES ($1, $2, $3, NOW())
           ON CONFLICT (contact_id, user_id)
           DO UPDATE SET note = EXCLUDED.note, updated_at = NOW()`,
          [personId, userId, remainder],
        );
      }
    }

    const cleanedOrgNote = remainder && !existingPerson.rows.length
      ? row.note
      : (row.note || '').replace(VET_CONTACT_PREFIX, '').trim();
    await pool.query(
      `UPDATE people_contact_private_notes
       SET note = $1, updated_at = NOW()
       WHERE contact_id = $2 AND user_id = $3`,
      [cleanedOrgNote, row.id, userId],
    );
    repaired += 1;
  }

  return { repaired };
}
