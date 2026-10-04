import { tryLinkInviteContact } from '../../../lib/people/inviteContactLink.js';

describe('tryLinkInviteContact', () => {
  it('links when contact has no linked_user_id', async () => {
    const updates = [];
    const pool = {
      query: async (sql, params) => {
        if (sql.includes('SELECT linked_user_id')) {
          return { rows: [{ linked_user_id: null }] };
        }
        if (sql.includes('UPDATE people_contacts')) {
          updates.push(params);
          return { rows: [] };
        }
        return { rows: [] };
      },
    };

    const result = await tryLinkInviteContact(pool, 'contact-1', 'user-1', {
      inviteId: 'invite-1',
      source: 'pet_share',
    });
    expect(result.linked).toBe(true);
    expect(updates).toHaveLength(1);
  });

  it('skips when contact is linked to a different user', async () => {
    const updates = [];
    const pool = {
      query: async (sql) => {
        if (sql.includes('SELECT linked_user_id')) {
          return { rows: [{ linked_user_id: 'other-user' }] };
        }
        if (sql.includes('UPDATE people_contacts')) {
          updates.push(true);
          return { rows: [] };
        }
        return { rows: [] };
      },
    };

    const result = await tryLinkInviteContact(pool, 'contact-1', 'user-1', {
      inviteId: 'invite-1',
      source: 'household',
    });
    expect(result.skipped).toBe(true);
    expect(updates).toHaveLength(0);
  });
});
