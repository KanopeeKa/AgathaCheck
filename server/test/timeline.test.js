import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'timeline-user';
const petId = 'pet-timeline-1';
const token = jwt.sign({ id: userId, email: 'timeline@example.com' }, JWT_SECRET, {
  expiresIn: '1h',
});

function buildMockPool() {
  const queries = [];
  return {
    queries,
    query: async (sql, params) => {
      queries.push({ sql, params });
      if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2')) {
        return { rows: [{ '?column?': 1 }] };
      }
      if (sql.includes('FROM pets WHERE id') && sql.includes('created_at')) {
        return {
          rows: [{
            id: petId,
            created_at: new Date('2024-01-01T00:00:00Z'),
            date_of_birth: '2023-06-01',
          }],
        };
      }
      if (sql.includes('SELECT 1 FROM pets WHERE id') && sql.includes('user_id')) {
        return { rows: [] };
      }
      if (sql.includes('FROM custody_transfers')) {
        return { rows: [] };
      }
      if (sql.includes('FROM foster_placements fp')) {
        return {
          rows: [{
            id: 'fp-1',
            start_date: '2025-06-01',
            end_date: '2025-08-31',
            notes: '',
            foster_name: 'Frank',
            foster_email: 'frank@example.com',
          }],
        };
      }
      if (sql.includes('FROM pet_timeline_entries') && sql.includes('WHERE id')) {
        return {
          rows: [{
            id: 'entry-1',
            pet_id: petId,
            entry_type: 'manual',
            title: 'Shelter stay',
            description: 'Temporary boarding',
            start_date: '2024-03-01',
            end_date: '2024-03-15',
          }],
        };
      }
      if (sql.includes('FROM pet_timeline_entries')) {
        return { rows: [] };
      }
      if (sql.includes('INSERT INTO pet_timeline_entries')) {
        return {
          rows: [{
            id: 'entry-1',
            title: params[2],
            description: params[3],
            start_date: params[4],
            end_date: params[5],
          }],
        };
      }
      if (sql.includes('UPDATE pet_timeline_entries')) {
        return {
          rows: [{
            id: params[4],
            title: params[0],
            description: params[1],
            start_date: params[2],
            end_date: params[3],
          }],
        };
      }
      if (sql.includes('DELETE FROM pet_timeline_entries')) {
        return { rows: [{ id: params[0] }] };
      }
      if (sql.includes('INSERT INTO audit_events')) {
        return { rows: [] };
      }
      return { rows: [] };
    },
    end: async () => {},
  };
}

describe('Pet timeline API', () => {
  it('GET /api/pets/:id/timeline returns fostering session segments', async () => {
    const pool = buildMockPool();
    const app = createApp(pool);
    const res = await request(app)
      .get(`/api/pets/${petId}/timeline`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.segments)).toBe(true);
    const session = res.body.segments.find((s) => s.kind === 'fostering_session');
    expect(session).toBeDefined();
    expect(session.foster_name).toBe('Frank');
    expect(session.start_date).toBe('2025-06-01');
    expect(session.end_date).toBe('2025-08-31');
  });

  it('POST /api/pets/:id/timeline/entries creates a manual entry', async () => {
    const pool = buildMockPool();
    const app = createApp(pool);
    const res = await request(app)
      .post(`/api/pets/${petId}/timeline/entries`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Shelter stay',
        description: 'Temporary boarding',
        start_date: '2024-03-01',
        end_date: '2024-03-15',
      });

    expect(res.status).toBe(201);
    expect(res.body.kind).toBe('manual');
    expect(res.body.title).toBe('Shelter stay');
    expect(pool.queries.some((q) => q.sql.includes('INSERT INTO pet_timeline_entries'))).toBe(true);
  });

  it('PUT /api/pets/:id/timeline/entries/:entryId updates a manual entry', async () => {
    const pool = buildMockPool();
    const app = createApp(pool);
    const res = await request(app)
      .put(`/api/pets/${petId}/timeline/entries/entry-1`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Updated stay',
        description: 'Extended boarding',
        start_date: '2024-03-01',
        end_date: '2024-03-20',
      });

    expect(res.status).toBe(200);
    expect(res.body.kind).toBe('manual');
    expect(res.body.title).toBe('Updated stay');
    expect(res.body.description).toBe('Extended boarding');
    expect(res.body.end_date).toBe('2024-03-20');
    expect(pool.queries.some((q) => q.sql.includes('UPDATE pet_timeline_entries'))).toBe(true);
  });

  it('DELETE /api/pets/:id/timeline/entries/:entryId deletes a manual entry', async () => {
    const pool = buildMockPool();
    const app = createApp(pool);
    const res = await request(app)
      .delete(`/api/pets/${petId}/timeline/entries/entry-1`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.deleted).toBe(true);
    expect(pool.queries.some((q) => q.sql.includes('DELETE FROM pet_timeline_entries'))).toBe(true);
  });
});
