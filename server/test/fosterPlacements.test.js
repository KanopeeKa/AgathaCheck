import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';
import {
  PLACEMENT_STATUS_ADOPTED,
  PLACEMENT_STATUS_IN_PROGRESS,
  PLACEMENT_STATUS_NOT_IN_FOSTER,
  PLACEMENT_STATUS_PENDING,
  PLACEMENT_STATUS_PENDING_CONDITIONS,
  PLACEMENT_STATUS_WAITING_ADOPTION,
  SESSION_STATUS_ACTIVE,
  SESSION_STATUS_ADOPTION_IN_PROGRESS,
  SESSION_STATUS_CANCELLED,
  SESSION_STATUS_CONVERTED_TO_ADOPTION,
  SESSION_STATUS_END_PENDING_CONFIRMATION,
  SESSION_STATUS_PENDING_ACCEPTANCE,
  normalizePlacementStatus,
  OPEN_PLACEMENT_STATUSES,
  placementToMap,
  toLegacyStatus,
} from '../lib/fosterPlacements.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const adminId = 'admin-user-id';
const fosterId = 'foster-user-id';
const adminToken = jwt.sign({ id: adminId, email: 'admin@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const fosterToken = jwt.sign({ id: fosterId, email: 'foster@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';
const petId = 'pet-1';
const placementId = 'placement-1';
const journeyId = 'journey-1';

describe('fostering session schema (J3 Phase 1)', () => {
  it('maps legacy statuses to target session statuses (appendix §3.1)', () => {
    expect(normalizePlacementStatus(PLACEMENT_STATUS_PENDING)).toBe(SESSION_STATUS_PENDING_ACCEPTANCE);
    expect(normalizePlacementStatus(PLACEMENT_STATUS_IN_PROGRESS)).toBe(SESSION_STATUS_ACTIVE);
    expect(normalizePlacementStatus(PLACEMENT_STATUS_WAITING_ADOPTION)).toBe(SESSION_STATUS_ADOPTION_IN_PROGRESS);
    expect(normalizePlacementStatus(PLACEMENT_STATUS_PENDING_CONDITIONS)).toBe(SESSION_STATUS_ADOPTION_IN_PROGRESS);
    expect(normalizePlacementStatus(PLACEMENT_STATUS_ADOPTED)).toBe(SESSION_STATUS_CONVERTED_TO_ADOPTION);
    expect(normalizePlacementStatus(PLACEMENT_STATUS_NOT_IN_FOSTER)).toBe(SESSION_STATUS_CANCELLED);
  });

  it('passes through canonical session statuses unchanged', () => {
    expect(normalizePlacementStatus(SESSION_STATUS_ACTIVE)).toBe(SESSION_STATUS_ACTIVE);
    expect(normalizePlacementStatus(SESSION_STATUS_PENDING_ACCEPTANCE)).toBe(SESSION_STATUS_PENDING_ACCEPTANCE);
  });

  it('maps adoption_in_progress with conditions to legacy pending_adoption_conditions', () => {
    expect(toLegacyStatus(SESSION_STATUS_ADOPTION_IN_PROGRESS, { adoption_conditions: 'Neuter first' }))
      .toBe(PLACEMENT_STATUS_PENDING_CONDITIONS);
    expect(toLegacyStatus(SESSION_STATUS_ADOPTION_IN_PROGRESS, { adoption_conditions: '' }))
      .toBe(PLACEMENT_STATUS_WAITING_ADOPTION);
  });

  it('maps session statuses back to legacy API values', () => {
    expect(toLegacyStatus(SESSION_STATUS_PENDING_ACCEPTANCE)).toBe(PLACEMENT_STATUS_PENDING);
    expect(toLegacyStatus(SESSION_STATUS_ACTIVE)).toBe(PLACEMENT_STATUS_IN_PROGRESS);
    expect(toLegacyStatus(SESSION_STATUS_ADOPTION_IN_PROGRESS)).toBe(PLACEMENT_STATUS_WAITING_ADOPTION);
    expect(toLegacyStatus(SESSION_STATUS_CONVERTED_TO_ADOPTION)).toBe(PLACEMENT_STATUS_ADOPTED);
    expect(toLegacyStatus(SESSION_STATUS_CANCELLED)).toBe(PLACEMENT_STATUS_NOT_IN_FOSTER);
  });

  it('includes legacy and target statuses in OPEN_PLACEMENT_STATUSES during dual-write', () => {
    expect(OPEN_PLACEMENT_STATUSES).toEqual(expect.arrayContaining([
      PLACEMENT_STATUS_PENDING,
      PLACEMENT_STATUS_IN_PROGRESS,
      SESSION_STATUS_PENDING_ACCEPTANCE,
      SESSION_STATUS_ACTIVE,
      SESSION_STATUS_ADOPTION_IN_PROGRESS,
    ]));
  });

  it('placementToMap exposes session fields and dual-write status fields', () => {
    const row = {
      id: placementId,
      organization_id: orgId,
      pet_id: petId,
      foster_user_id: fosterId,
      org_foster_parent_id: 'rel-1',
      shelter_foster_relationship_id: 'rel-1',
      session_type: 'standard_foster',
      foster_request_response_id: 'response-1',
      shelter_start_confirmed_at: new Date('2024-02-01'),
      foster_start_confirmed_at: new Date('2024-02-02'),
      status: SESSION_STATUS_ACTIVE,
      start_date: '2024-02-01',
      end_date: null,
      notes: 'notes',
      adoption_conditions: '',
      created_by: adminId,
      created_at: new Date('2024-01-01'),
      updated_at: new Date('2024-02-02'),
      responded_at: new Date('2024-02-02'),
    };

    expect(placementToMap(row)).toMatchObject({
      status: PLACEMENT_STATUS_IN_PROGRESS,
      session_status: SESSION_STATUS_ACTIVE,
      shelter_foster_relationship_id: 'rel-1',
      session_type: 'standard_foster',
      foster_request_response_id: 'response-1',
      shelter_start_confirmed_at: row.shelter_start_confirmed_at,
      foster_start_confirmed_at: row.foster_start_confirmed_at,
    });
  });
});

function makePlacementRow(status, adoptionConditions = '') {
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
    adoption_conditions: adoptionConditions,
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
  let placementAdoptionConditions = '';
  let journeyStatus = null;
  let journeyConditions = '';
  let fosterAccessGranted = false;
  let adoptedOwnerId = null;

  const rowForStatus = (status) => makePlacementRow(status, placementAdoptionConditions);

  const handleQuery = async (sql, params) => {
    if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
      return { rows: [] };
    }
    if (sql.includes('SELECT role FROM organization_users WHERE organization_id')) {
      const uid = params[1];
      if (uid === adminId) return { rows: [{ role: 'admin' }] };
      if (uid === fosterId) return { rows: [{ role: 'foster' }] };
      return { rows: [] };
    }
    if (sql.includes('FROM adoption_journeys') && sql.includes('fostering_session_id = $1')) {
      if (!journeyStatus) return { rows: [] };
      return {
        rows: [{
          id: journeyId,
          organization_id: orgId,
          fostering_session_id: placementId,
          pet_id: petId,
          foster_user_id: fosterId,
          status: journeyStatus,
          adoption_conditions: journeyConditions,
          started_at: new Date('2024-03-01'),
          finalised_at: null,
          cancelled_at: null,
          created_by: adminId,
          created_at: new Date('2024-03-01'),
          updated_at: new Date('2024-03-01'),
        }],
      };
    }
    if (sql.includes('INSERT INTO adoption_journeys')) {
      journeyStatus = params[5];
      journeyConditions = params[6] || '';
      placementStatus = SESSION_STATUS_ADOPTION_IN_PROGRESS;
      placementAdoptionConditions = journeyConditions;
      return {
        rows: [{
          id: journeyId,
          organization_id: orgId,
          fostering_session_id: placementId,
          pet_id: petId,
          foster_user_id: fosterId,
          status: journeyStatus,
          adoption_conditions: journeyConditions,
          started_at: new Date(),
          created_by: adminId,
          created_at: new Date(),
          updated_at: new Date(),
        }],
      };
    }
    if (sql.includes('UPDATE adoption_journeys') && sql.includes('finalised')) {
      journeyStatus = 'finalised';
      return { rows: [] };
    }
    if (sql.includes('UPDATE adoption_journeys') && sql.includes('cancelled')) {
      journeyStatus = 'cancelled';
      return { rows: [] };
    }
    if (sql.includes('FROM foster_placements fp') && sql.includes('LEFT JOIN adoption_journeys')) {
      if (
        placementStatus === PLACEMENT_STATUS_WAITING_ADOPTION
        || (placementStatus === SESSION_STATUS_ADOPTION_IN_PROGRESS
          && journeyStatus === 'awaiting_foster_confirmation')
      ) {
        return { rows: [rowForStatus(placementStatus)] };
      }
      return { rows: [] };
    }
    if (sql.includes('FROM foster_placements fp') && sql.includes('fp.foster_user_id = $1') && sql.includes('fp.status = $2')) {
      if (params[1] === placementStatus) {
        return { rows: [rowForStatus(placementStatus)] };
      }
      return { rows: [] };
    }
    if (sql.includes('SELECT * FROM foster_placements WHERE id = $1 AND organization_id')) {
      if (!placementStatus) return { rows: [] };
      return { rows: [rowForStatus(placementStatus)] };
    }
    if (sql.includes('SELECT * FROM foster_placements WHERE id = $1 FOR UPDATE')) {
      if (!placementStatus) return { rows: [] };
      return { rows: [rowForStatus(placementStatus)] };
    }
    if (sql.includes('SELECT * FROM foster_placements WHERE id = $1')) {
      if (!placementStatus) return { rows: [] };
      return { rows: [rowForStatus(placementStatus)] };
    }
    if (sql.includes('SELECT fp.*') && sql.includes('WHERE fp.pet_id = $1')) {
      if (!placementStatus
        || placementStatus === PLACEMENT_STATUS_NOT_IN_FOSTER
        || placementStatus === PLACEMENT_STATUS_ADOPTED
        || placementStatus === SESSION_STATUS_CANCELLED
        || placementStatus === SESSION_STATUS_CONVERTED_TO_ADOPTION) {
        return { rows: [] };
      }
      return { rows: [rowForStatus(placementStatus)] };
    }
    if (sql.includes('SELECT id, name FROM pets WHERE id = $1 AND organization_id')) {
      return { rows: [{ id: petId, name: 'Buddy' }] };
    }
    if (sql.includes('SELECT id, name, species, user_id, organization_id FROM pets WHERE id = $1')) {
      return { rows: [{ id: petId, name: 'Buddy', species: 'dog', user_id: adminId, organization_id: orgId }] };
    }
    if (sql.includes('SELECT id FROM pets WHERE id = $1 AND organization_id = $2')) {
      return { rows: [{ id: petId }] };
    }
    if (sql.includes('SELECT name FROM pets WHERE id = $1')) {
      return { rows: [{ name: 'Buddy' }] };
    }
    if (sql.includes('INSERT INTO foster_placements')) {
      placementStatus = params[4] || PLACEMENT_STATUS_PENDING;
      return { rows: [rowForStatus(placementStatus)] };
    }
    if (sql.includes('UPDATE foster_placements') && params[0] === SESSION_STATUS_END_PENDING_CONFIRMATION) {
      placementStatus = SESSION_STATUS_END_PENDING_CONFIRMATION;
      return { rows: [rowForStatus(placementStatus)] };
    }
    if (sql.includes('UPDATE foster_placements') && params[0] === PLACEMENT_STATUS_IN_PROGRESS) {
      placementStatus = PLACEMENT_STATUS_IN_PROGRESS;
      fosterAccessGranted = true;
      return { rows: [rowForStatus(PLACEMENT_STATUS_IN_PROGRESS)] };
    }
    if (sql.includes('UPDATE foster_placements') && params[0] === SESSION_STATUS_ADOPTION_IN_PROGRESS) {
      if (sql.includes("adoption_conditions = ''")) {
        placementAdoptionConditions = '';
      } else {
        placementAdoptionConditions = params[1] || '';
      }
      placementStatus = SESSION_STATUS_ADOPTION_IN_PROGRESS;
      return { rows: [rowForStatus(placementStatus)] };
    }
    if (sql.includes('UPDATE foster_placements') && params[0] === 'cancelled') {
      placementStatus = SESSION_STATUS_CANCELLED;
      fosterAccessGranted = false;
      return { rows: [rowForStatus(SESSION_STATUS_CANCELLED)] };
    }
    if (sql.includes('UPDATE foster_placements') && params[0] === PLACEMENT_STATUS_WAITING_ADOPTION) {
      placementStatus = PLACEMENT_STATUS_WAITING_ADOPTION;
      return { rows: [rowForStatus(PLACEMENT_STATUS_WAITING_ADOPTION)] };
    }
    if (sql.includes('UPDATE foster_placements') && params[0] === PLACEMENT_STATUS_PENDING_CONDITIONS) {
      placementStatus = PLACEMENT_STATUS_PENDING_CONDITIONS;
      placementAdoptionConditions = params[1] || '';
      return { rows: [rowForStatus(PLACEMENT_STATUS_PENDING_CONDITIONS)] };
    }
    if (sql.includes('UPDATE foster_placements') && (
      params[0] === PLACEMENT_STATUS_ADOPTED || params[0] === SESSION_STATUS_CONVERTED_TO_ADOPTION
    )) {
      placementStatus = SESSION_STATUS_CONVERTED_TO_ADOPTION;
      adoptedOwnerId = fosterId;
      return { rows: [rowForStatus(SESSION_STATUS_CONVERTED_TO_ADOPTION)] };
    }
    if (sql.includes('UPDATE foster_placements') && (
      params[0] === PLACEMENT_STATUS_NOT_IN_FOSTER || params[0] === SESSION_STATUS_CANCELLED
    )) {
      const ended = rowForStatus(SESSION_STATUS_CANCELLED);
      placementStatus = SESSION_STATUS_CANCELLED;
      fosterAccessGranted = false;
      return { rows: [ended] };
    }
    if (sql.includes('UPDATE pets') && sql.includes('organization_id = NULL')) {
      adoptedOwnerId = params[0];
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO archived_pets')) {
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO pet_access') && sql.includes("'foster'")) {
      fosterAccessGranted = true;
      return { rows: [] };
    }
    if (sql.includes('DELETE FROM pet_access')) {
      fosterAccessGranted = false;
      return { rows: [] };
    }
    if (sql.includes('SELECT first_name, last_name, email FROM users')) {
      return { rows: [{ first_name: 'Test', last_name: 'User', email: 'test@example.com' }] };
    }
    if (sql.includes('INSERT INTO notifications')) {
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO audit_events')) {
      return { rows: [{ id: 'audit-1' }] };
    }
    if (sql.includes('SELECT id FROM org_foster_parents')) {
      return { rows: [] };
    }
    if (sql.includes('FROM foster_placements fp') && sql.includes('WHERE fp.organization_id')) {
      if (!placementStatus || placementStatus === PLACEMENT_STATUS_NOT_IN_FOSTER) {
        return { rows: [] };
      }
      return { rows: [rowForStatus(placementStatus)] };
    }
    if (sql.includes('WHERE fp.id = $1')) {
      if (!placementStatus) return { rows: [] };
      return { rows: [rowForStatus(placementStatus)] };
    }
    return { rows: [] };
  };

  const query = handleQuery;
  const connect = async () => ({
    query: handleQuery,
    release: () => {},
  });

  return {
    query,
    connect,
    get fosterAccessGranted() { return fosterAccessGranted; },
    get adoptedOwnerId() { return adoptedOwnerId; },
    setPlacementPending() { placementStatus = PLACEMENT_STATUS_PENDING; },
    setPlacementInProgress() {
      placementStatus = PLACEMENT_STATUS_IN_PROGRESS;
      journeyStatus = null;
    },
    setPlacementWaitingAdoption() {
      placementStatus = PLACEMENT_STATUS_WAITING_ADOPTION;
      journeyStatus = 'awaiting_foster_confirmation';
      journeyConditions = '';
      placementAdoptionConditions = '';
    },
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

    it('ends an in-progress placement via end confirmation', async () => {
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
      expect(res.body.session_status).toBe('end_pending_confirmation');
    });

    it('GET /:orgId/placements returns 403 for foster', async () => {
      const app = createApp(buildMockPool());
      const res = await request(app)
        .get(`/api/organizations/${orgId}/placements`)
        .set('Authorization', `Bearer ${fosterToken}`);
      expect(res.statusCode).toBe(403);
    });
  });

  describe('Adoption flow', () => {
    it('admin starts adoption from in-progress placement', async () => {
      const pool = buildMockPool();
      pool.setPlacementInProgress();
      const app = createApp(pool);
      const res = await request(app)
        .post(`/api/organizations/${orgId}/placements/${placementId}/start-adoption`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({});
      expect(res.statusCode).toBe(200);
      expect(res.body.session_status).toBe(SESSION_STATUS_ADOPTION_IN_PROGRESS);
      expect(res.body.status).toBe(PLACEMENT_STATUS_WAITING_ADOPTION);
      expect(res.body.adoption_journey).toBeDefined();
    });

    it('admin can start adoption with pre-adoption conditions', async () => {
      const pool = buildMockPool();
      pool.setPlacementInProgress();
      const app = createApp(pool);
      const res = await request(app)
        .post(`/api/organizations/${orgId}/placements/${placementId}/start-adoption`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ adoption_conditions: 'Must be neutered first' });
      expect(res.statusCode).toBe(200);
      expect(res.body.status).toBe(PLACEMENT_STATUS_PENDING_CONDITIONS);
      expect(res.body.adoption_journey.status).toBe('pending_conditions');
    });

    it('foster lists pending adoption confirmations', async () => {
      const pool = buildMockPool();
      pool.setPlacementWaitingAdoption();
      const app = createApp(pool);
      const res = await request(app)
        .get('/api/foster-placements/pending-adoptions')
        .set('Authorization', `Bearer ${fosterToken}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveLength(1);
      expect(res.body[0].status).toBe(PLACEMENT_STATUS_WAITING_ADOPTION);
    });

    it('foster confirms adoption and becomes owner', async () => {
      const pool = buildMockPool();
      pool.setPlacementWaitingAdoption();
      const app = createApp(pool);
      const res = await request(app)
        .post(`/api/foster-placements/${placementId}/confirm-adoption`)
        .set('Authorization', `Bearer ${fosterToken}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toMatchObject({
        status: PLACEMENT_STATUS_ADOPTED,
        adopted: true,
        new_owner_id: fosterId,
      });
      expect(pool.adoptedOwnerId).toBe(fosterId);
    });

    it('admin can cancel adoption and return pet to org custody', async () => {
      const pool = buildMockPool();
      pool.setPlacementWaitingAdoption();
      const app = createApp(pool);
      const res = await request(app)
        .post(`/api/organizations/${orgId}/placements/${placementId}/cancel-adoption`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({});
      expect(res.statusCode).toBe(200);
      expect(res.body.status).toBe(PLACEMENT_STATUS_NOT_IN_FOSTER);
    });

    it('admin can start direct adopt without a foster period', async () => {
      const pool = buildMockPool();
      const app = createApp(pool);
      const res = await request(app)
        .post(`/api/organizations/${orgId}/pets/${petId}/placements/direct-adopt`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ foster_user_id: fosterId });
      expect(res.statusCode).toBe(201);
      expect(res.body.session_status).toBe(SESSION_STATUS_ADOPTION_IN_PROGRESS);
      expect(res.body.adoption_journey).toBeDefined();
    });
  });
});
