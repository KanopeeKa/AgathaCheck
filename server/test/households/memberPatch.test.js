import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import { createTransactionalMockPool } from '../helpers/transactionMockPool.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const householdId = 'household-uuid-0001';
const organiserId = 'organiser-uuid-01';
const coOrganiserId = 'organiser-uuid-02';
const memberId = 'member-uuid-0003';

const organiserToken = jwt.sign({ id: organiserId, email: 'org@example.com' }, JWT_SECRET, {
  expiresIn: '1h',
});
const memberToken = jwt.sign({ id: memberId, email: 'mem@example.com' }, JWT_SECRET, {
  expiresIn: '1h',
});

function buildPatchMockState(initialMembers) {
  const members = new Map(initialMembers.map((m) => [`${householdId}:${m.user_id}`, { ...m }]));

  const queryHandler = async (sql, params = []) => {
    const s = sql.replace(/\s+/g, ' ');

    if (s.includes('FROM household_members') && s.includes('household_id = $1 AND user_id = $2')) {
      const key = `${params[0]}:${params[1]}`;
      const row = members.get(key);
      return { rows: row ? [row] : [] };
    }

    if (s.includes('SELECT user_id FROM household_members') && s.includes('is_organiser = true')) {
      const rows = [];
      for (const m of members.values()) {
        if (m.household_id === params[0] && m.is_organiser && m.user_id !== params[1]) {
          rows.push({ user_id: m.user_id });
        }
      }
      return { rows };
    }

    if (s.includes('UPDATE household_members')) {
      const key = `${params[0]}:${params[1]}`;
      const existing = members.get(key);
      if (existing) {
        members.set(key, {
          ...existing,
          access_tier: params[2],
          is_organiser: params[3],
        });
      }
      return { rows: [] };
    }

    if (s.includes('FROM household_members hm') && s.includes('INNER JOIN users')) {
      const key = `${params[0]}:${params[1]}`;
      const row = members.get(key);
      if (!row) return { rows: [] };
      return {
        rows: [
          {
            ...row,
            first_name: 'Test',
            last_name: 'User',
            email: 'test@example.com',
            photo_url: '',
          },
        ],
      };
    }

    return { rows: [] };
  };

  return { members, queryHandler };
}

describe('PATCH /api/households/:id/members/:userId', () => {
  it('allows an organiser to change tier and organiser flag', async () => {
    const { members, queryHandler } = buildPatchMockState([
      {
        household_id: householdId,
        user_id: organiserId,
        access_tier: 'full_access',
        is_organiser: true,
        joined_at: new Date(),
      },
      {
        household_id: householdId,
        user_id: memberId,
        access_tier: 'full_access',
        is_organiser: false,
        joined_at: new Date(),
      },
    ]);
    const app = createApp(createTransactionalMockPool(queryHandler));

    const res = await request(app)
      .patch(`/api/households/${householdId}/members/${memberId}`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .send({ access_tier: 'can_log_care', is_organiser: false });

    expect(res.status).toBe(200);
    expect(res.body.user_id).toBe(memberId);
    expect(res.body.access_tier).toBe('can_log_care');
    expect(res.body.is_organiser).toBe(false);
    expect(members.get(`${householdId}:${memberId}`).access_tier).toBe('can_log_care');
  });

  it('normalises organiser to full_access (D13)', async () => {
    const { queryHandler } = buildPatchMockState([
      {
        household_id: householdId,
        user_id: organiserId,
        access_tier: 'full_access',
        is_organiser: true,
        joined_at: new Date(),
      },
      {
        household_id: householdId,
        user_id: memberId,
        access_tier: 'can_log_care',
        is_organiser: false,
        joined_at: new Date(),
      },
    ]);
    const app = createApp(createTransactionalMockPool(queryHandler));

    const res = await request(app)
      .patch(`/api/households/${householdId}/members/${memberId}`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .send({ is_organiser: true });

    expect(res.status).toBe(200);
    expect(res.body.access_tier).toBe('full_access');
    expect(res.body.is_organiser).toBe(true);
  });

  it('returns 403 for non-organiser callers', async () => {
    const { queryHandler } = buildPatchMockState([
      {
        household_id: householdId,
        user_id: organiserId,
        access_tier: 'full_access',
        is_organiser: true,
        joined_at: new Date(),
      },
      {
        household_id: householdId,
        user_id: memberId,
        access_tier: 'can_log_care',
        is_organiser: false,
        joined_at: new Date(),
      },
    ]);
    const app = createApp(createTransactionalMockPool(queryHandler));

    const res = await request(app)
      .patch(`/api/households/${householdId}/members/${organiserId}`)
      .set('Authorization', `Bearer ${memberToken}`)
      .send({ access_tier: 'can_log_care' });

    expect(res.status).toBe(403);
  });

  it('returns 409 last_organiser when demoting the sole organiser', async () => {
    const { members, queryHandler } = buildPatchMockState([
      {
        household_id: householdId,
        user_id: organiserId,
        access_tier: 'full_access',
        is_organiser: true,
        joined_at: new Date(),
      },
      {
        household_id: householdId,
        user_id: memberId,
        access_tier: 'can_log_care',
        is_organiser: false,
        joined_at: new Date(),
      },
    ]);
    const app = createApp(createTransactionalMockPool(queryHandler));

    const res = await request(app)
      .patch(`/api/households/${householdId}/members/${organiserId}`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .send({ is_organiser: false });

    expect(res.status).toBe(409);
    expect(res.body.code).toBe('last_organiser');
    expect(members.get(`${householdId}:${organiserId}`).is_organiser).toBe(true);
  });

  it('allows self-demotion when another organiser exists', async () => {
    const { members, queryHandler } = buildPatchMockState([
      {
        household_id: householdId,
        user_id: organiserId,
        access_tier: 'full_access',
        is_organiser: true,
        joined_at: new Date(),
      },
      {
        household_id: householdId,
        user_id: coOrganiserId,
        access_tier: 'full_access',
        is_organiser: true,
        joined_at: new Date(),
      },
    ]);
    const app = createApp(createTransactionalMockPool(queryHandler));

    const res = await request(app)
      .patch(`/api/households/${householdId}/members/${organiserId}`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .send({ is_organiser: false });

    expect(res.status).toBe(200);
    expect(res.body.is_organiser).toBe(false);
    expect(members.get(`${householdId}:${organiserId}`).is_organiser).toBe(false);
  });

  it('returns 404 for an unknown member', async () => {
    const { queryHandler } = buildPatchMockState([
      {
        household_id: householdId,
        user_id: organiserId,
        access_tier: 'full_access',
        is_organiser: true,
        joined_at: new Date(),
      },
    ]);
    const app = createApp(createTransactionalMockPool(queryHandler));

    const res = await request(app)
      .patch(`/api/households/${householdId}/members/unknown-user-id`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .send({ access_tier: 'can_log_care' });

    expect(res.status).toBe(404);
  });
});
