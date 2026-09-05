import request from 'supertest';
import { createApp } from '../../bin/server.js';
import { createMockPool, makePetRow, token, petId, petId2, PET_COLOR_PALETTE } from './helpers.js';

describe('Pets API', () => {
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
      expect(pet).toHaveProperty('species', 'Cat');
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

    it('returns calendar dates as date-only strings', async () => {
      const row = makePetRow();
      const app = createApp(createMockPool(async (sql) => {
        if (sql.includes('SELECT * FROM pets')) return { rows: [row] };
        return { rows: [] };
      }));
      const res = await request(app)
        .get('/api/pets')
        .set('Authorization', `Bearer ${token}`);
      const pet = res.body[0];
      expect(pet.dateOfBirth).toBe('2021-01-15');
      expect(pet.date_of_birth).toBe('2021-01-15');
      expect(pet.neuteredDate).toBe('2022-06-01');
      expect(pet.dateOfBirth).not.toMatch(/T/);
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
        primary_holder_name: 'Jane Guardian',
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
        primary_holder_name: 'Jane Guardian',
      });
    });

    it('filters org-home-hidden pets from the owned-pets union branch', async () => {
      const captured = [];
      const app = createApp(createMockPool(async (sql) => {
        captured.push(sql);
        if (sql.includes('false AS is_shared') || sql.includes('UNION ALL')) {
          return { rows: [] };
        }
        return { rows: [] };
      }));
      await request(app)
        .get('/api/pets/all')
        .set('Authorization', `Bearer ${token}`);

      const unionSql = captured.find((s) => s.includes('UNION ALL'));
      expect(unionSql).toBeDefined();
      const ownedBranch = unionSql.split('UNION ALL')[0];
      expect(ownedBranch).toContain('org_pet_home_hidden');
    });
  });
});
