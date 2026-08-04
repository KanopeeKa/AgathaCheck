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

  describe('People directory', () => {
      it('GET /:orgId/people returns redacted summary for foster role', async () => {
        const pool = buildMockPool({
          memberRole: 'foster',
          query: async (sql) => {
            if (sql.includes('primary_contact_ref FROM organizations')) {
              return { rows: [{ primary_contact_ref: null }] };
            }
            if (sql.includes('FROM organization_users ou') && sql.includes('JOIN users u')) {
              return {
                rows: [{
                  kind: 'member',
                  record_id: 'ou-1',
                  user_id: memberId,
                  display_name: 'Grace Admin',
                  email: 'grace@example.com',
                  photo_url: null,
                  role: 'admin',
                  is_pending: false,
                  active_foster_count: 2,
                }],
              };
            }
            if (sql.includes('FROM org_foster_parents fp')) {
              return { rows: [] };
            }
            return { rows: [] };
          },
        });
        const fosterApp = createApp(pool);
        const res = await request(fosterApp)
          .get(`/api/organizations/${orgId}/people`)
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(200);
        expect(res.body[0]).toMatchObject({
          display_name: 'Grace Admin',
          email: null,
          active_foster_count: 2,
        });
      });

      it('GET /:orgId/people returns 403 without view_admin_contacts membership', async () => {
        const pendingApp = createApp(buildMockPool({ memberRole: 'pending_foster' }));
        const res = await request(pendingApp)
          .get(`/api/organizations/${orgId}/people`)
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(403);
      });

      it('GET /:orgId/people/:kind/:personId redacts detail for foster viewers', async () => {
        const pool = buildMockPool({
          memberRole: 'foster',
          query: async (sql) => {
            if (sql.includes('primary_contact_ref FROM organizations')) {
              return { rows: [{ primary_contact_ref: null }] };
            }
            if (sql.includes('FROM organization_users ou') && sql.includes('ou.id = $2')) {
              return {
                rows: [{
                  kind: 'member',
                  record_id: 'ou-1',
                  user_id: memberId,
                  display_name: 'Other Admin',
                  email: 'admin@example.com',
                  photo_url: '/photos/admin.jpg',
                  role: 'admin',
                  is_pending: false,
                  foster_phone: '555-2222',
                  foster_address: '9 Admin Rd',
                  admin_notes: 'Team lead',
                  active_foster_count: 0,
                }],
              };
            }
            if (sql.includes('FROM foster_placements fp') && sql.includes('fp.foster_user_id = $2')) {
              return { rows: [] };
            }
            if (sql.includes('SELECT DISTINCT ON (pet_id)')) {
              return { rows: [] };
            }
            return { rows: [] };
          },
        });
        const localApp = createApp(pool);
        const res = await request(localApp)
          .get(`/api/organizations/${orgId}/people/member/ou-1`)
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(200);
        expect(res.body).toMatchObject({
          display_name: 'Other Admin',
          email: null,
          foster_phone: '',
          foster_address: '',
          admin_notes: '',
        });
        expect(res.body.current_placements).toEqual([]);
        expect(res.body.past_placements).toEqual([]);
      });
  
      it('GET /:orgId/people/:kind/:personId returns member detail', async () => {
        const pool = buildMockPool({
          query: async (sql) => {
            if (sql.includes('SELECT role FROM organization_users WHERE organization_id')) {
              return { rows: [{ role: 'super_admin' }] };
            }
            if (sql.includes('FROM organization_users ou') && sql.includes('ou.id = $2')) {
              return {
                rows: [{
                  kind: 'member',
                  record_id: 'ou-1',
                  user_id: memberId,
                  display_name: 'Other Admin',
                  email: 'admin@example.com',
                  photo_url: '/photos/admin.jpg',
                  role: 'admin',
                  is_pending: false,
                  foster_phone: '555-2222',
                  foster_address: '9 Admin Rd',
                  admin_notes: 'Team lead',
                  active_foster_count: 0,
                }],
              };
            }
            if (sql.includes('FROM foster_placements fp') && sql.includes('fp.foster_user_id = $2')) {
              return { rows: [] };
            }
            if (sql.includes('SELECT DISTINCT ON (pet_id)')) {
              return { rows: [] };
            }
            return { rows: [] };
          },
        });
        const localApp = createApp(pool);
        const res = await request(localApp)
          .get(`/api/organizations/${orgId}/people/member/ou-1`)
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(200);
        expect(res.body).toMatchObject({
          kind: 'member',
          record_id: 'ou-1',
          display_name: 'Other Admin',
          role: 'admin',
          foster_phone: '555-2222',
          foster_address: '9 Admin Rd',
          admin_notes: 'Team lead',
        });
      });
  
      it('GET /:orgId/people/:kind/:personId returns external foster detail', async () => {
        const pool = buildMockPool({
          query: async (sql) => {
            if (sql.includes('SELECT role FROM organization_users WHERE organization_id')) {
              return { rows: [{ role: 'super_admin' }] };
            }
            if (sql.includes('FROM org_foster_parents fp') && sql.includes('fp.id = $2')) {
              return {
                rows: [{
                  kind: 'external',
                  record_id: 'fp-external-1',
                  user_id: null,
                  display_name: 'Off-app Parent',
                  email: 'offapp@example.com',
                  photo_url: null,
                  role: null,
                  is_pending: false,
                  foster_phone: '555-0000',
                  foster_address: '1 Main St',
                  admin_notes: 'Notes',
                  active_foster_count: 0,
                }],
              };
            }
            if (sql.includes('FROM foster_placements fp') && sql.includes('org_foster_parent_id = $2')) {
              return { rows: [] };
            }
            if (sql.includes('SELECT DISTINCT ON (pet_id)')) {
              return { rows: [] };
            }
            return { rows: [] };
          },
        });
        const localApp = createApp(pool);
        const res = await request(localApp)
          .get(`/api/organizations/${orgId}/people/external/fp-external-1`)
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(200);
        expect(res.body).toMatchObject({
          kind: 'external',
          record_id: 'fp-external-1',
          display_name: 'Off-app Parent',
          foster_phone: '555-0000',
          foster_address: '1 Main St',
          admin_notes: 'Notes',
        });
      });
  
      it('PUT /:orgId/people/external/:id/contact updates external foster contact', async () => {
        const pool = buildMockPool({
          query: async (sql) => {
            if (sql.includes('SELECT role FROM organization_users WHERE organization_id')) {
              return { rows: [{ role: 'super_admin' }] };
            }
            if (sql.includes('UPDATE org_foster_parents')) {
              return { rows: [{ id: 'fp-external-1' }] };
            }
            if (sql.includes('FROM org_foster_parents fp') && sql.includes('fp.id = $2')) {
              return {
                rows: [{
                  kind: 'external',
                  record_id: 'fp-external-1',
                  user_id: null,
                  display_name: 'Updated Parent',
                  email: 'updated@example.com',
                  photo_url: null,
                  role: null,
                  is_pending: false,
                  foster_phone: '555-1111',
                  foster_address: '2 Oak Ave',
                  admin_notes: 'Updated notes',
                  active_foster_count: 0,
                }],
              };
            }
            if (sql.includes('FROM foster_placements fp') && sql.includes('org_foster_parent_id = $2')) {
              return { rows: [] };
            }
            if (sql.includes('SELECT DISTINCT ON (pet_id)')) {
              return { rows: [] };
            }
            return { rows: [] };
          },
        });
        const localApp = createApp(pool);
        const res = await request(localApp)
          .put(`/api/organizations/${orgId}/people/external/fp-external-1/contact`)
          .set('Authorization', `Bearer ${token}`)
          .send({
            display_name: 'Updated Parent',
            email: 'updated@example.com',
            foster_phone: '555-1111',
            foster_address: '2 Oak Ave',
            admin_notes: 'Updated notes',
          });
        expect(res.statusCode).toBe(200);
        expect(res.body).toMatchObject({
          display_name: 'Updated Parent',
          email: 'updated@example.com',
          foster_phone: '555-1111',
          foster_address: '2 Oak Ave',
          admin_notes: 'Updated notes',
        });
      });
  
      it('PUT /:orgId/people/external/:id/contact returns 400 without display name', async () => {
        const pool = buildMockPool({
          query: async (sql) => {
            if (sql.includes('SELECT role FROM organization_users WHERE organization_id')) {
              return { rows: [{ role: 'super_admin' }] };
            }
            return { rows: [] };
          },
        });
        const localApp = createApp(pool);
        const res = await request(localApp)
          .put(`/api/organizations/${orgId}/people/external/fp-external-1/contact`)
          .set('Authorization', `Bearer ${token}`)
          .send({ display_name: '   ' });
        expect(res.statusCode).toBe(400);
      });
    });
});
