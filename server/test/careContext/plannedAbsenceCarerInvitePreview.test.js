import request from 'supertest';

import { createApp } from '../../bin/server.js';
import { createMockPool } from '../pets/helpers.js';

describe('planned absence carer invite preview', () => {
  it('GET /api/planned-absences/carer-invites/code/:code includes absence title', async () => {
    const app = createApp(createMockPool(async (sql) => {
        if (sql.includes('planned_absence_carer_invites i')
          && sql.includes('WHERE i.code = $1')) {
          return {
            rows: [{
              id: 'invite-1',
              code: 'testcode',
              inviter_user_id: 'user-inviter',
              invitee_email: 'carer@example.com',
              status: 'pending',
              expires_at: new Date('2099-01-01T00:00:00.000Z'),
              starts_on: '2026-11-01',
              ends_on: '2026-11-07',
              timezone: 'UTC',
              title: 'Ski week',
              absence_status: 'active',
            }],
          };
        }
        if (sql.includes('planned_absence_carer_invite_pets')) {
          return { rows: [{ pet_id: 'pet-1' }] };
        }
        if (sql.includes('FROM users WHERE id = $1')) {
          return {
            rows: [{ id: 'user-inviter', first_name: 'Alex', last_name: 'Guardian' }],
          };
        }
        return { rows: [] };
      }));

    const res = await request(app).get('/api/planned-absences/carer-invites/code/testcode');
    expect(res.status).toBe(200);
    expect(res.body.title).toBe('Ski week');
    expect(res.body.starts_on).toBe('2026-11-01');
    expect(res.body.inviter_name).toBeTruthy();
  });
});
