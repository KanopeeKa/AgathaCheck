import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const ownerId = 'owner-uuid-0001';
const memberId = 'member-uuid-0002';
const petId = 'pet-uuid-0001';
const householdId = 'household-uuid-0001';

const ownerToken = jwt.sign({ id: ownerId, email: 'owner@example.com' }, JWT_SECRET, {
  expiresIn: '1h',
});

describe('Households API', () => {
  let app;
  const households = new Map();
  const members = new Map();
  const householdPets = new Map();

  beforeAll(() => {
    const mockPool = {
      query: async (sql, params = []) => {
        const s = sql.replace(/\s+/g, ' ');

        if (s.includes('INSERT INTO households')) {
          const id = params[0];
          households.set(id, { id, name: params[1], created_at: new Date(), updated_at: new Date() });
          return { rows: [] };
        }
        if (s.includes('INSERT INTO household_members')) {
          const key = `${params[0]}:${params[1]}`;
          members.set(key, {
            household_id: params[0],
            user_id: params[1],
            access_tier: params[2],
            is_organiser: params[3],
            joined_at: new Date(),
          });
          return { rows: [] };
        }
        if (s.includes('INSERT INTO people_directories') && s.includes('household_id')) {
          return { rows: [{ id: 'dir-household' }] };
        }
        if (s.includes('SELECT id FROM people_directories WHERE household_id')) {
          return { rows: [{ id: 'dir-household' }] };
        }
        if (s.includes('FROM household_members hm') && s.includes('hm.user_id = $1') && s.includes('ORDER BY h.name')) {
          const rows = [];
          for (const m of members.values()) {
            if (m.user_id === params[0]) {
              const h = households.get(m.household_id);
              if (h) {
                rows.push({
                  ...h,
                  access_tier: m.access_tier,
                  is_organiser: m.is_organiser,
                });
              }
            }
          }
          return { rows };
        }
        if (s.includes('FROM household_members') && s.includes('household_id = $1 AND user_id = $2')) {
          const key = `${params[0]}:${params[1]}`;
          const row = members.get(key);
          return { rows: row ? [row] : [] };
        }
        if (s.includes('SELECT id, name, created_at, updated_at FROM households WHERE id')) {
          const h = households.get(params[0]);
          return { rows: h ? [h] : [] };
        }
        if (s.includes('FROM household_members hm') && s.includes('INNER JOIN users')) {
          const rows = [];
          for (const m of members.values()) {
            if (m.household_id === params[0]) {
              rows.push({
                ...m,
                first_name: 'Test',
                last_name: 'User',
                email: 'test@example.com',
                photo_url: '',
              });
            }
          }
          return { rows };
        }
        if (s.includes('FROM household_pets hp') && s.includes('INNER JOIN pets')) {
          const rows = [];
          for (const [pid, hid] of householdPets.entries()) {
            if (hid === params[0]) {
              rows.push({ pet_id: pid, name: 'Buddy', owner_user_id: ownerId });
            }
          }
          return { rows };
        }
        if (s.includes('SELECT 1 FROM users WHERE id')) {
          return { rows: [{ '?column?': 1 }] };
        }
        if (s.includes('FROM pets WHERE id = $1 AND user_id = $2')) {
          return params[0] === petId && params[1] === ownerId ? { rows: [{ '?column?': 1 }] } : { rows: [] };
        }
        if (s.includes('SELECT household_id FROM household_pets WHERE pet_id')) {
          return { rows: householdPets.has(params[0]) ? [{ household_id: householdPets.get(params[0]) }] : [] };
        }
        if (s.includes('SELECT pet_id FROM household_pets WHERE household_id')) {
          const rows = [];
          for (const [pid, hid] of householdPets.entries()) {
            if (hid === params[0]) rows.push({ pet_id: pid });
          }
          return { rows };
        }
        if (s.includes('INSERT INTO household_pets')) {
          householdPets.set(params[1], params[0]);
          return { rows: [] };
        }
        if (s.includes('DELETE FROM household_pets WHERE pet_id')) {
          householdPets.delete(params[0]);
          return { rows: [] };
        }
        if (s.includes('INSERT INTO pet_access_events')) {
          return { rows: [] };
        }
        if (s.includes('DELETE FROM pet_access_events')) {
          return { rows: [] };
        }
        if (s.includes('SELECT user_id FROM pets WHERE id')) {
          return { rows: [{ user_id: ownerId }] };
        }
        if (s.includes('FROM pet_contact_relationships')) {
          return { rows: [] };
        }
        if (s.includes('SELECT id FROM people_directories WHERE owner_user_id')) {
          return { rows: [{ id: 'dir-personal' }] };
        }
        return { rows: [] };
      },
    };
    app = createApp(mockPool);
  });

  it('POST /api/households creates household with organiser membership', async () => {
    const res = await request(app)
      .post('/api/households')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ name: 'Morgan household' });
    expect(res.status).toBe(201);
    expect(res.body.name).toBe('Morgan household');
    expect(res.body.members?.length).toBeGreaterThan(0);
  });

  it('GET /api/households lists memberships for caller', async () => {
    members.set(`${householdId}:${ownerId}`, {
      household_id: householdId,
      user_id: ownerId,
      access_tier: 'full_access',
      is_organiser: true,
      joined_at: new Date(),
    });
    households.set(householdId, {
      id: householdId,
      name: 'Test HH',
      created_at: new Date(),
      updated_at: new Date(),
    });

    const res = await request(app)
      .get('/api/households')
      .set('Authorization', `Bearer ${ownerToken}`);
    expect(res.status).toBe(200);
    expect(res.body.households.length).toBeGreaterThan(0);
  });
});
