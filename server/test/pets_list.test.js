import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

describe('GET /backend/api/pets', () => {
  it('should return an empty array if user has no pets', async () => {
    const mockPool = {
      query: async (sql, params) => {
        return { rows: [] };
      },
      end: async () => {}
    };
    const app = createApp(mockPool);
    const res = await request(app)
      .get('/backend/api/pets')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBe(0);
  });

  it('should return a list of pets with proper mapping', async () => {
    const mockPets = [
      { id: 'pet-1', user_id: userId, name: 'Fluffy', species: 'cat', breed: '', age: 2, weight: 4, gender: 'female', date_of_birth: null, bio: '', insurance: '', neutered_date: null, neuter_dismissed: false, chip_id: '', chip_dismissed: false, photo_path: null, vet_id: null, color_index: 0, passed_away: false, organization_id: null, created_at: new Date(), updated_at: new Date() },
      { id: 'pet-2', user_id: userId, name: 'Rex', species: 'dog', breed: 'Labrador', age: 5, weight: 30, gender: 'male', date_of_birth: null, bio: '', insurance: '', neutered_date: null, neuter_dismissed: false, chip_id: '', chip_dismissed: false, photo_path: null, vet_id: null, color_index: 1, passed_away: false, organization_id: null, created_at: new Date(), updated_at: new Date() },
    ];
    const mockPool = {
      query: async (sql, params) => {
        if (sql.includes('SELECT * FROM pets')) {
          return { rows: mockPets };
        }
        return { rows: [] };
      },
      end: async () => {}
    };
    const app = createApp(mockPool);
    const res = await request(app)
      .get('/backend/api/pets')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBe(2);
    expect(res.body[0]).toHaveProperty('colorValue');
    expect(res.body[0]).toHaveProperty('name', 'Fluffy');
    expect(res.body[1]).toHaveProperty('name', 'Rex');
  });

  it('should return 401 without auth', async () => {
    const mockPool = { query: async () => ({ rows: [] }), end: async () => {} };
    const app = createApp(mockPool);
    const res = await request(app).get('/backend/api/pets');
    expect(res.statusCode).toBe(401);
  });
});
