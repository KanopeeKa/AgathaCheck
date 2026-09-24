import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const inviterId = 'inviter-user';
const inviteeId = 'invitee-user';
const pet1 = 'pet-1';
const pet2 = 'pet-2';
const inviterToken = jwt.sign(
  { id: inviterId, email: 'owner@example.com' },
  JWT_SECRET,
  { expiresIn: '1h' },
);

function buildCreateInvitePool(overrides = {}) {
  const state = {
    insertedInvites: [],
    notifications: [],
    emails: [],
    petOwnership: new Set([pet1, pet2]),
    existingAccess: new Set(),
    pendingInvites: new Map(),
    usersByEmail: {
      'invitee@example.com': { id: inviteeId, email: 'invitee@example.com' },
    },
    ...overrides.state,
  };

  const query = async (sql, params) => {
    if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
      return { rows: [] };
    }
    if (sql.includes('SELECT email FROM users WHERE id = $1')) {
      return { rows: [{ email: 'owner@example.com' }] };
    }
    if (sql.includes('SELECT id, email, first_name, last_name FROM users WHERE LOWER(email)')) {
      const email = params[0];
      const user = state.usersByEmail[email];
      return { rows: user ? [user] : [] };
    }
    if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2 LIMIT 1')) {
      const petId = params[0];
      if (state.petOwnership.has(petId) && params[1] === inviterId) {
        return { rows: [{ '?column?': 1 }] };
      }
      return { rows: [] };
    }
    if (sql.includes('foster_placements fp')) {
      return { rows: [] };
    }
    if (sql.includes('SELECT pa.id') && sql.includes('FROM pet_access pa')) {
      const petId = params[0];
      const email = params[1];
      const userId = params[2];
      if (state.existingAccess.has(`${petId}:${email}`) || state.existingAccess.has(`${petId}:${userId}`)) {
        return { rows: [{ id: 'access-1' }] };
      }
      return { rows: [] };
    }
    if (sql.includes('FROM pet_share_invites psi') && sql.includes('pending')) {
      const petId = params[0];
      const email = params[1];
      const existingId = state.pendingInvites.get(`${petId}:${email}`);
      return { rows: existingId ? [{ id: existingId }] : [] };
    }
    if (sql.includes('INSERT INTO pet_share_invites')) {
      state.insertedInvites.push({ params });
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO pet_share_invite_pets')) {
      return { rows: [] };
    }
    if (sql.includes('SELECT id, name FROM pets WHERE id = ANY')) {
      return {
        rows: (params[0] || []).map((id) => ({ id, name: id === pet1 ? 'Buddy' : 'Max' })),
      };
    }
    if (sql.includes('SELECT first_name, last_name, email FROM users WHERE id = $1')) {
      return { rows: [{ first_name: 'Alice', last_name: 'Owner', email: 'owner@example.com' }] };
    }
    if (sql.includes('INSERT INTO notifications')) {
      state.notifications.push({ params });
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

describe('POST /api/share/invites', () => {
  it('returns 401 without token', async () => {
    const app = createApp(buildCreateInvitePool());
    const res = await request(app)
      .post('/api/share/invites')
      .send({ invitee_email: 'invitee@example.com', pet_ids: [pet1] });
    expect(res.statusCode).toBe(401);
  });

  it('returns 400 for self-invite', async () => {
    const app = createApp(buildCreateInvitePool());
    const res = await request(app)
      .post('/api/share/invites')
      .set('Authorization', `Bearer ${inviterToken}`)
      .send({ invitee_email: 'owner@example.com', pet_ids: [pet1] });
    expect(res.statusCode).toBe(400);
    expect(res.body.error).toMatch(/yourself/i);
  });

  it('returns 400 when pet_ids is empty', async () => {
    const app = createApp(buildCreateInvitePool());
    const res = await request(app)
      .post('/api/share/invites')
      .set('Authorization', `Bearer ${inviterToken}`)
      .send({ invitee_email: 'invitee@example.com', pet_ids: [] });
    expect(res.statusCode).toBe(400);
  });

  it('returns 400 when more than 20 pet_ids', async () => {
    const app = createApp(buildCreateInvitePool());
    const res = await request(app)
      .post('/api/share/invites')
      .set('Authorization', `Bearer ${inviterToken}`)
      .send({
        invitee_email: 'invitee@example.com',
        pet_ids: Array.from({ length: 21 }, (_, i) => `pet-${i}`),
      });
    expect(res.statusCode).toBe(400);
  });

  it('returns 403 when user cannot share a pet', async () => {
    const pool = buildCreateInvitePool({
      state: { petOwnership: new Set([pet2]) },
    });
    const app = createApp(pool);
    const res = await request(app)
      .post('/api/share/invites')
      .set('Authorization', `Bearer ${inviterToken}`)
      .send({ invitee_email: 'invitee@example.com', pet_ids: [pet1, pet2] });
    expect(res.statusCode).toBe(403);
    expect(res.body.error).not.toMatch(/pet-1|pet-2/);
  });

  it('excludes pets with existing access and pending invites', async () => {
    const pool = buildCreateInvitePool({
      state: {
        existingAccess: new Set([`${pet1}:invitee@example.com`]),
        pendingInvites: new Map([[`${pet2}:invitee@example.com`, 'existing-invite']]),
      },
    });
    const app = createApp(pool);
    const res = await request(app)
      .post('/api/share/invites')
      .set('Authorization', `Bearer ${inviterToken}`)
      .send({ invitee_email: 'invitee@example.com', pet_ids: [pet1, pet2] });
    expect(res.statusCode).toBe(400);
    expect(res.body.excluded).toEqual([
      { pet_id: pet1, reason: 'already_has_access' },
      { pet_id: pet2, reason: 'pending_invite_exists', existing_invite_id: 'existing-invite' },
    ]);
  });

  it('creates invite for existing member with notification delivery', async () => {
    const pool = buildCreateInvitePool();
    const app = createApp(pool);
    const res = await request(app)
      .post('/api/share/invites')
      .set('Authorization', `Bearer ${inviterToken}`)
      .send({ invitee_email: 'invitee@example.com', pet_ids: [pet1] });
    expect(res.statusCode).toBe(201);
    expect(res.body).toMatchObject({
      included_pet_ids: [pet1],
      excluded: [],
      delivery: { email: 'skipped', notification: true },
    });
    expect(res.body.invite_id).toBeTruthy();
    expect(res.body.code).toBeTruthy();
    expect(pool.state.insertedInvites.length).toBe(1);
    expect(pool.state.notifications.length).toBeGreaterThan(0);
  });

  it('returns 201 with invite when post-commit name lookup fails after commit (A02 fixed)', async () => {
    let txDepth = 0;
    const pool = buildCreateInvitePool();
    const baseQuery = pool.query;
    pool.query = async (sql, params) => {
      if (sql === 'BEGIN') txDepth += 1;
      if (sql === 'COMMIT' || sql === 'ROLLBACK') txDepth = Math.max(0, txDepth - 1);
      if (
        txDepth === 0
        && sql.includes('SELECT first_name, last_name, email FROM users WHERE id = $1')
      ) {
        throw new Error('characterization: post-commit inviter name lookup failure');
      }
      return baseQuery(sql, params);
    };
    pool.connect = async () => ({ query: pool.query, release: () => {} });
    const app = createApp(pool);
    const res = await request(app)
      .post('/api/share/invites')
      .set('Authorization', `Bearer ${inviterToken}`)
      .send({ invitee_email: 'invitee@example.com', pet_ids: [pet1] });
    expect(res.statusCode).toBe(201);
    expect(res.body.invite_id).toBeTruthy();
    expect(res.body.code).toBeTruthy();
    expect(res.body.included_pet_ids).toEqual([pet1]);
    expect(pool.state.insertedInvites.length).toBe(1);
    expect(res.body.delivery.delivery_error).toBe(true);
  });

  it('creates invite for new user with skipped notification', async () => {
    const pool = buildCreateInvitePool({
      state: { usersByEmail: {} },
    });
    const app = createApp(pool);
    const res = await request(app)
      .post('/api/share/invites')
      .set('Authorization', `Bearer ${inviterToken}`)
      .send({ invitee_email: 'newuser@example.com', pet_ids: [pet1] });
    expect(res.statusCode).toBe(201);
    expect(res.body.delivery.notification).toBe(false);
    expect(['sent', 'failed', 'skipped']).toContain(res.body.delivery.email);
  });
});
