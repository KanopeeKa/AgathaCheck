import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'user-tags-1';
const otherUserId = 'user-tags-2';
const tagId = 'tag-1';
const token = jwt.sign({ id: userId, email: 'tags@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const otherToken = jwt.sign({ id: otherUserId, email: 'other@example.com' }, JWT_SECRET, { expiresIn: '1h' });

function buildMockPool(handler) {
  return { query: handler };
}

describe('Pet tags catalog API', () => {
  it('GET /api/pet-tags returns 401 without token', async () => {
    const app = createApp(buildMockPool(async () => ({ rows: [] })));
    const res = await request(app).get('/api/pet-tags');
    expect(res.status).toBe(401);
  });

  it('GET /api/pet-tags lists user tags with pet_ids', async () => {
    const app = createApp(buildMockPool(async (sql) => {
      if (sql.includes('FROM pet_tags pt')) {
        return {
          rows: [{
            id: tagId,
            name: 'Weekend',
            created_at: new Date('2026-01-01T00:00:00Z'),
            updated_at: new Date('2026-01-01T00:00:00Z'),
            pet_ids: ['pet-1'],
          }],
        };
      }
      return { rows: [] };
    }));
    const res = await request(app)
      .get('/api/pet-tags')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual([{
      id: tagId,
      name: 'Weekend',
      pet_ids: ['pet-1'],
      created_at: '2026-01-01T00:00:00.000Z',
      updated_at: '2026-01-01T00:00:00.000Z',
    }]);
  });

  it('POST /api/pet-tags creates a tag', async () => {
    const app = createApp(buildMockPool(async (sql) => {
      if (sql.includes('SELECT 1 FROM pet_tags') && sql.includes('lower(name)')) {
        return { rows: [] };
      }
      if (sql.includes('INSERT INTO pet_tags')) {
        return {
          rows: [{
            id: tagId,
            name: 'Weekend',
            created_at: new Date('2026-01-01T00:00:00Z'),
            updated_at: new Date('2026-01-01T00:00:00Z'),
          }],
        };
      }
      return { rows: [] };
    }));
    const res = await request(app)
      .post('/api/pet-tags')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Weekend' });
    expect(res.status).toBe(201);
    expect(res.body.name).toBe('Weekend');
    expect(res.body.pet_ids).toEqual([]);
  });

  it('POST /api/pet-tags rejects empty name', async () => {
    const app = createApp(buildMockPool(async () => ({ rows: [] })));
    const res = await request(app)
      .post('/api/pet-tags')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: '   ' });
    expect(res.status).toBe(400);
  });

  it('POST /api/pet-tags returns 409 on duplicate name', async () => {
    const app = createApp(buildMockPool(async (sql) => {
      if (sql.includes('SELECT 1 FROM pet_tags') && sql.includes('lower(name)')) {
        return { rows: [{ '?column?': 1 }] };
      }
      return { rows: [] };
    }));
    const res = await request(app)
      .post('/api/pet-tags')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Weekend' });
    expect(res.status).toBe(409);
  });

  it('PATCH /api/pet-tags/:id allows case-only rename of same tag', async () => {
    const app = createApp(buildMockPool(async (sql) => {
      if (sql.includes('SELECT id FROM pet_tags WHERE id = $1 AND user_id = $2')) {
        return { rows: [{ id: tagId }] };
      }
      if (sql.includes('SELECT 1 FROM pet_tags') && sql.includes('AND id != $3')) {
        return { rows: [] };
      }
      if (sql.includes('UPDATE pet_tags SET name')) {
        return { rows: [] };
      }
      if (sql.includes('FROM pet_tags pt')) {
        return {
          rows: [{
            id: tagId,
            name: 'weekend',
            created_at: new Date('2026-01-01T00:00:00Z'),
            updated_at: new Date('2026-01-02T00:00:00Z'),
            pet_ids: [],
          }],
        };
      }
      return { rows: [] };
    }));
    const res = await request(app)
      .patch(`/api/pet-tags/${tagId}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'weekend' });
    expect(res.status).toBe(200);
    expect(res.body.name).toBe('weekend');
  });

  it('PATCH /api/pet-tags/:id returns 409 when name collides with another tag', async () => {
    const app = createApp(buildMockPool(async (sql) => {
      if (sql.includes('SELECT id FROM pet_tags WHERE id = $1 AND user_id = $2')) {
        return { rows: [{ id: tagId }] };
      }
      if (sql.includes('SELECT 1 FROM pet_tags') && sql.includes('AND id != $3')) {
        return { rows: [{ '?column?': 1 }] };
      }
      return { rows: [] };
    }));
    const res = await request(app)
      .patch(`/api/pet-tags/${tagId}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Other' });
    expect(res.status).toBe(409);
  });

  it('DELETE /api/pet-tags/:id returns 404 for other user tag', async () => {
    const app = createApp(buildMockPool(async (sql) => {
      if (sql.includes('DELETE FROM pet_tags')) return { rows: [] };
      return { rows: [] };
    }));
    const res = await request(app)
      .delete(`/api/pet-tags/${tagId}`)
      .set('Authorization', `Bearer ${otherToken}`);
    expect(res.status).toBe(404);
  });
});
