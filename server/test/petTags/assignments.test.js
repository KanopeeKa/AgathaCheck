import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'user-assign-1';
const token = jwt.sign({ id: userId, email: 'assign@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const petId = 'pet-assign-1';
const tagId = 'tag-assign-1';

function buildMockPool(handler) {
  return { query: handler };
}

describe('Pet tag assignments API', () => {
  it('POST /api/pets/:petId/tags assigns tag when user has access', async () => {
    const app = createApp(buildMockPool(async (sql) => {
      if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2')) {
        return { rows: [{ '?column?': 1 }] };
      }
      if (sql.includes('SELECT id FROM pet_tags WHERE id = $1 AND user_id = $2')) {
        return { rows: [{ id: tagId }] };
      }
      if (sql.includes('INSERT INTO pet_tag_assignments')) {
        return { rows: [] };
      }
      return { rows: [] };
    }));
    const res = await request(app)
      .post(`/api/pets/${petId}/tags`)
      .set('Authorization', `Bearer ${token}`)
      .send({ tag_id: tagId });
    expect(res.status).toBe(204);
  });

  it('POST /api/pets/:petId/tags returns 404 when pet inaccessible', async () => {
    const app = createApp(buildMockPool(async (sql) => {
      if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2')) {
        return { rows: [] };
      }
      if (sql.includes('FROM pet_access')) return { rows: [] };
      if (sql.includes('FROM pets p') && sql.includes('organization_users')) {
        return { rows: [] };
      }
      return { rows: [] };
    }));
    const res = await request(app)
      .post(`/api/pets/${petId}/tags`)
      .set('Authorization', `Bearer ${token}`)
      .send({ tag_id: tagId });
    expect(res.status).toBe(404);
  });

  it('POST /api/pets/:petId/tags requires tag_id', async () => {
    const app = createApp(buildMockPool(async () => ({ rows: [] })));
    const res = await request(app)
      .post(`/api/pets/${petId}/tags`)
      .set('Authorization', `Bearer ${token}`)
      .send({});
    expect(res.status).toBe(400);
  });

  it('DELETE /api/pets/:petId/tags/:tagId unassigns tag', async () => {
    const app = createApp(buildMockPool(async (sql) => {
      if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2')) {
        return { rows: [{ '?column?': 1 }] };
      }
      if (sql.includes('SELECT id FROM pet_tags WHERE id = $1 AND user_id = $2')) {
        return { rows: [{ id: tagId }] };
      }
      if (sql.includes('DELETE FROM pet_tag_assignments')) {
        return { rows: [] };
      }
      return { rows: [] };
    }));
    const res = await request(app)
      .delete(`/api/pets/${petId}/tags/${tagId}`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(204);
  });
});
