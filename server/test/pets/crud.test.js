import request from 'supertest';
import { createApp } from '../../bin/server.js';
import { handlePetAccessQuery } from '../helpers/petAccessMocks.js';
import { createMockPool, makePetRow, token, userId, petId } from './helpers.js';

describe('Pets API', () => {
  describe('GET /api/pets/:id', () => {
    it('returns a single pet by id', async () => {
      const row = makePetRow();
      const app = createApp(createMockPool(async (sql) => {
        if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2')) {
          return { rows: [{ '?column?': 1 }] };
        }
        if (sql.includes('EXISTS') && sql.includes('AS is_foster') && sql.includes('WHERE p.id = $1')) return { rows: [row] };
        return { rows: [] };
      }));
      const res = await request(app)
        .get(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body.id).toBe(petId);
      expect(res.body.name).toBe('Fluffy');
    });

    it('returns 404 when pet not found', async () => {
      const app = createApp(createMockPool(async () => ({ rows: [] })));
      const res = await request(app)
        .get(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error', 'Pet not found');
    });

    it('returns 400 for invalid UUID', async () => {
      const app = createApp(createMockPool());
      const res = await request(app)
        .get('/api/pets/not-a-uuid')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error', 'Invalid pet ID');
    });

    it('handles 500 on database error', async () => {
      const app = createApp(createMockPool(async () => { throw new Error('fail'); }));
      const res = await request(app)
        .get(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(500);
    });
  });

  describe('POST /api/pets (create with upsert)', () => {
    it('creates a new pet with all fields', async () => {
      const returnedRow = makePetRow();
      const app = createApp(createMockPool(async (sql) => {
        if (sql.includes('organization_users')) return { rows: [{ '?column?': 1 }] };
        if (sql.includes('FROM weight_entries')) return { rows: [] };
        if (sql.includes('INSERT INTO weight_entries')) return { rows: [] };
        if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
        if (sql.includes('SELECT * FROM pets WHERE id = $1')) return { rows: [returnedRow] };
        if (sql.includes('INSERT INTO pets')) return { rows: [returnedRow] };
        return { rows: [] };
      }));
      const res = await request(app)
        .post('/api/pets')
        .set('Authorization', `Bearer ${token}`)
        .send({
          name: 'Fluffy',
          species: 'cat',
          breed: 'Persian',
          age: 3,
          dateOfBirth: '2021-01-15',
          weight: 4.5,
          gender: 'female',
          bio: 'A lovely cat',
          insurance: 'PetPlan #123',
          neuteredDate: '2022-06-01',
          neuterDismissed: false,
          chipId: 'CHIP-001',
          chipDismissed: false,
          photoPath: '/uploads/fluffy.jpg',
          vetId: 'vet-uuid-1',
          colorValue: 0,
          passedAway: false,
          organization_id: 'org-uuid-1',
        });
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('id', petId);
      expect(res.body).toHaveProperty('name', 'Fluffy');
      expect(res.body).toHaveProperty('colorValue');
      expect(res.body).toHaveProperty('bio', 'A lovely cat');
      expect(res.body).toHaveProperty('insurance', 'PetPlan #123');
      expect(res.body).toHaveProperty('chipId', 'CHIP-001');
    });

    it('normalizes species and gender on create', async () => {
      const returnedRow = makePetRow({ species: 'Cat', gender: 'Female' });
      let capturedParams;
      const app = createApp(createMockPool(async (sql, params) => {
        if (sql.includes('FROM weight_entries')) return { rows: [] };
        if (sql.includes('INSERT INTO weight_entries')) return { rows: [] };
        if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
        if (sql.includes('SELECT * FROM pets WHERE id = $1')) return { rows: [returnedRow] };
        if (sql.includes('INSERT INTO pets')) {
          capturedParams = params;
          return { rows: [returnedRow] };
        }
        return { rows: [] };
      }));
      const res = await request(app)
        .post('/api/pets')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Fluffy', species: 'cat', gender: 'female' });
      expect(res.statusCode).toBe(201);
      expect(capturedParams[3]).toBe('Cat');
      expect(capturedParams[8]).toBe('Female');
      expect(res.body.species).toBe('Cat');
      expect(res.body.gender).toBe('Female');
    });

    it('rejects inline base64 photo paths on create', async () => {
      const app = createApp(createMockPool());
      const res = await request(app)
        .post('/api/pets')
        .set('Authorization', `Bearer ${token}`)
        .send({
          name: 'Fluffy',
          species: 'cat',
          photoPath: 'data:image/png;base64,abc',
        });
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toContain('photo endpoint');
    });

    it('creates pet with provided id (upsert)', async () => {
      const returnedRow = makePetRow();
      let capturedParams;
      const app = createApp(createMockPool(async (sql, params) => {
        if (sql.includes('FROM weight_entries')) return { rows: [] };
        if (sql.includes('INSERT INTO weight_entries')) return { rows: [] };
        if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
        if (sql.includes('SELECT * FROM pets WHERE id = $1')) return { rows: [returnedRow] };
        if (sql.includes('INSERT INTO pets')) {
          capturedParams = params;
          return { rows: [returnedRow] };
        }
        return { rows: [] };
      }));
      const res = await request(app)
        .post('/api/pets')
        .set('Authorization', `Bearer ${token}`)
        .send({ id: petId, name: 'Fluffy', species: 'cat' });
      expect(res.statusCode).toBe(201);
      expect(capturedParams[0]).toBe(petId);
    });

    it('uses date_of_birth fallback field', async () => {
      const returnedRow = makePetRow();
      let capturedParams;
      const app = createApp(createMockPool(async (sql, params) => {
        if (sql.includes('FROM weight_entries')) return { rows: [] };
        if (sql.includes('INSERT INTO weight_entries')) return { rows: [] };
        if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
        if (sql.includes('SELECT * FROM pets WHERE id = $1')) return { rows: [returnedRow] };
        if (sql.includes('INSERT INTO pets')) {
          capturedParams = params;
          return { rows: [returnedRow] };
        }
        return { rows: [] };
      }));
      await request(app)
        .post('/api/pets')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Fluffy', species: 'cat', date_of_birth: '2021-01-15' });
      expect(capturedParams[6]).toBe('2021-01-15');
    });

    it('normalizes ISO timestamps to date-only on create', async () => {
      const returnedRow = makePetRow();
      let capturedParams;
      const app = createApp(createMockPool(async (sql, params) => {
        if (sql.includes('FROM weight_entries')) return { rows: [] };
        if (sql.includes('INSERT INTO weight_entries')) return { rows: [] };
        if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
        if (sql.includes('SELECT * FROM pets WHERE id = $1')) return { rows: [returnedRow] };
        if (sql.includes('INSERT INTO pets')) {
          capturedParams = params;
          return { rows: [returnedRow] };
        }
        return { rows: [] };
      }));
      await request(app)
        .post('/api/pets')
        .set('Authorization', `Bearer ${token}`)
        .send({
          name: 'Fluffy',
          species: 'cat',
          dateOfBirth: '2021-01-15T00:00:00.000Z',
          neuteredDate: '2022-06-01T00:00:00.000Z',
        });
      expect(capturedParams[6]).toBe('2021-01-15');
      expect(capturedParams[11]).toBe('2022-06-01');
    });

    it('handles 500 on database error', async () => {
      const app = createApp(createMockPool(async () => { throw new Error('insert fail'); }));
      const res = await request(app)
        .post('/api/pets')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'X', species: 'dog' });
      expect(res.statusCode).toBe(500);
      expect(res.body.error).toContain('Error creating pet');
    });
  });

  describe('PUT /api/pets/:id (update)', () => {
    it('updates a pet and returns mapped result', async () => {
      const updatedRow = makePetRow({ name: 'Fluffy Updated' });
      const app = createApp(createMockPool(async (sql, params) => {
        const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
        if (access) return access;
        if (sql.includes('SELECT organization_id FROM pets WHERE id = $1')) {
          return { rows: [{ organization_id: 'org-uuid-1' }] };
        }
        if (sql.includes('FROM weight_entries')) return { rows: [{ weight: 4.5 }] };
        if (sql.includes('INSERT INTO weight_entries')) return { rows: [] };
        if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
        if (sql.includes('SELECT * FROM pets WHERE id = $1')) return { rows: [updatedRow] };
        if (sql.includes('UPDATE pets SET')) return { rows: [updatedRow] };
        return { rows: [] };
      }));
      const res = await request(app)
        .put(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`)
        .send({
          name: 'Fluffy Updated',
          species: 'cat',
          breed: 'Persian',
          age: 4,
          weight: 5,
          gender: 'female',
          bio: 'Updated bio',
          insurance: 'NewPlan',
          neuteredDate: '2022-06-01',
          neuterDismissed: true,
          chipId: 'CHIP-002',
          chipDismissed: true,
          colorValue: 3,
          passedAway: false,
        });
      expect(res.statusCode).toBe(200);
      expect(res.body.name).toBe('Fluffy Updated');
    });

    it('preserves existing photo when photoPath is omitted on update', async () => {
      const updatedRow = makePetRow({ photo_path: '/uploads/fluffy.jpg' });
      let capturedParams;
      const app = createApp(createMockPool(async (sql, params) => {
        const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
        if (access) return access;
        if (sql.includes('SELECT organization_id, photo_path FROM pets')) {
          return { rows: [{ organization_id: null, photo_path: '/uploads/fluffy.jpg' }] };
        }
        if (sql.includes('FROM weight_entries')) return { rows: [{ weight: 4.5 }] };
        if (sql.includes('INSERT INTO weight_entries')) return { rows: [] };
        if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
        if (sql.includes('SELECT * FROM pets WHERE id = $1')) return { rows: [updatedRow] };
        if (sql.includes('UPDATE pets SET')) {
          capturedParams = params;
          return { rows: [updatedRow] };
        }
        return { rows: [] };
      }));
      const res = await request(app)
        .put(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Fluffy', species: 'cat' });
      expect(res.statusCode).toBe(200);
      expect(capturedParams[13]).toBe('/uploads/fluffy.jpg');
    });

    it('rejects inline base64 photo paths on update', async () => {
      const app = createApp(createMockPool(async (sql, params) => {
        const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
        if (access) return access;
        if (sql.includes('SELECT organization_id, photo_path FROM pets')) {
          return { rows: [{ organization_id: null, photo_path: '/uploads/fluffy.jpg' }] };
        }
        return { rows: [] };
      }));
      const res = await request(app)
        .put(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`)
        .send({
          name: 'Fluffy',
          species: 'cat',
          photoPath: 'data:image/png;base64,abc',
        });
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toContain('photo endpoint');
    });

    it('creates a weight entry when weight changes on update', async () => {
      const updatedRow = makePetRow({ weight: 5 });
      const queries = [];
      const app = createApp(createMockPool(async (sql, params) => {
        queries.push({ sql, params });
        const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
        if (access) return access;
        if (sql.includes('SELECT organization_id FROM pets WHERE id = $1')) {
          return { rows: [{ organization_id: null }] };
        }
        if (sql.includes('FROM weight_entries')) return { rows: [{ weight: 4.5 }] };
        if (sql.includes('INSERT INTO weight_entries')) return { rows: [] };
        if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
        if (sql.includes('SELECT * FROM pets WHERE id = $1')) return { rows: [updatedRow] };
        if (sql.includes('UPDATE pets SET')) return { rows: [updatedRow] };
        return { rows: [] };
      }));
      const res = await request(app)
        .put(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`)
        .send({
          name: 'Fluffy',
          species: 'cat',
          weight: 5,
          weightEntryDate: '2026-07-29',
        });
      expect(res.statusCode).toBe(200);
      const insert = queries.find((q) => q.sql.includes('INSERT INTO weight_entries'));
      expect(insert).toBeTruthy();
      expect(insert.params[5]).toBe('2026-07-29');
    });

    it('returns 404 when pet not found', async () => {
      const app = createApp(createMockPool(async () => ({ rows: [] })));
      const res = await request(app)
        .put(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'X', species: 'dog' });
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error', 'Pet not found');
    });

    it('handles 500 on database error', async () => {
      const app = createApp(createMockPool(async () => { throw new Error('update fail'); }));
      const res = await request(app)
        .put(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'X', species: 'dog' });
      expect(res.statusCode).toBe(500);
      expect(res.body.error).toContain('Error updating pet');
    });
  });

  describe('DELETE /api/pets/:id', () => {
    it('deletes a pet and returns deleted: true', async () => {
      const app = createApp(createMockPool(async (sql, params) => {
        const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
        if (access) return access;
        if (sql.includes('DELETE FROM pets')) return { rows: [] };
        return { rows: [] };
      }));
      const res = await request(app)
        .delete(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toEqual({ deleted: true });
    });

    it('handles 500 on database error', async () => {
      const app = createApp(createMockPool(async () => { throw new Error('delete fail'); }));
      const res = await request(app)
        .delete(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(500);
      expect(res.body.error).toContain('Error deleting pet');
    });
  });
});
