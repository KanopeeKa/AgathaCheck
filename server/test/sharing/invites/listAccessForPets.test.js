import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const ownerId = 'owner-user';
const pet1 = 'pet-1';
const pet2 = 'pet-2';
const token = jwt.sign({ id: ownerId, email: 'owner@example.com' }, JWT_SECRET, { expiresIn: '1h' });

function buildAccessPool() {
  const query = async (sql, params) => {
    if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2 LIMIT 1')) {
      return { rows: [{ '?column?': 1 }] };
    }
    if (sql.includes('foster_placements fp')) {
      return { rows: [] };
    }
    if (sql.includes('FROM pet_access pa') && sql.includes('JOIN users u')) {
      if (params[0]?.includes(pet1)) {
        return {
          rows: [{
            id: 'access-1',
            pet_id: pet1,
            user_id: 'carer-1',
            role: 'carer',
            invited_by: ownerId,
            created_at: new Date(),
            first_name: 'Carol',
            last_name: 'Carer',
            email: 'carol@example.com',
            category: 'pet_carer',
            bio: '',
            photo_url: '',
          }],
        };
      }
      return { rows: [] };
    }
    if (sql.includes('FROM pet_share_invites psi') && sql.includes('ANY($1::uuid[])')) {
      return {
        rows: [{
          id: 'invite-1',
          inviter_user_id: ownerId,
          invitee_email: 'new@example.com',
          invitee_user_id: null,
          role: 'carer',
          code: 'abc12345',
          status: 'pending',
          created_at: new Date(),
          expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
          pet_id: pet2,
        }],
      };
    }
    if (sql.includes('FROM pet_share_invites psi') && sql.includes('WHERE psip.pet_id = $1')) {
      return {
        rows: [{
          id: 'invite-1',
          invitee_email: 'new@example.com',
          invitee_user_id: null,
          role: 'carer',
          code: 'abc12345',
          status: 'pending',
          created_at: new Date(),
          expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
          pets: [{ pet_id: pet2, pet_name: 'Max' }],
        }],
      };
    }
    return { rows: [] };
  };

  return { query, connect: async () => ({ query, release: () => {} }), end: async () => {} };
}

describe('GET /api/share/access', () => {
  it('returns access and pending invites grouped by pet', async () => {
    const app = createApp(buildAccessPool());
    const res = await request(app)
      .get('/api/share/access')
      .query({ pet_ids: `${pet1},${pet2}` })
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.pets).toHaveLength(2);
    const petOne = res.body.pets.find((p) => p.pet_id === pet1);
    const petTwo = res.body.pets.find((p) => p.pet_id === pet2);
    expect(petOne.access).toHaveLength(1);
    expect(petOne.access[0].user.email).toBe('carol@example.com');
    expect(petTwo.pending_invites).toHaveLength(1);
    expect(petTwo.pending_invites[0].invitee_email).toBe('new@example.com');
  });

  it('returns 400 without pet_ids', async () => {
    const app = createApp(buildAccessPool());
    const res = await request(app)
      .get('/api/share/access')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(400);
  });
});

describe('GET /api/pets/:id/invites', () => {
  it('returns pending invites for a pet', async () => {
    const app = createApp(buildAccessPool());
    const res = await request(app)
      .get(`/api/pets/${pet2}/invites`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body[0]).toMatchObject({
      id: 'invite-1',
      invitee_email: 'new@example.com',
      role: 'carer',
      code: 'abc12345',
    });
  });
});
