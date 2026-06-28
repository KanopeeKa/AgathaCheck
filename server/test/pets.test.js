import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

const PET_COLOR_PALETTE = [
  4286470082, 4287985101, 4284246976, 4286154443, 4283283116,
  4286695300, 4283417591, 4290406600, 4293943954, 4293227379,
  4294948685, 4288776319, 4287669422, 4284790262, 4289648001,
];

const petId = '123e4567-e89b-12d3-a456-426614174000';
const petId2 = '223e4567-e89b-12d3-a456-426614174001';

function makePetRow(overrides = {}) {
  return {
    id: petId,
    user_id: userId,
    name: 'Fluffy',
    species: 'cat',
    breed: 'Persian',
    age: 3,
    date_of_birth: new Date('2021-01-15'),
    weight: 4.5,
    gender: 'female',
    bio: 'A lovely cat',
    insurance: 'PetPlan #123',
    neutered_date: new Date('2022-06-01'),
    neuter_dismissed: false,
    chip_id: 'CHIP-001',
    chip_dismissed: false,
    photo_path: '/uploads/fluffy.jpg',
    vet_id: 'vet-uuid-1',
    color_index: 0,
    passed_away: false,
    organization_id: 'org-uuid-1',
    created_at: new Date('2023-01-01'),
    updated_at: new Date('2023-06-01'),
    ...overrides,
  };
}

function createMockPool(queryHandler) {
  return {
    query: queryHandler || (async (sql, params) => {
      if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2')) {
        return { rows: [{ '?column?': 1 }] };
      }
      if (sql.includes('SELECT 1 FROM pet_access WHERE pet_id')) {
        return { rows: [] };
      }
      if (sql.includes('CASE WHEN p.user_id')) {
        return { rows: [makePetRow()] };
      }
      if (sql.includes('false AS is_shared') || sql.includes('UNION ALL')) {
        return { rows: [makePetRow({ is_shared: false })] };
      }
      if (sql.includes('FROM pet_access pa') && sql.includes("role IN ('shared', 'guardian')")) {
        return { rows: [] };
      }
      if (sql.includes('DELETE FROM pet_access WHERE pet_id')) {
        return { rows: [{ id: 'pa-1' }] };
      }
      if (sql.includes('INSERT INTO notifications')) {
        return { rows: [] };
      }
      if (sql.includes('SELECT name FROM pets WHERE id = $1')) {
        return { rows: [{ name: 'Fluffy' }] };
      }
      if (sql.includes('SELECT first_name, last_name, email FROM users')) {
        return { rows: [{ first_name: 'Test', last_name: 'User', email: 'test@example.com' }] };
      }
      return { rows: [] };
    }),
    end: async () => {},
  };
}

describe('Pets API', () => {
  describe('Auth guard', () => {
    let app;
    beforeAll(() => {
      app = createApp(createMockPool());
    });

    it('GET /api/pets returns 401 without token', async () => {
      const res = await request(app).get('/api/pets');
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error', 'Unauthorized');
    });

    it('GET /api/pets/all returns 401 without token', async () => {
      const res = await request(app).get('/api/pets/all');
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error', 'Unauthorized');
    });

    it('GET /api/pets/:id returns 401 without token', async () => {
      const res = await request(app).get(`/api/pets/${petId}`);
      expect(res.statusCode).toBe(401);
    });

    it('POST /api/pets returns 401 without token', async () => {
      const res = await request(app).post('/api/pets').send({ name: 'X' });
      expect(res.statusCode).toBe(401);
    });

    it('PUT /api/pets/:id returns 401 without token', async () => {
      const res = await request(app).put(`/api/pets/${petId}`).send({ name: 'X' });
      expect(res.statusCode).toBe(401);
    });

    it('DELETE /api/pets/:id returns 401 without token', async () => {
      const res = await request(app).delete(`/api/pets/${petId}`);
      expect(res.statusCode).toBe(401);
    });

    it('returns 401 with invalid token', async () => {
      const res = await request(app)
        .get('/api/pets')
        .set('Authorization', 'Bearer invalidtoken');
      expect(res.statusCode).toBe(401);
    });

    it('returns 401 with expired token', async () => {
      const expired = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '0s' });
      await new Promise(r => setTimeout(r, 10));
      const res = await request(app)
        .get('/api/pets')
        .set('Authorization', `Bearer ${expired}`);
      expect(res.statusCode).toBe(401);
    });
  });

  describe('GET /api/pets (list)', () => {
    it('returns empty array when user has no pets', async () => {
      const app = createApp(createMockPool(async () => ({ rows: [] })));
      const res = await request(app)
        .get('/api/pets')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBe(0);
    });

    it('returns list of pets with proper field mapping', async () => {
      const row = makePetRow();
      const app = createApp(createMockPool(async (sql) => {
        if (sql.includes('SELECT * FROM pets')) return { rows: [row] };
        return { rows: [] };
      }));
      const res = await request(app)
        .get('/api/pets')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body.length).toBe(1);
      const pet = res.body[0];
      expect(pet).toHaveProperty('id', petId);
      expect(pet).toHaveProperty('name', 'Fluffy');
      expect(pet).toHaveProperty('species', 'cat');
      expect(pet).toHaveProperty('breed', 'Persian');
      expect(pet).toHaveProperty('dateOfBirth');
      expect(pet).toHaveProperty('date_of_birth');
      expect(pet).toHaveProperty('photoPath', '/uploads/fluffy.jpg');
      expect(pet).toHaveProperty('vetId', 'vet-uuid-1');
      expect(pet).toHaveProperty('passedAway', false);
      expect(pet).toHaveProperty('organization_id', 'org-uuid-1');
      expect(pet).toHaveProperty('chipId', 'CHIP-001');
      expect(pet).toHaveProperty('chipDismissed', false);
      expect(pet).toHaveProperty('neuteredDate');
      expect(pet).toHaveProperty('neuterDismissed', false);
      expect(pet).toHaveProperty('bio', 'A lovely cat');
      expect(pet).toHaveProperty('insurance', 'PetPlan #123');
      expect(pet).toHaveProperty('colorValue');
    });

    it('resolves colorValue from color_index using palette', async () => {
      const row = makePetRow({ color_index: 2 });
      const app = createApp(createMockPool(async (sql) => {
        if (sql.includes('SELECT * FROM pets')) return { rows: [row] };
        return { rows: [] };
      }));
      const res = await request(app)
        .get('/api/pets')
        .set('Authorization', `Bearer ${token}`);
      expect(res.body[0].colorValue).toBe(PET_COLOR_PALETTE[2]);
    });

    it('returns colorValue as-is when color_index >= palette length', async () => {
      const bigColor = 4294967295;
      const row = makePetRow({ color_index: bigColor });
      const app = createApp(createMockPool(async (sql) => {
        if (sql.includes('SELECT * FROM pets')) return { rows: [row] };
        return { rows: [] };
      }));
      const res = await request(app)
        .get('/api/pets')
        .set('Authorization', `Bearer ${token}`);
      expect(res.body[0].colorValue).toBe(bigColor);
    });

    it('handles 500 on database error', async () => {
      const app = createApp(createMockPool(async () => { throw new Error('DB down'); }));
      const res = await request(app)
        .get('/api/pets')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(500);
      expect(res.body.error).toContain('Error fetching pets');
    });
  });

  describe('GET /api/pets/all', () => {
    it('returns list of all pets for user', async () => {
      const rows = [makePetRow(), makePetRow({ id: petId2, name: 'Rex', species: 'dog', color_index: 1 })];
      const app = createApp(createMockPool(async (sql) => {
        if (sql.includes('false AS is_shared') || sql.includes('UNION ALL')) return { rows };
        return { rows: [] };
      }));
      const res = await request(app)
        .get('/api/pets/all')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body.length).toBe(2);
      expect(res.body[0].name).toBe('Fluffy');
      expect(res.body[1].name).toBe('Rex');
    });

    it('maps shared pets with is_shared and clears organization_id', async () => {
      const sharedRow = makePetRow({
        id: petId2,
        name: 'Buddy',
        user_id: 'other-owner',
        organization_id: 'org-uuid-1',
        is_shared: true,
      });
      const app = createApp(createMockPool(async (sql) => {
        if (sql.includes('false AS is_shared') || sql.includes('UNION ALL')) {
          return { rows: [sharedRow] };
        }
        return { rows: [] };
      }));
      const res = await request(app)
        .get('/api/pets/all')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveLength(1);
      expect(res.body[0]).toMatchObject({
        name: 'Buddy',
        is_shared: true,
        organization_id: null,
      });
    });
  });

  describe('GET /api/pets/:id', () => {
    it('returns a single pet by id', async () => {
      const row = makePetRow();
      const app = createApp(createMockPool(async (sql) => {
        if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2')) {
          return { rows: [{ '?column?': 1 }] };
        }
        if (sql.includes('CASE WHEN p.user_id')) return { rows: [row] };
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

    it('creates pet with provided id (upsert)', async () => {
      const returnedRow = makePetRow();
      let capturedParams;
      const app = createApp(createMockPool(async (sql, params) => {
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
      const app = createApp(createMockPool(async (sql) => {
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
      const app = createApp(createMockPool(async () => ({ rows: [] })));
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

  describe('Ownership / cross-user access', () => {
    it('GET /api/pets/:id scopes the query to the authenticated user', async () => {
      let capturedParams;
      const app = createApp(createMockPool(async (sql, params) => {
        if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2')) {
          capturedParams = params;
          return { rows: [{ '?column?': 1 }] };
        }
        if (sql.includes('CASE WHEN p.user_id')) {
          return { rows: [makePetRow()] };
        }
        return { rows: [] };
      }));
      await request(app)
        .get(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`);
      expect(capturedParams[0]).toBe(petId);
      expect(capturedParams[1]).toBe(userId);
    });

    it('GET /api/pets/:id returns 404 when the pet belongs to another user', async () => {
      const app = createApp(createMockPool(async () => ({ rows: [] })));
      const res = await request(app)
        .get(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error', 'Pet not found');
    });

    it('PUT /api/pets/:id scopes the update to the authenticated user', async () => {
      let capturedParams;
      const app = createApp(createMockPool(async (sql, params) => {
        if (sql.includes('UPDATE pets SET')) {
          capturedParams = params;
          return { rows: [makePetRow()] };
        }
        return { rows: [] };
      }));
      await request(app)
        .put(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'X', species: 'dog' });
      expect(capturedParams).toContain(petId);
      expect(capturedParams).toContain(userId);
    });

    it('PUT /api/pets/:id returns 404 when the pet belongs to another user', async () => {
      const app = createApp(createMockPool(async () => ({ rows: [] })));
      const res = await request(app)
        .put(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'X', species: 'dog' });
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error', 'Pet not found');
    });

    it('DELETE /api/pets/:id scopes the delete to the authenticated user', async () => {
      let capturedParams;
      const app = createApp(createMockPool(async (sql, params) => {
        if (sql.includes('DELETE FROM pets')) {
          capturedParams = params;
          return { rows: [] };
        }
        return { rows: [] };
      }));
      await request(app)
        .delete(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`);
      expect(capturedParams[0]).toBe(petId);
      expect(capturedParams[1]).toBe(userId);
    });
  });

  describe('Organization membership enforcement', () => {
    it('POST /api/pets returns 403 when user is not a member of organization_id', async () => {
      const app = createApp(createMockPool(async (sql) => {
        if (sql.includes('organization_users')) return { rows: [] };
        if (sql.includes('INSERT INTO pets')) return { rows: [makePetRow()] };
        return { rows: [] };
      }));
      const res = await request(app)
        .post('/api/pets')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Fluffy', species: 'cat', organization_id: 'org-uuid-1' });
      expect(res.statusCode).toBe(403);
      expect(res.body).toHaveProperty('error', 'Not a member of this organization');
    });

    it('POST /api/pets succeeds when user is a member of organization_id', async () => {
      const app = createApp(createMockPool(async (sql) => {
        if (sql.includes('organization_users')) return { rows: [{ '?column?': 1 }] };
        if (sql.includes('INSERT INTO pets')) return { rows: [makePetRow()] };
        return { rows: [] };
      }));
      const res = await request(app)
        .post('/api/pets')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Fluffy', species: 'cat', organization_id: 'org-uuid-1' });
      expect(res.statusCode).toBe(201);
    });

    it('POST /api/pets skips the membership check when no organization_id is given', async () => {
      let checkedMembership = false;
      const app = createApp(createMockPool(async (sql) => {
        if (sql.includes('organization_users')) { checkedMembership = true; return { rows: [] }; }
        if (sql.includes('INSERT INTO pets')) return { rows: [makePetRow({ organization_id: null })] };
        return { rows: [] };
      }));
      const res = await request(app)
        .post('/api/pets')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Fluffy', species: 'cat' });
      expect(res.statusCode).toBe(201);
      expect(checkedMembership).toBe(false);
    });

    it('PUT /api/pets/:id returns 403 when user is not a member of organization_id', async () => {
      const app = createApp(createMockPool(async (sql) => {
        if (sql.includes('organization_users')) return { rows: [] };
        if (sql.includes('UPDATE pets SET')) return { rows: [makePetRow()] };
        return { rows: [] };
      }));
      const res = await request(app)
        .put(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'X', species: 'dog', organization_id: 'org-uuid-1' });
      expect(res.statusCode).toBe(403);
      expect(res.body).toHaveProperty('error', 'Not a member of this organization');
    });

    it('PUT /api/pets/:id succeeds when user is a member of organization_id', async () => {
      const app = createApp(createMockPool(async (sql) => {
        if (sql.includes('organization_users')) return { rows: [{ '?column?': 1 }] };
        if (sql.includes('UPDATE pets SET')) return { rows: [makePetRow()] };
        return { rows: [] };
      }));
      const res = await request(app)
        .put(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'X', species: 'dog', organization_id: 'org-uuid-1' });
      expect(res.statusCode).toBe(200);
    });
  });

  describe('Auto-assign colors', () => {
    it('assigns first available palette color when color_index is null', async () => {
      const row = makePetRow({ color_index: null });
      const app = createApp(createMockPool(async (sql) => {
        if (sql.includes('SELECT * FROM pets')) return { rows: [row] };
        return { rows: [] };
      }));
      const res = await request(app)
        .get('/api/pets')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body[0].colorValue).toBe(PET_COLOR_PALETTE[0]);
    });

    it('skips already used colors when auto-assigning', async () => {
      const row1 = makePetRow({ id: petId, color_index: 0 });
      const row2 = makePetRow({ id: petId2, name: 'Rex', color_index: null });
      const app = createApp(createMockPool(async (sql) => {
        if (sql.includes('SELECT * FROM pets')) return { rows: [row1, row2] };
        return { rows: [] };
      }));
      const res = await request(app)
        .get('/api/pets')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body[0].colorValue).toBe(PET_COLOR_PALETTE[0]);
      expect(res.body[1].colorValue).toBe(PET_COLOR_PALETTE[1]);
    });
  });

  describe('Response field mapping', () => {
    it('maps all camelCase fields correctly', async () => {
      const row = makePetRow();
      const app = createApp(createMockPool(async (sql) => {
        if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2')) {
          return { rows: [{ '?column?': 1 }] };
        }
        if (sql.includes('CASE WHEN p.user_id')) return { rows: [row] };
        return { rows: [] };
      }));
      const res = await request(app)
        .get(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`);
      const pet = res.body;
      expect(pet.dateOfBirth).toBeDefined();
      expect(pet.date_of_birth).toBeDefined();
      expect(pet.photoPath).toBe('/uploads/fluffy.jpg');
      expect(pet.vetId).toBe('vet-uuid-1');
      expect(pet.passedAway).toBe(false);
      expect(pet.organization_id).toBe('org-uuid-1');
      expect(pet.chipId).toBe('CHIP-001');
      expect(pet.chipDismissed).toBe(false);
      expect(pet.neuteredDate).toBeDefined();
      expect(pet.neuterDismissed).toBe(false);
      expect(pet.colorValue).toBe(PET_COLOR_PALETTE[0]);
    });

    it('handles null optional fields', async () => {
      const row = makePetRow({
        bio: null,
        insurance: null,
        neutered_date: null,
        chip_id: null,
        photo_path: null,
        vet_id: null,
        date_of_birth: null,
        organization_id: null,
        breed: null,
      });
      const app = createApp(createMockPool(async (sql) => {
        if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2')) {
          return { rows: [{ '?column?': 1 }] };
        }
        if (sql.includes('CASE WHEN p.user_id')) return { rows: [row] };
        return { rows: [] };
      }));
      const res = await request(app)
        .get(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`);
      const pet = res.body;
      expect(pet.bio).toBe('');
      expect(pet.insurance).toBe('');
      expect(pet.neuteredDate).toBeNull();
      expect(pet.chipId).toBe('');
      expect(pet.photoPath).toBeNull();
      expect(pet.vetId).toBeNull();
      expect(pet.dateOfBirth).toBeNull();
      expect(pet.breed).toBe('');
    });
  });

  describe('Extended endpoints', () => {
    let app;
    beforeAll(() => {
      app = createApp(createMockPool());
    });

    const extendedEndpoints = [
      ['POST', `/api/pets/${petId}/transfer-to-org`],
      ['GET', `/api/pets/${petId}/family-events`],
      ['POST', `/api/pets/${petId}/family-events`],
      ['PUT', `/api/pets/${petId}/family-events/1`],
      ['DELETE', `/api/pets/${petId}/family-events/1`],
      ['GET', `/api/pets/${petId}/access`],
      ['PUT', `/api/pets/${petId}/access/user-42/role`],
      ['DELETE', `/api/pets/${petId}/access/user-42`],
      ['DELETE', `/api/pets/${petId}/data`],
      ['POST', `/api/pets/${petId}/passed-away`],
    ];

    extendedEndpoints.forEach(([method, url]) => {
      it(`${method} ${url.replace(petId, ':id')} returns 401 without token`, async () => {
        const res = await request(app)[method.toLowerCase()](url).send({});
        expect(res.statusCode).toBe(401);
        expect(res.body).toHaveProperty('error', 'Unauthorized');
      });
    });

    it('POST /:id/transfer-to-org returns 501 (not implemented)', async () => {
      const res = await request(app)
        .post(`/api/pets/${petId}/transfer-to-org`)
        .set('Authorization', `Bearer ${token}`)
        .send({ organization_id: 'org-1' });
      expect(res.statusCode).toBe(501);
    });

    it('GET /:id/family-events returns an (empty) array', async () => {
      const res = await request(app)
        .get(`/api/pets/${petId}/family-events`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    it('POST /:id/family-events returns 501 (not implemented)', async () => {
      const res = await request(app)
        .post(`/api/pets/${petId}/family-events`)
        .set('Authorization', `Bearer ${token}`)
        .send({ type: 'adoption', date: '2023-01-01' });
      expect(res.statusCode).toBe(501);
    });

    it('PUT /:id/family-events/:eventId returns 501 (not implemented)', async () => {
      const res = await request(app)
        .put(`/api/pets/${petId}/family-events/1`)
        .set('Authorization', `Bearer ${token}`)
        .send({ type: 'birthday' });
      expect(res.statusCode).toBe(501);
    });

    it('DELETE /:id/family-events/:eventId returns 501 (not implemented)', async () => {
      const res = await request(app)
        .delete(`/api/pets/${petId}/family-events/1`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(501);
    });

    it('GET /:id/access returns access list for owner', async () => {
      const res = await request(app)
        .get(`/api/pets/${petId}/access`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    it('PUT /:id/access/:userId/role returns 501 (not implemented)', async () => {
      const res = await request(app)
        .put(`/api/pets/${petId}/access/user-42/role`)
        .set('Authorization', `Bearer ${token}`)
        .send({ role: 'editor' });
      expect(res.statusCode).toBe(501);
    });

    it('DELETE /:id/access/:userId removes access and notifies user', async () => {
      const res = await request(app)
        .delete(`/api/pets/${petId}/access/user-42`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Access removed');
    });

    it('DELETE /:id/data returns deleted', async () => {
      const res = await request(app)
        .delete(`/api/pets/${petId}/data`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('deleted', true);
      expect(res.body).toHaveProperty('pet_id', petId);
    });

    it('POST /:id/passed-away returns passed_away: true', async () => {
      const res = await request(app)
        .post(`/api/pets/${petId}/passed-away`)
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('passed_away', true);
      expect(res.body).toHaveProperty('pet_id', petId);
    });
  });
});
