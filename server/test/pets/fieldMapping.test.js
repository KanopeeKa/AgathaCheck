import request from 'supertest';
import { createApp } from '../../bin/server.js';
import { createMockPool, makePetRow, token, petId, PET_COLOR_PALETTE } from './helpers.js';

describe('Pets API', () => {
  describe('Response field mapping', () => {
    it('maps all camelCase fields correctly', async () => {
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
        if (sql.includes('EXISTS') && sql.includes('AS is_foster') && sql.includes('WHERE p.id = $1')) return { rows: [row] };
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
});
