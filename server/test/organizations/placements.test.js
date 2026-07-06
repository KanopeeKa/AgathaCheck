import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import { buildMockPool, makeOrgRow } from './helpers.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';
const memberId = 'member-user-id';
const inviteId = 'invite-1';


describe('Organizations API', () => {
  let app;

  beforeAll(() => {
    app = createApp(buildMockPool());
  });

  describe('GET /:orgId/pets/:petId/foster-history', () => {
      it('returns placement history for an org pet', async () => {
        const pool = buildMockPool({
          query: async (sql) => {
            if (sql.includes('SELECT id FROM pets WHERE id = $1 AND organization_id = $2')) {
              return { rows: [{ id: 'pet-1' }] };
            }
            if (sql.includes('FROM foster_placements fp') && sql.includes('fp.pet_id = $2')) {
              return {
                rows: [{
                  id: 'placement-1',
                  organization_id: orgId,
                  pet_id: 'pet-1',
                  foster_user_id: 'foster-1',
                  org_foster_parent_id: null,
                  status: 'adopted',
                  start_date: '2024-01-01',
                  end_date: '2024-06-01',
                  notes: 'Good home',
                  adoption_conditions: '',
                  created_at: new Date('2024-01-01'),
                  updated_at: new Date('2024-06-01'),
                  pet_name: 'Buddy',
                  pet_species: 'dog',
                  organization_name: 'Test Org',
                  foster_name: 'Jane Foster',
                  foster_email: 'jane@example.com',
                }],
              };
            }
            return { rows: [] };
          },
        });
        const res = await request(createApp(pool))
          .get(`/api/organizations/${orgId}/pets/pet-1/foster-history`)
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(200);
        expect(res.body).toHaveLength(1);
        expect(res.body[0]).toMatchObject({
          pet_id: 'pet-1',
          status: 'adopted',
          foster_name: 'Jane Foster',
        });
      });
    });
  
  describe('POST /:orgId/pets/:petId/transfer', () => {
      it('transfers org pet to recipient by email', async () => {
        let newOwnerId = null;
        const innerQuery = async (sql, params) => {
          if (sql.includes('SELECT id FROM users WHERE email')) {
            return { rows: [{ id: 'recipient-1' }] };
          }
          if (sql.includes('SELECT id, name, species, user_id, organization_id FROM pets WHERE id = $1 AND organization_id = $2')) {
            return { rows: [{ id: 'pet-1', name: 'Buddy', species: 'dog', user_id: userId, organization_id: orgId }] };
          }
          if (sql.includes('SELECT id, first_name, last_name, email FROM users WHERE id = $1')) {
            return { rows: [{ id: params[0], first_name: 'New', last_name: 'Owner', email: 'new@example.com' }] };
          }
          if (sql.includes('SELECT fp.*') && sql.includes('WHERE fp.pet_id = $1')) {
            return { rows: [] };
          }
          if (sql.includes('UPDATE pets') && sql.includes('user_id = $1')) {
            newOwnerId = params[0];
            return { rows: [] };
          }
          if (sql.includes('DELETE FROM pet_access')) return { rows: [] };
          if (sql.includes('INSERT INTO archived_pets')) return { rows: [] };
          if (sql.includes('INSERT INTO notifications')) return { rows: [] };
          if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') return { rows: [] };
          return { rows: [] };
        };
        const pool = buildMockPool({
          query: innerQuery,
          connect: async () => ({
            query: innerQuery,
            release: () => {},
          }),
        });
        const res = await request(createApp(pool))
          .post(`/api/organizations/${orgId}/pets/pet-1/transfer`)
          .set('Authorization', `Bearer ${token}`)
          .send({ recipient_email: 'new@example.com' });
        expect(res.statusCode).toBe(200);
        expect(res.body).toHaveProperty('transferred', true);
        expect(newOwnerId).toBe('recipient-1');
      });
  
      it('returns 400 without recipient email', async () => {
        const res = await request(app)
          .post(`/api/organizations/${orgId}/pets/pet-1/transfer`)
          .set('Authorization', `Bearer ${token}`)
          .send({});
        expect(res.statusCode).toBe(400);
      });
    });
});
