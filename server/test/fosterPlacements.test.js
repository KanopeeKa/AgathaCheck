import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';
import {
  PLACEMENT_STATUS_IN_PROGRESS,
  PLACEMENT_STATUS_NOT_IN_FOSTER,
  PLACEMENT_STATUS_PENDING,
} from '../lib/fosterPlacements.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const adminId = 'admin-user-id';
const fosterId = 'foster-user-id';
const adminToken = jwt.sign({ id: adminId, email: 'admin@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const fosterToken = jwt.sign({ id: fosterId, email: 'foster@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';
const petId = 'pet-1';
const placementId = 'placement-1';

function makePlacementRow(status) {
  return {
    id: placementId,
    organization_id: orgId,
    pet_id: petId,
    foster_user_id: fosterId,
    org_foster_parent_id: null,
    status,
    start_date: null,
    end_date: null,
    notes: '',
    created_by: adminId,
    created_at: new Date('2024-01-01'),
    updated_at: new Date('2024-01-01'),
    responded_at: null,
    pet_name: 'Buddy',
    pet_species: 'dog',
    organization_name: 'Test Org',
    foster_name: 'Jane Foster',
    foster_email: 'foster@example.com',
  };
}

function buildMockPool() {
  let placementStatus = null;
  let fosterAccessGranted = false;

  const query = async (sql, params) => {
    if (sql.includes('SELECT role FROM organization_users WHERE organization_id')) {
      const uid = params[1];
      if (uid === adminId) return { rows: [{ role: 'admin' }] };
      if (uid === fosterId) return { rows: [{ role: 'foster' }] };
      return { rows: [] };
    }
    if (sql.includes('FROM foster_placements fp') && sql.includes('fp.foster_user_id = $1')) {
      if (placementStatus !== PLACEMENT_STATUS_PENDING) return { rows: [] };
      return { rows: [makePlacementRow(PLACEMENT_STATUS_PENDING)] };
    }
    if (sql.includes('SELECT * FROM foster_placements WHERE id = $1 AND organization_id')) {
      if (!placementStatus) return { rows: [] };
      return { rows: [makePlacementRow(placementStatus)] };
    }
    if (sql.includes('SELECT * FROM foster_placements WHERE id = $1')) {
      if (!placementStatus) return { rows: [] };
      return { rows: [makePlacementRow(placementStatus)] };
    }
    if (sql.includes('SELECT fp.*') && sql.includes('WHERE fp.pet_id = $1')) {
      if (!placementStatus || placementStatus === PLACEMENT_STATUS_NOT_IN_FOSTER) {
        return { rows: [] };
      }
      return { rows: [makePlacementRow(placementStatus)] };
    }
    if (sql.includes('SELECT id, name FROM pets WHERE id = $1 AND organization_id')) {
      return { rows: [{ id: petId, name: 'Buddy' }] };
    }
    if (sql.includes('SELECT id FROM pets WHERE id = $1 AND organization_id = $2')) {
      return { rows: [{ id: petId }] };
    }
    if (sql.includes('SELECT name FROM pets WHERE id = $1')) {
      return { rows: [{ name: 'Buddy' }] };
    }
    if (sql.includes('INSERT INTO foster_placements')) {
      placementStatus = PLACEMENT_STATUS_PENDING;
      return { rows: [makePlacementRow(PLACEMENT_STATUS_PENDING)] };
    }
    if (sql.includes('UPDATE foster_placements') && params[0] === PLACEMENT_STATUS_IN_PROGRESS) {
      placementStatus = PLACEMENT_STATUS_IN_PROGRESS;
      fosterAccessGranted = true;
      return { rows: [makePlacementRow(PLACEMENT_STATUS_IN_PROGRESS)] };
    }
    if (sql.includes('UPDATE foster_placements') && params[0] === PLACEMENT_STATUS_NOT_IN_FOSTER) {
      const ended = makePlacementRow(PLACEMENT_STATUS_NOT_IN_FOSTER);
      placementStatus = PLACEMENT_STATUS_NOT_IN_FOSTER;
      fosterAccessGranted = false;
      return { rows: [ended] };
    }
    if (sql.includes('INSERT INTO pet_access') && sql.includes("'foster'")) {
      fosterAccessGranted = true;
      return { rows: [] };
    }
    if (sql.includes('DELETE FROM pet_access') && sql.includes('role = $3')) {
      fosterAccessGranted = false;
      return { rows: [] };
    }
    if (sql.includes('SELECT first_name, last_name, email FROM users')) {
      return { rows: [{ first_name: 'Test', last_name: 'User', email: 'test@example.com' }] };
    }
    if (sql.includes('INSERT INTO notifications')) {
      return { rows: [] };
    }
    if (sql.includes('FROM foster_placements fp') && sql.includes('WHERE fp.organization_id')) {
      if (!placementStatus || placementStatus === PLACEMENT_STATUS_NOT_IN_FOSTER) {
        return { rows: [] };
      }
      return { rows: [makePlacementRow(placementStatus)] };
    }
    if (sql.includes('WHERE fp.id = $1')) {
      if (!placementStatus) return { rows: [] };
      return { rows: [makePlacementRow(placementStatus)] };
    }
    return { rows: [] };
  };

  return {
    query,
    get fosterAccessGranted() { return fosterAccessGranted; },
    setPlacementPending() { placementStatus = PLACEMENT_STATUS_PENDING; },
  };
}

describe('Foster placements API', () => {
  describe('Auth guard', () => {
    let app;
    beforeAll(() => {
      app = createApp(buildMockPool());
    });

    it('GET /pending returns 401 without token', async () => {
      const res = await request(app).get('/api/foster-placements/pending');
      expect(res.statusCode).toBe(401);
    });

    it('POST /:id/accept returns 401 without token', async () => {
      const res = await request(app).post(`/api/foster-placements/${placementId}/accept`);
      expect(res.statusCode).toBe(401);
    });
  });

  describe('Foster user flow', () => {
    it('lists pending placements for the foster parent', async () => {
      const pool = buildMockPool();
      pool.setPlacementPending();
      const app = createApp(pool);
      const res = await request(app)
        .get('/api/foster-placements/pending')
        .set('Authorization', `Bearer ${fosterToken}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveLength(1);
      expect(res.body[0]).toMatchObject({
        id: placementId,
        pet_name: 'Buddy',
        status: PLACEMENT_STATUS_PENDING,
      });
    });

    it('accepts a pending placement and grants foster access', async () => {
      const pool = buildMockPool();
      pool.setPlacementPending();
      const app = createApp(pool);
      const res = await request(app)
        .post(`/api/foster-placements/${placementId}/accept`)
        .set('Authorization', `Bearer ${fosterToken}`);
      expect(res.statusCode).toBe(200);
      expect(res.body.status).toBe(PLACEMENT_STATUS_IN_PROGRESS);
      expect(pool.fosterAccessGranted).toBe(true);
    });

    it('declines a pending placement', async () => {
      const pool = buildMockPool();
      pool.setPlacementPending();
      const app = createApp(pool);
      const res = await request(app)
        .post(`/api/foster-placements/${placementId}/decline`)
        .set('Authorization', `Bearer ${fosterToken}`);
      expect(res.statusCode).toBe(200);
      expect(res.body.status).toBe(PLACEMENT_STATUS_NOT_IN_FOSTER);
    });
  });

  describe('Admin org placement flow', () => {
    it('starts a foster placement for an org pet', async () => {
      const app = createApp(buildMockPool());
      const res = await request(app)
        .post(`/api/organizations/${orgId}/pets/${petId}/placements`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ foster_user_id: fosterId, notes: 'Two week trial' });
      expect(res.statusCode).toBe(201);
      expect(res.body).toMatchObject({
        pet_id: petId,
        foster_user_id: fosterId,
        status: PLACEMENT_STATUS_PENDING,
      });
    });

    it('returns current placement for an org pet', async () => {
      const pool = buildMockPool();
      pool.setPlacementPending();
      const app = createApp(pool);
      const res = await request(app)
        .get(`/api/organizations/${orgId}/pets/${petId}/placement`)
        .set('Authorization', `Bearer ${adminToken}`);
      expect(res.statusCode).toBe(200);
      expect(res.body.placement).toMatchObject({ pet_id: petId });
    });

    it('ends an in-progress placement', async () => {
      const pool = buildMockPool();
      pool.setPlacementPending();
      const app = createApp(pool);
      await request(app)
        .post(`/api/foster-placements/${placementId}/accept`)
        .set('Authorization', `Bearer ${fosterToken}`);

      const res = await request(app)
        .post(`/api/organizations/${orgId}/placements/${placementId}/end`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({});
      expect(res.statusCode).toBe(200);
      expect(res.body.status).toBe(PLACEMENT_STATUS_NOT_IN_FOSTER);
    });

    it('GET /:orgId/placements returns 403 for foster', async () => {
      const app = createApp(buildMockPool());
      const res = await request(app)
        .get(`/api/organizations/${orgId}/placements`)
        .set('Authorization', `Bearer ${fosterToken}`);
      expect(res.statusCode).toBe(403);
    });
  });
});
