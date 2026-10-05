import { checkDueNotifications } from '../lib/checkDueNotifications.js';

function buildPool({ entries = [], recipients = ['user-1'], prefs = {} } = {}) {
  return {
    query: async (sql, params) => {
      const text = String(sql);
      if (text.includes('FROM health_entries')) {
        return { rows: entries };
      }
      if (text.includes('notification_preferences')) {
        const rows = Object.entries(prefs).map(([preference, value]) => ({
          preference,
          value: String(value),
        }));
        return { rows };
      }
      if (text.includes('SELECT p.user_id FROM pets p')) {
        return { rows: recipients.map((user_id) => ({ user_id })) };
      }
      if (text.includes('INSERT INTO notifications')) {
        throw new Error('checkDueNotifications must not insert inbox rows');
      }
      return { rows: [] };
    },
  };
}

describe('checkDueNotifications (v2 inbox)', () => {
  it('does not insert overdue or due_soon inbox rows', async () => {
    const pool = buildPool({
      entries: [{
        id: 'he-1',
        pet_id: 'pet-1',
        name: 'Vaccination',
        next_due_date: '2020-01-01',
        remind_days_before: 1,
        pet_name: 'Bella',
        pet_home_timezone: 'UTC',
      }],
      recipients: ['user-1'],
    });
    const result = await checkDueNotifications(pool, 'user-1', {}, {
      clock: { todayIso: '2026-01-01', nowTimeIso: '12:00:00' },
    });
    expect(result).toEqual({ checked: true, created: 0 });
  });
});
