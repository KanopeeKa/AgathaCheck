import request from 'supertest';
import { createApp } from '../../bin/server.js';
import { handlePetAccessQuery } from '../helpers/petAccessMocks.js';
import { createMockPool, makePetRow, token, userId, petId } from './helpers.js';

describe('Pets API', () => {
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
      const app = createApp(createMockPool(async (sql, params) => {
        const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
        if (access) return access;
        if (sql.includes('SELECT organization_id FROM pets WHERE id = $1')) {
          return { rows: [{ organization_id: null }] };
        }
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
      const app = createApp(createMockPool(async (sql, params) => {
        const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
        if (access) return access;
        if (sql.includes('SELECT organization_id FROM pets WHERE id = $1')) {
          return { rows: [{ organization_id: null }] };
        }
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
});
