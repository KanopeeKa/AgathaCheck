import request from 'supertest';
import { createApp } from '../../bin/server.js';
import { createMockPool, makePetRow, token, petId, petId2, PET_COLOR_PALETTE } from './helpers.js';

describe('Pets API', () => {
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
});
