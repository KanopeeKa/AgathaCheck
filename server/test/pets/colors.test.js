import request from 'supertest';
import { createApp } from '../../bin/server.js';
import { createMockPool, makePetRow, token, petId, PET_COLOR_PALETTE } from './helpers.js';

describe('Pets API', () => {
  describe('colorValue field', () => {
    it('returns null colorValue when color_index is null', async () => {
      const row = makePetRow({ color_index: null });
      const app = createApp(createMockPool(async (sql) => {
        if (sql.includes('SELECT * FROM pets')) return { rows: [row] };
        return { rows: [] };
      }));
      const res = await request(app)
        .get('/api/pets')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body[0].colorValue).toBeNull();
    });

    it('resolves palette index when color_index is set', async () => {
      const row = makePetRow({ id: petId, color_index: 0 });
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
  });
});
