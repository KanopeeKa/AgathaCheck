import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';
import {
  PLACEMENT_STATUS_IN_PROGRESS,
  PLACEMENT_STATUS_NOT_IN_FOSTER,
  PLACEMENT_STATUS_PENDING,
  SESSION_STATUS_ACTIVE,
  SESSION_STATUS_CANCELLED,
  SESSION_STATUS_END_PENDING_CONFIRMATION,
  SESSION_STATUS_PENDING_ACCEPTANCE,
  SESSION_STATUS_PREPARATION,
  SESSION_STATUS_READY_TO_START,
  SESSION_STATUS_RETURNED_TO_SHELTER,
} from '../lib/fosterPlacements.js';
import {
  AUDIT_FOSTERING_SESSION_CREATED,
  AUDIT_SESSION_RETURN_CONFIRMED,
  AUDIT_SESSION_START_CONFIRMED_FOSTER,
  AUDIT_SESSION_START_CONFIRMED_SHELTER,
} from '../lib/fosterSessions.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const adminId = 'admin-user-id';
const fosterId = 'foster-user-id';
const adminToken = jwt.sign({ id: adminId, email: 'admin@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const fosterToken = jwt.sign({ id: fosterId, email: 'foster@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';
const petId = 'pet-1';
const placementId = 'placement-1';
const relationshipId = 'relationship-1';

function makePlacementRow(overrides = {}) {
  return {
    id: placementId,
    organization_id: orgId,
    pet_id: petId,
    foster_user_id: fosterId,
    org_foster_parent_id: relationshipId,
    shelter_foster_relationship_id: relationshipId,
    session_type: 'standard_foster',
    foster_request_response_id: null,
    shelter_start_confirmed_at: null,
    foster_start_confirmed_at: null,
    status: SESSION_STATUS_PENDING_ACCEPTANCE,
    start_date: null,
    end_date: null,
    notes: '',
    adoption_conditions: '',
    created_by: adminId,
    created_at: new Date('2024-01-01'),
    updated_at: new Date('2024-01-01'),
    responded_at: null,
    pet_name: 'Buddy',
    pet_species: 'dog',
    organization_name: 'Test Org',
    foster_name: 'Jane Foster',
    foster_email: 'foster@example.com',
    session_checklist_items: {},
    flagged_for_admin_review: false,
    ...overrides,
  };
}

function buildSessionMockPool() {
  let placement = makePlacementRow({ status: SESSION_STATUS_CANCELLED });
  const auditEvents = [];
  let fosterAccessGranted = false;

  const handleQuery = async (sql, params) => {
    if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
      return { rows: [] };
    }
    if (sql.includes('SELECT role') && sql.includes('organization_users')) {
      const uid = params[1];
      if (uid === adminId) return { rows: [{ role: 'admin' }] };
      if (uid === fosterId) return { rows: [{ role: 'foster' }] };
      return { rows: [] };
    }
    if (sql.includes('FROM organization_permissions')) {
      return { rows: [] };
    }
    if (sql.includes('SELECT id FROM foster_placements WHERE id = $1 AND organization_id = $2')) {
      return placement.organization_id === params[1] && placement.id === params[0]
        ? { rows: [{ id: placement.id }] }
        : { rows: [] };
    }
    if (sql.includes('SELECT * FROM foster_placements WHERE id = $1 AND organization_id')) {
      return placement.organization_id === params[1] && placement.id === params[0]
        ? { rows: [placement] }
        : { rows: [] };
    }
    if (sql.includes('SELECT * FROM foster_placements WHERE id = $1')) {
      return placement.id === params[0] ? { rows: [placement] } : { rows: [] };
    }
    if (sql.includes('SELECT fp.*') && sql.includes('WHERE fp.pet_id = $1')) {
      const terminal = [
        PLACEMENT_STATUS_NOT_IN_FOSTER,
        SESSION_STATUS_CANCELLED,
        SESSION_STATUS_RETURNED_TO_SHELTER,
      ];
      if (terminal.includes(placement.status)) return { rows: [] };
      return { rows: [placement] };
    }
    if (sql.includes('FROM foster_placements fp') && sql.includes('WHERE fp.id = $1')) {
      return { rows: [makePlacementRow(placement)] };
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
    if (sql.includes('FROM org_foster_parents') && sql.includes('user_id = $2')) {
      return { rows: [{ id: relationshipId }] };
    }
    if (sql.includes('SELECT id FROM org_foster_parents')) {
      return { rows: [{ id: relationshipId }] };
    }
    if (sql.includes('INSERT INTO foster_placements')) {
      placement = makePlacementRow({
        id: params[0],
        status: params[4],
        shelter_foster_relationship_id: params[9] || relationshipId,
        org_foster_parent_id: params[9] || relationshipId,
        session_type: params[10] || 'standard_foster',
      });
      return { rows: [placement] };
    }
    if (sql.includes('UPDATE foster_placements') && sql.includes('start_date = COALESCE(start_date, CURRENT_DATE)')) {
      placement = makePlacementRow({
        ...placement,
        status: SESSION_STATUS_ACTIVE,
        start_date: '2024-03-01',
      });
      fosterAccessGranted = true;
      return { rows: [placement] };
    }
    if (sql.includes('UPDATE foster_placements') && sql.includes('SET status = $1')) {
      placement = makePlacementRow({
        ...placement,
        status: params[0],
        end_date: params[1] || placement.end_date,
      });
      return { rows: [placement] };
    }
    if (sql.includes('SET shelter_start_confirmed_at = NOW()')) {
      placement = makePlacementRow({
        ...placement,
        shelter_start_confirmed_at: new Date('2024-03-01T10:00:00Z'),
      });
      return { rows: [placement] };
    }
    if (sql.includes('SET foster_start_confirmed_at = NOW()')) {
      placement = makePlacementRow({
        ...placement,
        foster_start_confirmed_at: new Date('2024-03-01T11:00:00Z'),
      });
      return { rows: [placement] };
    }
    if (sql.includes('SET status = $1') && sql.includes('start_date = COALESCE')) {
      placement = makePlacementRow({
        ...placement,
        status: SESSION_STATUS_ACTIVE,
        start_date: '2024-03-01',
      });
      fosterAccessGranted = true;
      return { rows: [placement] };
    }
    if (sql.includes('INSERT INTO pet_access') && sql.includes("'foster'")) {
      fosterAccessGranted = true;
      return { rows: [] };
    }
    if (sql.includes('DELETE FROM pet_access')) {
      fosterAccessGranted = false;
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO audit_events')) {
      auditEvents.push({
        action: params[3],
        resourceType: params[4],
        resourceId: params[5],
      });
      return { rows: [{ id: 'audit-1' }] };
    }
    if (sql.includes('INSERT INTO notifications')) {
      return { rows: [] };
    }
    if (sql.includes('SELECT first_name, last_name, email FROM users')) {
      return { rows: [{ first_name: 'Test', last_name: 'User', email: 'test@example.com' }] };
    }
    if (sql.includes('FROM document_templates')) {
      return { rows: [] };
    }
    if (sql.includes('FROM adoption_journeys') && sql.includes('fostering_session_id')) {
      return { rows: [] };
    }
    return { rows: [] };
  };

  return {
    query: handleQuery,
    connect: async () => ({ query: handleQuery, release: () => {} }),
    get placement() { return placement; },
    setPlacement(next) { placement = makePlacementRow(next); },
    get auditEvents() { return auditEvents; },
    get fosterAccessGranted() { return fosterAccessGranted; },
  };
}

describe('J3 session lifecycle API', () => {
  it('GET placement detail returns session fields', async () => {
    const pool = buildSessionMockPool();
    pool.setPlacement({ status: SESSION_STATUS_PREPARATION });
    const app = createApp(pool);

    const res = await request(app)
      .get(`/api/organizations/${orgId}/placements/${placementId}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body).toMatchObject({
      id: placementId,
      session_status: SESSION_STATUS_PREPARATION,
      session_type: 'standard_foster',
      shelter_foster_relationship_id: relationshipId,
      viewer: {
        role: 'shelter_operator',
        allowed_actions: expect.arrayContaining([
          'transition_ready_to_start',
          'update_checklist_item',
          'register_export',
        ]),
      },
      pet: { id: petId, name: 'Buddy', species: 'dog' },
      organization: { id: orgId, name: 'Test Org' },
    });
  });

  it('transitions pending_acceptance to preparation then ready_to_start', async () => {
    const pool = buildSessionMockPool();
    pool.setPlacement({ status: SESSION_STATUS_PENDING_ACCEPTANCE });
    const app = createApp(pool);

    const prep = await request(app)
      .post(`/api/organizations/${orgId}/placements/${placementId}/transition`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ session_status: SESSION_STATUS_PREPARATION });
    expect(prep.statusCode).toBe(200);
    expect(prep.body.session_status).toBe(SESSION_STATUS_PREPARATION);

    const ready = await request(app)
      .post(`/api/organizations/${orgId}/placements/${placementId}/transition`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ session_status: SESSION_STATUS_READY_TO_START });
    expect(ready.statusCode).toBe(200);
    expect(ready.body.session_status).toBe(SESSION_STATUS_READY_TO_START);
  });

  it('dual-start confirms activate the session and grant foster access', async () => {
    const pool = buildSessionMockPool();
    pool.setPlacement({ status: SESSION_STATUS_READY_TO_START });
    const app = createApp(pool);

    const shelter = await request(app)
      .post(`/api/organizations/${orgId}/placements/${placementId}/confirm-shelter-start`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(shelter.statusCode).toBe(200);
    expect(shelter.body.session_status).toBe(SESSION_STATUS_READY_TO_START);
    expect(pool.auditEvents.some((e) => e.action === AUDIT_SESSION_START_CONFIRMED_SHELTER)).toBe(true);

    const foster = await request(app)
      .post(`/api/organizations/${orgId}/placements/${placementId}/confirm-foster-start`)
      .set('Authorization', `Bearer ${fosterToken}`);
    expect(foster.statusCode).toBe(200);
    expect(foster.body.session_status).toBe(SESSION_STATUS_ACTIVE);
    expect(pool.fosterAccessGranted).toBe(true);
    expect(pool.auditEvents.some((e) => e.action === AUDIT_SESSION_START_CONFIRMED_FOSTER)).toBe(true);
  });

  it('ends an active session through confirmation to returned_to_shelter', async () => {
    const pool = buildSessionMockPool();
    pool.setPlacement({
      status: SESSION_STATUS_ACTIVE,
      shelter_start_confirmed_at: new Date('2024-03-01'),
      foster_start_confirmed_at: new Date('2024-03-01'),
    });
    const app = createApp(pool);

    const requestEnd = await request(app)
      .post(`/api/organizations/${orgId}/placements/${placementId}/end`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(requestEnd.statusCode).toBe(200);
    expect(requestEnd.body.session_status).toBe(SESSION_STATUS_END_PENDING_CONFIRMATION);

    const complete = await request(app)
      .post(`/api/organizations/${orgId}/placements/${placementId}/end-session`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ outcome: SESSION_STATUS_RETURNED_TO_SHELTER });
    expect(complete.statusCode).toBe(200);
    expect(complete.body.session_status).toBe(SESSION_STATUS_RETURNED_TO_SHELTER);
    expect(pool.auditEvents.some((e) => e.action === AUDIT_SESSION_RETURN_CONFIRMED)).toBe(true);
    expect(pool.fosterAccessGranted).toBe(false);
  });

  it('creates a placement with shelter_foster_relationship_id and audit event', async () => {
    const pool = buildSessionMockPool();
    const app = createApp(pool);

    const res = await request(app)
      .post(`/api/organizations/${orgId}/pets/${petId}/placements`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ foster_user_id: fosterId, notes: 'Prep needed' });

    expect(res.statusCode).toBe(201);
    expect(res.body).toMatchObject({
      foster_user_id: fosterId,
      session_status: SESSION_STATUS_PENDING_ACCEPTANCE,
      shelter_foster_relationship_id: relationshipId,
    });
    expect(pool.auditEvents.some((e) => e.action === AUDIT_FOSTERING_SESSION_CREATED)).toBe(true);
  });

  it('rejects invalid transition targets', async () => {
    const pool = buildSessionMockPool();
    pool.setPlacement({ status: SESSION_STATUS_PENDING_ACCEPTANCE });
    const app = createApp(pool);

    const res = await request(app)
      .post(`/api/organizations/${orgId}/placements/${placementId}/transition`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ session_status: SESSION_STATUS_ACTIVE });
    expect(res.statusCode).toBe(400);
  });

  it('legacy pending placement end cancels immediately', async () => {
    const pool = buildSessionMockPool();
    pool.setPlacement({ status: PLACEMENT_STATUS_PENDING });
    const app = createApp(pool);

    const res = await request(app)
      .post(`/api/organizations/${orgId}/placements/${placementId}/end`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.session_status).toBe(SESSION_STATUS_CANCELLED);
    expect(res.body.status).toBe(PLACEMENT_STATUS_NOT_IN_FOSTER);
  });

  it('legacy in-progress placement end moves to end_pending_confirmation', async () => {
    const pool = buildSessionMockPool();
    pool.setPlacement({ status: PLACEMENT_STATUS_IN_PROGRESS });
    const app = createApp(pool);

    const res = await request(app)
      .post(`/api/organizations/${orgId}/placements/${placementId}/end`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.session_status).toBe(SESSION_STATUS_END_PENDING_CONFIRMATION);
  });
});
