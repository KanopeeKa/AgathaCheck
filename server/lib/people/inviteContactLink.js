import { linkContactToUser } from './contactsRepo.js';

/**
 * Structured invite logs (ids only, no PII).
 * @param {string} event
 * @param {Record<string, string | undefined>} fields
 */
export function logPeopleInviteEvent(event, fields) {
  const payload = { component: 'people_invite', event };
  for (const [key, value] of Object.entries(fields)) {
    if (value != null && value !== '') {
      payload[key] = value;
    }
  }
  console.info(JSON.stringify(payload));
}

/**
 * Link invite contact to accepter when unlinked; skip when linked to someone else.
 *
 * @param {import('pg').Pool|import('pg').PoolClient} db
 * @param {string|null|undefined} contactId
 * @param {string} userId
 * @param {{ inviteId: string, source: 'pet_share' | 'household' }} meta
 */
export async function tryLinkInviteContact(db, contactId, userId, { inviteId, source }) {
  if (!contactId) return { linked: false, skipped: false };

  const result = await db.query(
    'SELECT linked_user_id FROM people_contacts WHERE id = $1',
    [contactId],
  );
  const row = result.rows[0];
  if (!row) return { linked: false, skipped: false };

  if (row.linked_user_id == null) {
    await linkContactToUser(db, contactId, userId);
    logPeopleInviteEvent('invite_contact_linked', {
      invite_id: inviteId,
      contact_id: contactId,
      user_id: userId,
      source,
    });
    return { linked: true, skipped: false };
  }

  if (row.linked_user_id === userId) {
    return { linked: false, skipped: false };
  }

  logPeopleInviteEvent('invite_contact_link_skipped', {
    invite_id: inviteId,
    contact_id: contactId,
    user_id: userId,
    source,
  });
  return { linked: false, skipped: true };
}
