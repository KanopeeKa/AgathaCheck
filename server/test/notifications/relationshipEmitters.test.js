import {
  emitCareAssignmentAssigned,
  emitHouseholdMemberJoined,
  emitShareAccessChanged,
  NOTIFICATION_TYPE_CARE_ASSIGNMENT_ASSIGNED,
  NOTIFICATION_TYPE_HOUSEHOLD_MEMBER_JOINED,
  NOTIFICATION_TYPE_SHARE_ACCESS_CHANGED,
} from '../../lib/notifications/relationshipEmitters.js';

describe('relationshipEmitters', () => {
  it('emitShareAccessChanged inserts R5 for target user', async () => {
    const inserts = [];
    const pool = {
      query: jest.fn(async (sql, params) => {
        if (sql.includes('INSERT INTO notifications')) {
          inserts.push({ sql, params });
          return { rows: [] };
        }
        if (sql.includes('FROM users')) {
          return { rows: [{ first_name: 'Marie', last_name: 'D', email: 'm@x.com' }] };
        }
        return { rows: [] };
      }),
    };

    await emitShareAccessChanged(pool, {
      targetUserId: 'target-1',
      petId: 'pet-1',
      petName: 'Luna',
      actorUserId: 'actor-1',
      nextRole: 'carer',
    });

    expect(inserts.length).toBe(1);
    expect(inserts[0].params[8]).toBe(NOTIFICATION_TYPE_SHARE_ACCESS_CHANGED);
    expect(inserts[0].params[1]).toBe('target-1');
  });

  it('emitHouseholdMemberJoined notifies existing members only', async () => {
    const userIds = [];
    const pool = {
      query: jest.fn(async (sql, params) => {
        if (sql.includes('FROM household_members')) {
          return { rows: [{ user_id: 'a' }, { user_id: 'b' }, { user_id: 'new' }] };
        }
        if (sql.includes('FROM households')) {
          return { rows: [{ name: 'Dupont' }] };
        }
        if (sql.includes('INSERT INTO notifications')) {
          userIds.push(params[1]);
          return { rows: [] };
        }
        if (sql.includes('FROM users')) {
          return { rows: [{ first_name: 'Paul', last_name: '', email: 'p@x.com' }] };
        }
        return { rows: [] };
      }),
    };

    await emitHouseholdMemberJoined(pool, {
      householdId: 'hh-1',
      memberUserId: 'new',
    });

    expect(userIds.sort()).toEqual(['a', 'b']);
  });

  it('emitCareAssignmentAssigned notifies assignee', async () => {
    const inserts = [];
    const pool = {
      query: jest.fn(async (sql, params) => {
        if (sql.includes('INSERT INTO notifications')) {
          inserts.push(params);
          return { rows: [] };
        }
        if (sql.includes('FROM users')) {
          return { rows: [{ first_name: 'Marie', last_name: '', email: 'm@x.com' }] };
        }
        return { rows: [] };
      }),
    };

    await emitCareAssignmentAssigned(pool, {
      assigneeUserId: 'carer-1',
      actorUserId: 'owner-1',
      petId: 'pet-1',
      petName: 'Luna',
      startsOn: '2026-10-12',
      endsOn: '2026-10-19',
    });

    expect(inserts.length).toBe(1);
    expect(inserts[0][8]).toBe(NOTIFICATION_TYPE_CARE_ASSIGNMENT_ASSIGNED);
    expect(inserts[0][7]).toContain('2026-10-12');
    expect(inserts[0][7]).toContain('2026-10-19');
  });
});
