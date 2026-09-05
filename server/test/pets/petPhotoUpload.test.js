import request from 'supertest';
import { createApp } from '../../bin/server.js';
import { handlePetAccessQuery } from '../helpers/petAccessMocks.js';
import { createMockPool, makePetRow, token, userId, petId } from './helpers.js';

/** Minimal JPEG file header (FF D8 FF …). */
const JPEG_BUFFER = Buffer.from([
  0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0x00, 0x01,
]);

describe('POST /api/pets/:id/photo', () => {
  it('uploads a pet photo and returns normalized pet payload', async () => {
    const updatedRow = makePetRow({
      species: 'dog',
      gender: 'male',
      photo_path: '/uploads/pet_photos/test.jpg',
    });
    const app = createApp(createMockPool(async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
      if (access) return access;
      if (sql.includes('UPDATE pets SET photo_path')) return { rows: [updatedRow] };
      return { rows: [] };
    }));

    const res = await request(app)
      .post(`/api/pets/${petId}/photo`)
      .set('Authorization', `Bearer ${token}`)
      .attach('photo', JPEG_BUFFER, {
        filename: 'buddy.jpg',
        contentType: 'image/jpeg',
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.photoPath).toMatch(/^\/uploads\/pet_photos\//);
    expect(res.body.pet).toMatchObject({
      id: petId,
      species: 'Dog',
      gender: 'Male',
    });
  });

  it('returns 400 when photo file is missing', async () => {
    const app = createApp(createMockPool(async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
      if (access) return access;
      return { rows: [] };
    }));

    const res = await request(app)
      .post(`/api/pets/${petId}/photo`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toBe(400);
    expect(res.body).toEqual({ error: 'Photo file is required' });
  });

  it('returns 401 without token', async () => {
    const app = createApp(createMockPool());
    const res = await request(app)
      .post(`/api/pets/${petId}/photo`)
      .attach('photo', JPEG_BUFFER, {
        filename: 'buddy.jpg',
        contentType: 'image/jpeg',
      });
    expect(res.statusCode).toBe(401);
  });

  it('returns 404 when pet is not manageable', async () => {
    const app = createApp(createMockPool(async () => ({ rows: [] })));
    const res = await request(app)
      .post(`/api/pets/${petId}/photo`)
      .set('Authorization', `Bearer ${token}`)
      .attach('photo', JPEG_BUFFER, {
        filename: 'buddy.jpg',
        contentType: 'image/jpeg',
      });
    expect(res.statusCode).toBe(404);
    expect(res.body).toEqual({ error: 'Pet not found' });
  });
});
