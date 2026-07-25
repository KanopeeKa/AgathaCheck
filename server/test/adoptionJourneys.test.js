import request from 'supertest';
import { createApp } from '../bin/server.js';
import {
  AUDIT_ADOPTION_JOURNEY_STARTED,
  JOURNEY_STATUS_AWAITING_FOSTER_CONFIRMATION,
  JOURNEY_STATUS_PENDING_CONDITIONS,
  journeyStatusFromConditions,
  journeyToMap,
  migrateAdoptionJourneys,
  startAdoptionJourney,
} from '../lib/adoptionJourneys.js';
import {
  PLACEMENT_STATUS_IN_PROGRESS,
  PLACEMENT_STATUS_NOT_IN_FOSTER,
  PLACEMENT_STATUS_PENDING_CONDITIONS,
  PLACEMENT_STATUS_WAITING_ADOPTION,
  SESSION_STATUS_ACTIVE,
  SESSION_STATUS_ADOPTION_IN_PROGRESS,
  SESSION_STATUS_CANCELLED,
} from '../lib/fosterPlacements.js';
import {
  adminId,
  adminToken,
  buildAdoptionJourneyMockPool,
  fosterId,
  journeyId,
  orgId,
  petId,
  placementId,
} from './helpers/adoptionJourneyMockPool.js';

describe('adoptionJourneys lib (J5 Phase 1)', () => {
  it('maps journey status from adoption conditions', () => {
    expect(journeyStatusFromConditions('')).toBe(JOURNEY_STATUS_AWAITING_FOSTER_CONFIRMATION);
    expect(journeyStatusFromConditions('Neuter first'))
      .toBe(JOURNEY_STATUS_PENDING_CONDITIONS);
  });

  it('journeyToMap exposes journey fields', () => {
    const row = {
      id: journeyId,
      organization_id: orgId,
      fostering_session_id: placementId,
      pet_id: petId,
      foster_user_id: fosterId,
      status: JOURNEY_STATUS_AWAITING_FOSTER_CONFIRMATION,
      adoption_conditions: '',
      started_at: new Date('2024-03-01'),
      finalised_at: null,
      cancelled_at: null,
      created_by: adminId,
      created_at: new Date('2024-03-01'),
      updated_at: new Date('2024-03-01'),
    };

    expect(journeyToMap(row)).toMatchObject({
      id: journeyId,
      fostering_session_id: placementId,
      status: JOURNEY_STATUS_AWAITING_FOSTER_CONFIRMATION,
    });
  });

  it('startAdoptionJourney writes session adoption_in_progress and audits', async () => {
    const auditEvents = [];
    const placement = {
      id: placementId,
      organization_id: orgId,
      pet_id: petId,
      foster_user_id: fosterId,
      status: SESSION_STATUS_ACTIVE,
    };

    const db = {
      async query(sql, params) {
        if (sql.includes('FROM adoption_journeys') && sql.includes('fostering_session_id')) {
          return { rows: [] };
        }
        if (sql.includes('INSERT INTO adoption_journeys')) {
          return {
            rows: [{
              id: journeyId,
              organization_id: orgId,
              fostering_session_id: placementId,
              pet_id: petId,
              foster_user_id: fosterId,
              status: params[5],
              adoption_conditions: params[6],
              started_at: new Date(),
              created_by: adminId,
              created_at: new Date(),
              updated_at: new Date(),
            }],
          };
        }
        if (sql.includes('UPDATE foster_placements')) {
          return {
            rows: [{
              ...placement,
              status: SESSION_STATUS_ADOPTION_IN_PROGRESS,
              adoption_conditions: params[1],
            }],
          };
        }
        if (sql.includes('INSERT INTO audit_events')) {
          auditEvents.push({ sql, params });
          return { rows: [{ id: 'audit-1' }] };
        }
        return { rows: [] };
      },
    };

    const result = await startAdoptionJourney(db, {
      placement,
      adoptionConditions: 'Neuter first',
      createdBy: adminId,
      auditContext: { req: { ip: '127.0.0.1' } },
    });

    expect(result.status).toBe(200);
    expect(result.journey.status).toBe(JOURNEY_STATUS_PENDING_CONDITIONS);
    expect(result.placement.status).toBe(SESSION_STATUS_ADOPTION_IN_PROGRESS);
    expect(auditEvents).toHaveLength(1);
    expect(auditEvents[0].params[3]).toBe(AUDIT_ADOPTION_JOURNEY_STARTED);
    expect(auditEvents[0].params[4]).toBe('adoption_journey');
    expect(auditEvents[0].params[6]).toBe(orgId);
    expect(auditEvents[0].params[7]).toBe(petId);
  });

  it('migrateAdoptionJourneys backfills legacy waiting_adoption_confirmation rows', async () => {
    const inserts = [];
    const updates = [];
    const client = {
      async query(sql, params) {
        if (sql.includes('CREATE TABLE IF NOT EXISTS adoption_journeys')) return { rows: [] };
        if (sql.includes('CREATE INDEX')) return { rows: [] };
        if (sql.includes('CREATE UNIQUE INDEX')) return { rows: [] };
        if (sql.includes('FROM foster_placements fp')) {
          return {
            rows: [{
              id: placementId,
              organization_id: orgId,
              pet_id: petId,
              foster_user_id: fosterId,
              status: PLACEMENT_STATUS_WAITING_ADOPTION,
              adoption_conditions: '',
              created_by: adminId,
              created_at: new Date('2024-01-01'),
              updated_at: new Date('2024-01-01'),
            }],
          };
        }
        if (sql.includes('UPDATE foster_placements')) {
          updates.push({ sql, params });
          return { rows: [] };
        }
        if (sql.includes('INSERT INTO adoption_journeys')) {
          inserts.push({ sql, params });
          return { rows: [] };
        }
        return { rows: [] };
      },
    };

    await migrateAdoptionJourneys(client);

    expect(updates).toHaveLength(1);
    expect(updates[0].params[0]).toBe(SESSION_STATUS_ADOPTION_IN_PROGRESS);
    expect(inserts).toHaveLength(1);
    expect(inserts[0].params[5]).toBe(JOURNEY_STATUS_AWAITING_FOSTER_CONFIRMATION);
  });
});

describe('Adoption journeys API (J5 Phase 1)', () => {
  it('admin starts adoption journey from in-progress placement', async () => {
    const pool = buildAdoptionJourneyMockPool();
    pool.setPlacementInProgress();
    const app = createApp(pool);
    const res = await request(app)
      .post(`/api/organizations/${orgId}/placements/${placementId}/start-adoption`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({});
    expect(res.statusCode).toBe(200);
    expect(res.body.session_status).toBe(SESSION_STATUS_ADOPTION_IN_PROGRESS);
    expect(res.body.status).toBe(PLACEMENT_STATUS_WAITING_ADOPTION);
    expect(res.body.adoption_journey.status).toBe(JOURNEY_STATUS_AWAITING_FOSTER_CONFIRMATION);
    expect(pool.auditEvents.some((event) => event.params.includes(AUDIT_ADOPTION_JOURNEY_STARTED))).toBe(true);
  });

  it('admin can start adoption journey with pre-adoption conditions', async () => {
    const pool = buildAdoptionJourneyMockPool();
    pool.setPlacementInProgress();
    const app = createApp(pool);
    const res = await request(app)
      .post(`/api/organizations/${orgId}/placements/${placementId}/start-adoption`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ adoption_conditions: 'Must be neutered first' });
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe(PLACEMENT_STATUS_PENDING_CONDITIONS);
    expect(res.body.adoption_journey.status).toBe(JOURNEY_STATUS_PENDING_CONDITIONS);
  });

  it('admin can complete adoption journey conditions', async () => {
    const pool = buildAdoptionJourneyMockPool();
    pool.setPlacementPendingConditions();
    const app = createApp(pool);
    const res = await request(app)
      .post(`/api/organizations/${orgId}/placements/${placementId}/complete-conditions`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe(PLACEMENT_STATUS_WAITING_ADOPTION);
    expect(res.body.adoption_journey?.status).toBe(JOURNEY_STATUS_AWAITING_FOSTER_CONFIRMATION);
  });

  it('GET adoption journey by placement id', async () => {
    const pool = buildAdoptionJourneyMockPool();
    pool.setPlacementWaitingAdoption();
    const app = createApp(pool);
    const res = await request(app)
      .get(`/api/organizations/${orgId}/placements/${placementId}/adoption-journey`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.adoption_journey.id).toBe(journeyId);
    expect(res.body.placement_id).toBe(placementId);
  });

  it('admin can cancel adoption journey', async () => {
    const pool = buildAdoptionJourneyMockPool();
    pool.setPlacementWaitingAdoption();
    const app = createApp(pool);
    const res = await request(app)
      .post(`/api/organizations/${orgId}/placements/${placementId}/cancel-adoption`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({});
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe(PLACEMENT_STATUS_NOT_IN_FOSTER);
  });

  it('direct adopt creates session and adoption journey', async () => {
    const pool = buildAdoptionJourneyMockPool();
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
