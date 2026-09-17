import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const inviterId = 'inviter-user';
const inviteeId = 'invitee-user';
const inviteId = 'invite-1';
const inviteCode = 'invite01';
const pet1 = 'pet-1';
const futureExpiry = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
const inviteeToken = jwt.sign(
  { id: inviteeId, email: 'invitee@example.com' },
  JWT_SECRET,
  { expiresIn: '1h' },
);

function baseInvite(overrides = {}) {
  return {
    id: inviteId,
    inviter_user_id: inviterId,
    invitee_email: 'invitee@example.com',
    invitee_user_id: inviteeId,
    role: 'carer',
    code: inviteCode,
    status: 'pending',
    expires_at: futureExpiry,
    pets: [{ pet_id: pet1, pet_name: 'Buddy' }],
    ...overrides,
  };
}

function buildAcceptDeclinePool(overrides = {}) {
  const state = {
    invite: baseInvite(),
    accessRole: null,
    upgraded: false,
    notifications: [],
    resolved: false,
    ...overrides.state,
  };

  const query = async (sql, params) => {
    if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
      return { rows: [] };
    }
    if (sql.includes('FROM pet_share_invites psi') && sql.includes('FOR UPDATE')) {
      return { rows: [state.invite] };
    }
    if (sql.includes('SELECT first_name, last_name, email FROM users WHERE id = $1')) {
      if (params[0] === inviteeId) {
        return { rows: [{ first_name: 'Bob', last_name: 'Invitee', email: 'invitee@example.com' }] };
      }
      return { rows: [{ first_name: 'Alice', last_name: 'Owner', email: 'owner@example.com' }] };
    }
    if (sql.includes('UPDATE pet_share_invites SET invitee_user_id')) {
      return { rows: [] };
    }
    if (sql.includes('SELECT role FROM pet_access')) {
      return { rows: state.accessRole ? [{ role: state.accessRole }] : [] };
    }
    if (sql.includes('UPDATE pet_access') && sql.includes('SET role')) {
      state.upgraded = true;
      state.accessRole = params[2];
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO pet_access')) {
      state.accessRole = params[3];
      return { rows: [] };
    }
    if (sql.includes('UPDATE pet_share_invites') && sql.includes('responded_at')) {
      state.invite = { ...state.invite, status: params[1] };
      return { rows: [] };
    }
    if (sql.includes('UPDATE notifications') && sql.includes('resolved_at')) {
      state.resolved = true;
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO notifications')) {
      state.notifications.push({ sql, params });
      return { rows: [] };
    }
    return { rows: [] };
  };

  const connect = async () => ({
    query,
    release: () => {},
  });

  return { query, connect, state, end: async () => {} };
}

describe('POST /api/share/invites/:inviteId/accept', () => {
  it('accepts invite and notifies inviter', async () => {
    const pool = buildAcceptDeclinePool();
    const app = createApp(pool);
    const res = await request(app)
      .post(`/api/share/invites/${inviteId}/accept`)
      .set('Authorization', `Bearer ${inviteeToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toMatchObject({
      invite_id: inviteId,
      status: 'accepted',
      access_role: 'carer',
      pet_ids: [pet1],
    });
    expect(pool.state.notifications.some((n) => n.params?.[8] === 'shareInviteAccepted')).toBe(true);
    expect(pool.state.resolved).toBe(true);
  });

  it('upgrades carer access to co_parent when invite role is co_parent', async () => {
    const pool = buildAcceptDeclinePool({
      state: {
        invite: baseInvite({ role: 'co_parent' }),
        accessRole: 'carer',
      },
    });
    const app = createApp(pool);
    const res = await request(app)
      .post(`/api/share/invites/${inviteId}/accept`)
      .set('Authorization', `Bearer ${inviteeToken}`);
    expect(res.statusCode).toBe(200);
    expect(pool.state.upgraded).toBe(true);
    expect(pool.state.accessRole).toBe('co_parent');
  });

  it('is idempotent when invite already accepted', async () => {
    const pool = buildAcceptDeclinePool({
      state: { invite: baseInvite({ status: 'accepted' }) },
    });
    const app = createApp(pool);
    const res = await request(app)
      .post(`/api/share/invites/${inviteId}/accept`)
      .set('Authorization', `Bearer ${inviteeToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('accepted');
  });
});

describe('POST /api/share/invites/:inviteId/decline', () => {
  it('declines invite and notifies inviter', async () => {
    const pool = buildAcceptDeclinePool();
    const app = createApp(pool);
    const res = await request(app)
      .post(`/api/share/invites/${inviteId}/decline`)
      .set('Authorization', `Bearer ${inviteeToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toMatchObject({ invite_id: inviteId, status: 'declined' });
    expect(pool.state.notifications.some((n) => n.params?.[8] === 'shareInviteDeclined')).toBe(true);
    expect(pool.state.resolved).toBe(true);
  });

  it('is idempotent when invite already declined', async () => {
    const pool = buildAcceptDeclinePool({
      state: { invite: baseInvite({ status: 'declined' }) },
    });
    const app = createApp(pool);
    const res = await request(app)
      .post(`/api/share/invites/${inviteId}/decline`)
      .set('Authorization', `Bearer ${inviteeToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('declined');
  });
});
