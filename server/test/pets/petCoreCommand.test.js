import request from 'supertest';
import { createApp } from '../../bin/server.js';
import { handlePetAccessQuery } from '../helpers/petAccessMocks.js';
import { createMockPool, makePetRow, token, userId, petId } from './helpers.js';

describe('petCoreCommandService behaviour', () => {
  describe('POST /api/pets id conflict', () => {
    it('returns 409 when client id is already owned by another user and does not write weight', async () => {
      const queries = [];
      const app = createApp(createMockPool(async (sql, params) => {
        queries.push({ sql, params });
        if (sql.includes('FROM weight_entries')) return { rows: [] };
        if (sql.includes('INSERT INTO weight_entries')) return { rows: [] };
        if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
        if (sql.includes('INSERT INTO pets')) return { rows: [] };
        return null;
      }));
      const res = await request(app)
        .post('/api/pets')
        .set('Authorization', `Bearer ${token}`)
        .send({ id: petId, name: 'Fluffy', species: 'cat', weight: 4.5 });
      expect(res.statusCode).toBe(409);
      expect(res.body).toEqual({ error: 'Pet id already in use' });
      expect(queries.some((q) => q.sql.includes('INSERT INTO weight_entries'))).toBe(false);
    });
  });

  describe('PUT /api/pets/:id partial update', () => {
    const existingRow = {
      organization_id: 'org-uuid-1',
      photo_path: '/uploads/fluffy.jpg',
      weight_reference_value: null,
      weight_reference_authority: null,
      weight_management_context: 'none',
      home_timezone: 'UTC',
      name: 'Fluffy',
      species: 'cat',
      breed: 'Persian',
      age: 3,
      date_of_birth: '2021-01-15',
      gender: 'female',
      bio: 'bio',
      insurance: 'ins',
      neutered_date: '2022-06-01',
      neuter_dismissed: false,
      chip_id: 'CHIP-KEEP',
      chip_dismissed: false,
      vet_id: 'vet-uuid-1',
      color_index: 2,
      passed_away: true,
    };

    function buildUpdateApp(onUpdate) {
      return createApp(createMockPool(async (sql, params) => {
        const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
        if (access) return access;
        if (sql.includes('SELECT') && sql.includes('FROM pets WHERE id = $1')) {
          return { rows: [existingRow] };
        }
        if (sql.includes('FROM weight_entries')) return { rows: [{ weight: 4.5 }] };
        if (sql.includes('INSERT INTO weight_entries')) return { rows: [] };
        if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
        if (sql.includes('UPDATE pets SET name=$1')) {
          onUpdate(params);
          return { rows: [makePetRow({ name: params[0], passed_away: params[21], chip_id: params[10], organization_id: params[22] })] };
        }
        if (sql.includes('SELECT * FROM pets WHERE id = $1')) {
          return { rows: [makePetRow()] };
        }
        return null;
      }));
    }

    it('preserves passedAway, chipId, and organization_id when only name is sent', async () => {
      let capturedParams;
      const app = buildUpdateApp((params) => { capturedParams = params; });
      const res = await request(app)
        .put(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Renamed only' });
      expect(res.statusCode).toBe(200);
      expect(capturedParams[0]).toBe('Renamed only');
      expect(capturedParams[10]).toBe('CHIP-KEEP');
      expect(capturedParams[21]).toBe(true);
      expect(capturedParams[22]).toBe('org-uuid-1');
    });

    it('clears organization_id and chipId when explicit null is sent', async () => {
      let capturedParams;
      const app = buildUpdateApp((params) => { capturedParams = params; });
      const res = await request(app)
        .put(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Fluffy', organization_id: null, chipId: null });
      expect(res.statusCode).toBe(200);
      expect(capturedParams[10]).toBe('');
      expect(capturedParams[16]).toBeNull();
    });
  });
});
