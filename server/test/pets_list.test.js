import request from 'supertest';
import { createApp } from '../bin/server.js';
import { expect } from 'chai';

describe('GET /backend/api/pets', () => {
  it('should return an empty array if user has no pets', async () => {
    // Mock pool returns empty pets
    const mockPool = {
      query: async (sql, params) => {
        if (sql.includes('SELECT * FROM pets')) {
          return { rows: [] };
        }
        return { rows: [] };
      },
      end: async () => {}
    };
    const app = createApp(mockPool);
    const res = await request(app).get('/backend/api/pets');
    expect(res.statusCode).to.equal(200);
    expect(res.body).to.be.an('array').that.is.empty;
  });

  it('should return a list of pets if user has pets', async () => {
    // Mock pool returns some pets
    const mockPets = [
      { id: 'pet-1', name: 'Fluffy', species: 'cat', age: 2 },
      { id: 'pet-2', name: 'Rex', species: 'dog', age: 5 }
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
    const res = await request(app).get('/backend/api/pets');
    expect(res.statusCode).to.equal(200);
    expect(res.body).to.be.an('array').with.lengthOf(2);
    expect(res.body[0]).to.include({ id: 'pet-1', name: 'Fluffy', species: 'cat', age: 2 });
    expect(res.body[1]).to.include({ id: 'pet-2', name: 'Rex', species: 'dog', age: 5 });
  });
});
