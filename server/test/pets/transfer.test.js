import request from 'supertest';
import { createApp } from '../../bin/server.js';
import { handlePetAccessQuery } from '../helpers/petAccessMocks.js';
import { createMockPool, makePetRow, token, userId, petId, petId2 } from './helpers.js';

const recipientId = 'recipient-user-id';
const recipientEmail = 'newowner@example.com';

function createTransferPool(customEmailHandler) {
  let updatedOwnerId = null;
  let archivedInsert = null;
  let sharedAccessInsert = null;

  const pool = createMockPool(async (sql, params) => {
    if (sql.includes('SELECT id, name, species, organization_id, user_id FROM pets')) {
      return { rows: [makePetRow({ name: 'Fluffy', user_id: userId })] };
    }
    if (sql.includes('SELECT id, email, first_name, last_name FROM users WHERE email')) {
      if (customEmailHandler) return customEmailHandler(sql, params);
      return {
        rows: [{ id: recipientId, email: recipientEmail, first_name: 'New', last_name: 'Owner' }],
      };
    }
    if (sql.includes('UPDATE pets SET user_id')) {
      updatedOwnerId = params[0];
      return { rows: [makePetRow({ user_id: params[0] })] };
    }
    if (sql.includes('DELETE FROM pet_access WHERE pet_id = $1 AND user_id = $2')) {
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO pet_access') && sql.includes('ON CONFLICT')) {
      sharedAccessInsert = params;
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO archived_pets')) {
      archivedInsert = params;
      return { rows: [] };
    }
    const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId, petId2] });
    if (access) return access;
    if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2')) {
      return { rows: [{ '?column?': 1 }] };
    }
    if (sql.includes('SELECT first_name, last_name, email FROM users')) {
      return { rows: [{ first_name: 'Test', last_name: 'User', email: 'test@example.com' }] };
    }
    if (sql.includes('INSERT INTO notifications')) {
      return { rows: [] };
    }
    return { rows: [] };
  });

  return {
    pool,
    get updatedOwnerId() { return updatedOwnerId; },
    get archivedInsert() { return archivedInsert; },
    get sharedAccessInsert() { return sharedAccessInsert; },
  };
}

describe('Pets API', () => {
  describe('POST /:id/transfer (ownership)', () => {
    it('transfers ownership to another user', async () => {
      const transferPool = createTransferPool();
      const app = createApp(transferPool.pool);
      const res = await request(app)
        .post(`/api/pets/${petId}/transfer`)
        .set('Authorization', `Bearer ${token}`)
        .send({ recipient_email: recipientEmail, confirmation_name: 'Fluffy' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('transferred', true);
      expect(res.body).toHaveProperty('new_owner_id', recipientId);
      expect(transferPool.updatedOwnerId).toBe(recipientId);
      expect(transferPool.archivedInsert[6]).toBe('user_to_user');
      expect(transferPool.archivedInsert[7]).toBe(recipientId);
      expect(transferPool.sharedAccessInsert[2]).toBe(userId);
    });

    it('returns 400 when confirmation name does not match', async () => {
      const { pool } = createTransferPool();
      const app = createApp(pool);
      const res = await request(app)
        .post(`/api/pets/${petId}/transfer`)
        .set('Authorization', `Bearer ${token}`)
        .send({ recipient_email: recipientEmail, confirmation_name: 'Wrong' });
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/confirmation/i);
    });

    it('returns 404 when recipient is not found', async () => {
      const { pool } = createTransferPool(() => ({ rows: [] }));
      const app = createApp(pool);
      const res = await request(app)
        .post(`/api/pets/${petId}/transfer`)
        .set('Authorization', `Bearer ${token}`)
        .send({ recipient_email: 'missing@example.com', confirmation_name: 'Fluffy' });
      expect(res.statusCode).toBe(404);
    });

    it('returns 403 when caller is not the owner', async () => {
      const app = createApp(createMockPool(async (sql, params) => {
        const access = handlePetAccessQuery(sql, params, {
          userId,
          ownedPetIds: [],
          deniedPetIds: [petId],
        });
        if (access) return access;
        return { rows: [] };
      }));
      const res = await request(app)
        .post(`/api/pets/${petId}/transfer`)
        .set('Authorization', `Bearer ${token}`)
        .send({ recipient_email: recipientEmail, confirmation_name: 'Fluffy' });
      expect(res.statusCode).toBe(403);
    });
  });
});
