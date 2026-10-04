import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const organiserId = 'organiser-uuid';
const memberId = 'member-uuid';
const inviteeId = 'invitee-uuid';
const householdId = 'household-uuid';
const inviteId = 'invite-uuid';
const inviteCode = 'hhinvite1';

const organiserToken = jwt.sign(
  { id: organiserId, email: 'org@example.com' },
  JWT_SECRET,
  { expiresIn: '1h' },
);
const memberToken = jwt.sign(
  { id: memberId, email: 'member@example.com' },
  JWT_SECRET,
  { expiresIn: '1h' },
);
const inviteeToken = jwt.sign(
  { id: inviteeId, email: 'invitee@example.com' },
  JWT_SECRET,
  { expiresIn: '1h' },
);

function futureExpiry() {
  return new Date(Date.now() + 14 * 24 * 60 * 60 * 1000);
}

describe('Household invites API', () => {
  let app;
  const invites = new Map();
  const members = new Map();
  const households = new Map([[householdId, { id: householdId, name: 'Test Home' }]]);

  members.set(`${householdId}:${organiserId}`, {
    household_id: householdId,
    user_id: organiserId,
    access_tier: 'full_access',
    is_organiser: true,
  });
  members.set(`${householdId}:${memberId}`, {
    household_id: householdId,
    user_id: memberId,
    access_tier: 'full_access',
    is_organiser: false,
  });

  beforeAll(() => {
    const mockPool = {
      query: async (sql, params = []) => {
        const s = sql.replace(/\s+/g, ' ');

        if (s.includes('FROM household_members') && s.includes('household_id = $1 AND user_id = $2')) {
          const key = `${params[0]}:${params[1]}`;
          const row = members.get(key);
          return { rows: row ? [row] : [] };
        }
        if (s.includes('FROM household_members hm') && s.includes('INNER JOIN users u')) {
          if (params[0] === householdId && params[1] === 'invitee@example.com') {
            return { rows: [] };
          }
          return { rows: [] };
        }
        if (s.includes('SELECT id FROM household_invites') && s.includes('pending')) {
          return { rows: [] };
        }
        if (s.includes('INSERT INTO household_invites')) {
          const id = params[0];
          invites.set(id, {
            id,
            household_id: params[1],
            inviter_user_id: params[2],
            invitee_email: params[3],
            invitee_user_id: params[4],
            access_tier: params[5],
            is_organiser: params[6],
            contact_id: params[7],
            code: params[8],
            status: params[9],
            expires_at: params[10],
            household_name: 'Test Home',
          });
          invites.set(params[8], invites.get(id));
          return { rows: [] };
        }
        if (s.includes('FROM household_invites i') && s.includes('INNER JOIN households')) {
          let row = invites.get(params[0]);
          if (!row) {
            row = [...invites.values()].find((i) => i.id === params[0]);
          }
          return { rows: row ? [row] : [] };
        }
        if (s.includes('SELECT name FROM households WHERE id')) {
          return { rows: [{ name: 'Test Home' }] };
        }
        if (s.includes('SELECT email FROM users WHERE id = $1')) {
          const emails = {
            [organiserId]: 'org@example.com',
            [inviteeId]: 'invitee@example.com',
            'decline-user': 'decline@example.com',
          };
          const email = emails[params[0]];
          return { rows: email ? [{ email }] : [] };
        }
        if (s.includes('SELECT first_name, last_name, email FROM users WHERE id = $1')) {
          return { rows: [{ first_name: 'Org', last_name: 'User', email: 'org@example.com' }] };
        }
        if (s.includes('SELECT id, email, first_name, last_name FROM users WHERE LOWER(email)')) {
          if (params[0] === 'invitee@example.com') {
            return { rows: [{ id: inviteeId, email: 'invitee@example.com' }] };
          }
          return { rows: [] };
        }
        if (s.includes('SELECT linked_user_id FROM people_contacts')) {
          return { rows: [{ linked_user_id: null }] };
        }
        if (s.includes('UPDATE people_contacts') && s.includes('linked_user_id')) {
          return { rows: [] };
        }
        if (s.includes('INSERT INTO household_members')) {
          members.set(`${params[0]}:${params[1]}`, {
            household_id: params[0],
            user_id: params[1],
            access_tier: params[2],
            is_organiser: params[3],
          });
          return { rows: [] };
        }
        if (s.includes('UPDATE household_invites') && s.includes('responded_at')) {
          const invite = invites.get(params[0]);
          if (invite) {
            invite.status = params[1];
            invite.invitee_user_id = params[2] ?? invite.invitee_user_id;
          }
          return { rows: [] };
        }
        if (s.includes('INSERT INTO notifications')) {
          return { rows: [] };
        }
        return { rows: [] };
      },
    };
    app = createApp(mockPool);
  });

  it('creates invite for organiser', async () => {
    const res = await request(app)
      .post(`/api/households/${householdId}/invites`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .send({
        invitee_email: 'invitee@example.com',
        access_tier: 'can_log_care',
        is_organiser: false,
      });
    expect(res.status).toBe(201);
    expect(res.body.invite_id).toBeTruthy();
    expect(res.body.code).toBeTruthy();
  });

  it('denies create for non-organiser', async () => {
    const res = await request(app)
      .post(`/api/households/${householdId}/invites`)
      .set('Authorization', `Bearer ${memberToken}`)
      .send({ invitee_email: 'other@example.com' });
    expect(res.status).toBe(403);
  });

  it('accepts invite by code', async () => {
    const stored = [...invites.values()].find((i) => i.code && i.status === 'pending');
    const res = await request(app)
      .post(`/api/households/invites/code/${stored.code}/accept`)
      .set('Authorization', `Bearer ${inviteeToken}`);
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('accepted');
    expect(res.body.household_id).toBe(householdId);
  });

  it('returns preview for valid code', async () => {
    const createRes = await request(app)
      .post(`/api/households/${householdId}/invites`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .send({ invitee_email: 'preview@example.com' });
    const code = createRes.body.code;
    const res = await request(app).get(`/api/households/invites/code/${code}`);
    expect(res.status).toBe(200);
    expect(res.body.household_name).toBe('Test Home');
  });

  it('declines invite by code', async () => {
    const createRes = await request(app)
      .post(`/api/households/${householdId}/invites`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .send({ invitee_email: 'decline@example.com' });
    const code = createRes.body.code;
    const declineToken = jwt.sign(
      { id: 'decline-user', email: 'decline@example.com' },
      JWT_SECRET,
      { expiresIn: '1h' },
    );
    const res = await request(app)
      .post(`/api/households/invites/code/${code}/decline`)
      .set('Authorization', `Bearer ${declineToken}`);
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('declined');
  });

  it('revokes pending invite', async () => {
    const createRes = await request(app)
      .post(`/api/households/${householdId}/invites`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .send({ invitee_email: 'revoke@example.com' });
    const id = createRes.body.invite_id;
    const res = await request(app)
      .delete(`/api/households/${householdId}/invites/${id}`)
      .set('Authorization', `Bearer ${organiserToken}`);
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('revoked');
  });
});
