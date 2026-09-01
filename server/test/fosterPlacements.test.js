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
  isPendingFosterAcceptance,
  OPEN_PLACEMENT_STATUSES,
  placementToMap,
  toLegacyStatus,
} from '../lib/fosterPlacements.js';
import {
  adminId,
  adminToken,
  buildFosterPlacementMockPool,
  fosterId,
  fosterToken,
  orgId,
  petId,
  placementId,
} from './helpers/fosterPlacementMockPool.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';

const buildMockPool = buildFosterPlacementMockPool;

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

  it('isPendingFosterAcceptance recognises legacy and J3 pending statuses', () => {
    expect(isPendingFosterAcceptance(PLACEMENT_STATUS_PENDING)).toBe(true);
    expect(isPendingFosterAcceptance(SESSION_STATUS_PENDING_ACCEPTANCE)).toBe(true);
    expect(isPendingFosterAcceptance(SESSION_STATUS_ACTIVE)).toBe(false);
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

    it('GET /:id returns 401 without token', async () => {
      const res = await request(app).get(`/api/foster-placements/${placementId}`);
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

    it('lists pending_acceptance placements (J3 session status)', async () => {
      const pool = buildMockPool();
      pool.setPlacementPendingAcceptance();
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
        session_status: SESSION_STATUS_PENDING_ACCEPTANCE,
      });
    });

    it('GET /:id returns session aggregate for foster participant', async () => {
      const pool = buildMockPool();
      pool.setPlacementPendingAcceptance();
      const app = createApp(pool);
      const res = await request(app)
        .get(`/api/foster-placements/${placementId}`)
        .set('Authorization', `Bearer ${fosterToken}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toMatchObject({
        id: placementId,
        session_status: SESSION_STATUS_PENDING_ACCEPTANCE,
        viewer: {
          role: 'foster_participant',
          allowed_actions: expect.arrayContaining(['accept_invite', 'decline_invite']),
        },
        pet: { id: petId, name: 'Buddy' },
        organization: { id: orgId, name: 'Test Org' },
      });
    });

    it('GET /:id returns 403 for non-participant non-member', async () => {
      const pool = buildMockPool();
      pool.setPlacementPendingAcceptance();
      const app = createApp(pool);
      const strangerToken = jwt.sign({ id: 'stranger-id', email: 's@example.com' }, JWT_SECRET, { expiresIn: '1h' });
      const res = await request(app)
        .get(`/api/foster-placements/${placementId}`)
        .set('Authorization', `Bearer ${strangerToken}`);
      expect(res.statusCode).toBe(403);
    });

    it('accepts a pending_acceptance placement and grants foster access', async () => {
      const pool = buildMockPool();
      pool.setPlacementPendingAcceptance();
      const app = createApp(pool);
      const res = await request(app)
        .post(`/api/foster-placements/${placementId}/accept`)
        .set('Authorization', `Bearer ${fosterToken}`);
      expect(res.statusCode).toBe(200);
      expect(res.body.status).toBe(PLACEMENT_STATUS_IN_PROGRESS);
      expect(res.body.session_status).toBe(SESSION_STATUS_ACTIVE);
      expect(pool.fosterAccessGranted).toBe(true);
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
      expect(res.body.session_status).toBe(SESSION_STATUS_ACTIVE);
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
      if (res.statusCode !== 201) {
        throw new Error(`direct-adopt failed: ${res.statusCode} ${JSON.stringify(res.body)}`);
      }
      expect(res.statusCode).toBe(201);
      expect(res.body.session_status).toBe(SESSION_STATUS_ADOPTION_IN_PROGRESS);
      expect(res.body.adoption_journey).toBeDefined();
    });
  });
});
