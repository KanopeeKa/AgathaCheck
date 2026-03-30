import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

describe('Vets API', () => {
  let app;

  beforeAll(() => {
    const mockPool = {
      query: async (sql, params) => {
        if (sql.includes('SELECT * FROM vets') && sql.includes('ORDER BY')) {
          return { rows: [{ id: 'vet-1', user_id: userId, name: 'Dr. Smith', clinic: 'Happy Paws', phone: '555-0100', email: 'dr@vet.com', website: 'https://vet.com', address: '123 Vet St', notes: 'Great vet', created_at: new Date(), updated_at: new Date() }] };
        }
        if (sql.includes('SELECT * FROM vets WHERE id')) {
          return { rows: [{ id: params[0], user_id: userId, name: 'Dr. Smith', clinic: 'Happy Paws', phone: '555-0100', email: 'dr@vet.com', website: '', address: '', notes: '', created_at: new Date(), updated_at: new Date() }] };
        }
        if (sql.includes('INSERT INTO vets')) {
          return { rows: [{ id: 'new-vet-id', user_id: userId, name: params[2], clinic: params[3], phone: params[4], email: params[5], website: params[6] || '', address: params[7] || '', notes: params[8] || '', created_at: new Date(), updated_at: new Date() }] };
        }
        if (sql.includes('UPDATE vets SET')) {
          return { rows: [{ id: params[7], user_id: userId, name: params[0], clinic: params[1], phone: params[2], email: params[3], website: params[4] || '', address: params[5] || '', notes: params[6] || '', created_at: new Date(), updated_at: new Date() }] };
        }
        if (sql.includes('DELETE FROM vets')) {
          return { rows: [{ id: params[0] }] };
        }
        return { rows: [] };
      },
      end: async () => {}
    };
    app = createApp(mockPool);
  });

  it('GET /backend/api/vets returns array with vet fields', async () => {
    const res = await request(app)
      .get('/backend/api/vets')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body[0]).toHaveProperty('website');
    expect(res.body[0]).toHaveProperty('address');
    expect(res.body[0]).toHaveProperty('notes');
  });

  it('POST /backend/api/vets creates vet with all fields', async () => {
    const vet = { name: 'Dr. Smith', clinic: 'Happy Paws', phone: '555', email: 'dr@v.com', website: 'https://v.com', address: '123 St', notes: 'Good' };
    const res = await request(app)
      .post('/backend/api/vets')
      .set('Authorization', `Bearer ${token}`)
      .send(vet);
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('name', 'Dr. Smith');
    expect(res.body).toHaveProperty('website');
    expect(res.body).toHaveProperty('address');
    expect(res.body).toHaveProperty('notes');
  });

  it('GET /backend/api/vets without auth returns 401', async () => {
    const res = await request(app).get('/backend/api/vets');
    expect(res.statusCode).toBe(401);
  });
});
