import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import {
  buildFosterOnboardingSteps,
} from '../../routes/organizations/fosterOnboarding.js';
import {
  DEFAULT_HOME_VISIT_CHECKLIST,
  hasValidatedHomeVisitYes,
  OUTCOME_NO,
  OUTCOME_YES,
  scheduleHomeVisit,
  validateHomeVisit,
  visitToExportMap,
  visitToMap,
  VISIT_STATUS_CANCELLED,
  VISIT_STATUS_SCHEDULED,
  VISIT_STATUS_VALIDATED,
} from '../../lib/fosterHomeVisits.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const adminToken = jwt.sign({ id: 'admin-user', email: 'admin@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const fosterToken = jwt.sign({ id: 'foster-user', email: 'foster@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const noPermToken = jwt.sign({ id: 'viewer-user', email: 'viewer@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';
const fosterParentId = 'fp-1';

function externalContext(overrides = {}) {
  return {
    kind: 'external', personId: fosterParentId, fosterParentId, userId: null,
    role: null, isPending: false, approvalState: 'under_review', rulesAgreementAt: null,
    fosterProfileId: 'prof-1', confirmedCompetencies: [], questionnaireSubmitted: true,
    homeVisitValidatedYes: false, ...overrides,
  };
}

describe('fosterHomeVisits helpers', () => {
  it('maps visit without address for export', () => {
    const map = visitToExportMap({
      id: 'hv-1',
      organization_id: orgId,
      org_foster_parent_id: fosterParentId,
      status: VISIT_STATUS_SCHEDULED,
      visit_date: '2026-09-01',
      visit_time: '14:30',
      address: '123 Secret St',
      notes: '',
      checklist_items: [],
      outcome: null,
      outcome_reason: '',
    });
    expect(map.visit_date).toBe('2026-09-01');
    expect(map.address).toBeUndefined();
  });

  it('includes address in admin map', () => {
    const map = visitToMap({
      id: 'hv-1',
      organization_id: orgId,
      org_foster_parent_id: fosterParentId,
      status: VISIT_STATUS_SCHEDULED,
      visit_date: '2026-09-01',
      visit_time: '14:30',
      address: '123 Secret St',
      notes: '',
      checklist_items: [],
    });
    expect(map.address).toBe('123 Secret St');
  });

  it('provides default checklist template', () => {
    expect(DEFAULT_HOME_VISIT_CHECKLIST.length).toBeGreaterThanOrEqual(5);
  });
});

describe('foster home visit lifecycle', () => {
  function buildLifecyclePool() {
    const visits = new Map();
    const attendees = new Map();
    const photos = new Map();
    let auditCount = 0;

    const client = {
      query: jest.fn(async (sql, params) => {
        if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') return { rows: [] };
        if (sql.includes('INSERT INTO foster_home_visits')) {
          const row = {
            id: params[0],
            organization_id: params[1],
            org_foster_parent_id: params[2],
            status: params[3],
            visit_date: params[4],
            visit_time: params[5],
            address: params[6],
            notes: params[7],
            checklist_items: JSON.parse(params[8]),
            outcome: null,
            outcome_reason: '',
            scheduled_by: params[9],
            validated_by: null,
            validated_at: null,
            cancelled_by: null,
            cancelled_at: null,
            cancel_reason: '',
            created_at: '2026-08-21T12:00:00.000Z',
            updated_at: '2026-08-21T12:00:00.000Z',
          };
          visits.set(row.id, row);
          attendees.set(row.id, []);
          photos.set(row.id, []);
          return { rows: [row] };
        }
        if (sql.includes('DELETE FROM foster_home_visit_attendees')) {
          attendees.set(params[0], []);
          return { rows: [] };
        }
        if (sql.includes('INSERT INTO foster_home_visit_attendees')) {
          const list = attendees.get(params[1]) || [];
          list.push({ id: params[0], user_id: params[2], display_name: params[3] });
          attendees.set(params[1], list);
          return { rows: [] };
        }
        if (sql.includes('UPDATE foster_home_visits') && sql.includes('validated_at')) {
          const row = visits.get(params[4]);
          if (!row) return { rows: [] };
          row.status = params[0];
          row.outcome = params[1];
          row.outcome_reason = params[2];
          row.validated_by = params[3];
          row.validated_at = '2026-08-21T13:00:00.000Z';
          visits.set(row.id, row);
          return { rows: [row] };
        }
        if (sql.includes('UPDATE foster_home_visits') && sql.includes('cancelled_at')) {
          const row = visits.get(params[3]);
          if (!row) return { rows: [] };
          row.status = params[0];
          row.cancel_reason = params[1];
          row.cancelled_by = params[2];
          row.cancelled_at = '2026-08-21T13:00:00.000Z';
          visits.set(row.id, row);
          return { rows: [row] };
        }
        if (sql.includes('FROM foster_home_visits') && sql.includes('WHERE id = $1')) {
          const row = visits.get(params[0]);
          return { rows: row ? [row] : [] };
        }
        if (sql.includes('FROM foster_home_visit_attendees')) {
          return { rows: attendees.get(params[0]) || [] };
        }
        if (sql.includes('FROM foster_home_visit_photos')) {
          return { rows: photos.get(params[0]) || [] };
        }
        if (sql.includes('INSERT INTO audit_events')) {
          auditCount += 1;
          return { rows: [{ id: `audit-${auditCount}` }] };
        }
        if (sql.includes('FROM organization_permissions')) return { rows: [] };
        if (sql.includes('FROM organization_role_permission_defaults')) return { rows: [] };
        if (sql.includes('SELECT role') && sql.includes('organization_users')) {
          return { rows: [{ role: 'admin' }] };
        }
        return { rows: [] };
      }),
      release: jest.fn(),
    };

    return {
      visits,
      attendees,
      photos,
      client,
      connect: jest.fn(async () => client),
      query: jest.fn(async (sql, params) => {
        if (sql.includes('FROM org_foster_parents') && sql.includes('organization_id')) {
          return { rows: [{ id: fosterParentId }] };
        }
        if (sql.includes('FROM foster_home_visits') && sql.includes('status = $3')
          && sql.includes('outcome = $4')) {
          const yesVisit = [...visits.values()].find(
            (v) => v.status === VISIT_STATUS_VALIDATED && v.outcome === OUTCOME_YES,
          );
          return { rows: yesVisit ? [{ id: yesVisit.id }] : [] };
        }
        if (sql.includes('FROM foster_home_visits') && sql.includes('status = $3')
          && !sql.includes('outcome')) {
          const scheduled = [...visits.values()].find(
            (v) => v.org_foster_parent_id === params[1] && v.status === VISIT_STATUS_SCHEDULED,
          );
          return { rows: scheduled ? [{ id: scheduled.id }] : [] };
        }
        if (sql.includes('UPDATE foster_home_visits') && sql.includes('validated_at')) {
          const row = visits.get(params[4]);
          if (!row) return { rows: [] };
          row.status = params[0];
          row.outcome = params[1];
          row.outcome_reason = params[2];
          row.validated_by = params[3];
          row.validated_at = '2026-08-21T13:00:00.000Z';
          visits.set(row.id, row);
          return { rows: [row] };
        }
        if (sql.includes('FROM foster_home_visits') && sql.includes('WHERE id = $1')) {
          const row = visits.get(params[0]);
          return { rows: row ? [row] : [] };
        }
        if (sql.includes('FROM foster_home_visit_attendees')) {
          return { rows: attendees.get(params[0]) || [] };
        }
        if (sql.includes('FROM foster_home_visit_photos')) {
          return { rows: photos.get(params[0]) || [] };
        }
        if (sql.includes('INSERT INTO audit_events')) {
          auditCount += 1;
          return { rows: [{ id: `audit-${auditCount}` }] };
        }
        if (sql.includes('FROM organization_permissions')) return { rows: [] };
        if (sql.includes('FROM organization_role_permission_defaults')) return { rows: [] };
        if (sql.includes('SELECT role') && sql.includes('organization_users')) {
          return { rows: [{ role: 'admin' }] };
        }
        return { rows: [] };
      }),
    };
  }

  it('schedules and validates yes outcome', async () => {
    const pool = buildLifecyclePool();
    const scheduled = await scheduleHomeVisit(pool, {
      orgId,
      fosterParentId,
      visitDate: '2026-09-15',
      visitTime: '10:00',
      address: '1 Foster Lane',
      actorUserId: 'admin-user',
    });
    expect(scheduled.status).toBe(201);
    expect(scheduled.visit.status).toBe(VISIT_STATUS_SCHEDULED);

    const validated = await validateHomeVisit(pool, {
      orgId,
      visitId: scheduled.visit.id,
      outcome: OUTCOME_YES,
      actorUserId: 'admin-user',
    });
    expect(validated.visit.status).toBe(VISIT_STATUS_VALIDATED);
    expect(validated.visit.outcome).toBe(OUTCOME_YES);

    expect(await hasValidatedHomeVisitYes(pool, orgId, fosterParentId)).toBe(true);
  });

  it('requires outcome reason on no', async () => {
    const pool = buildLifecyclePool();
    const scheduled = await scheduleHomeVisit(pool, {
      orgId,
      fosterParentId,
      visitDate: '2026-09-15',
      visitTime: '10:00',
      actorUserId: 'admin-user',
    });
    const result = await validateHomeVisit(pool, {
      orgId,
      visitId: scheduled.visit.id,
      outcome: OUTCOME_NO,
      actorUserId: 'admin-user',
    });
    expect(result.error).toMatch(/outcome_reason/);
    expect(result.status).toBe(400);
  });

  it('auto-completes home_visit onboarding step after validated yes', () => {
    const steps = buildFosterOnboardingSteps(externalContext({ homeVisitValidatedYes: true }));
    expect(steps.find((s) => s.key === 'home_visit')?.state).toBe('complete');
  });
});

describe('foster home visit routes', () => {
  function buildPool({ role = 'admin' } = {}) {
    const visits = [];
    return {
      query: jest.fn(async (sql, params) => {
        if (sql.includes('SELECT role') && sql.includes('organization_users')) {
          const uid = params[1];
          if (uid === 'foster-user') return { rows: [{ role: 'foster' }] };
          if (uid === 'viewer-user') return { rows: [{ role: 'associate' }] };
          return { rows: [{ role }] };
        }
        if (sql.includes('FROM organization_permissions')) return { rows: [] };
        if (sql.includes('FROM organization_role_permission_defaults')) return { rows: [] };
        if (sql.includes('FROM org_foster_parents') && sql.includes('user_id = $2')) {
          return {
            rows: [{
              id: fosterParentId,
              user_id: params[1],
              approval_state: 'under_review',
            }],
          };
        }
        if (sql.includes('FROM org_foster_parents') && sql.includes('organization_id = $1')) {
          return { rows: [{ id: fosterParentId }] };
        }
        if (sql.includes('FROM foster_home_visits') && sql.includes('ORDER BY visit_date')) {
          return { rows: visits };
        }
        if (sql.includes('FROM foster_home_visits') && sql.includes('status = $3')) {
          const scheduled = visits.find((v) => v.status === VISIT_STATUS_SCHEDULED);
          return { rows: scheduled ? [{ id: scheduled.id }] : [] };
        }
        if (sql.includes('FROM foster_home_visits') && sql.includes('WHERE id = $1')) {
          const row = visits.find((v) => v.id === params[0]);
          return { rows: row ? [row] : [] };
        }
        if (sql.includes('INSERT INTO foster_home_visits')) {
          const row = {
            id: params[0],
            organization_id: params[1],
            org_foster_parent_id: params[2],
            status: params[3],
            visit_date: params[4],
            visit_time: params[5],
            address: params[6],
            notes: params[7],
            checklist_items: JSON.parse(params[8]),
            outcome: null,
            outcome_reason: '',
            scheduled_by: params[9],
          };
          visits.push(row);
          return { rows: [row] };
        }
        if (sql.includes('INSERT INTO audit_events')) return { rows: [{ id: 'audit-1' }] };
        if (sql.includes('FROM foster_home_visit_attendees')) return { rows: [] };
        if (sql.includes('FROM foster_home_visit_photos')) return { rows: [] };
        if (sql.includes('DELETE FROM foster_home_visit_attendees')) return { rows: [] };
        return { rows: [] };
      }),
      connect: jest.fn(async () => ({
        query: jest.fn(async (sql, params) => {
          if (sql.includes('INSERT INTO foster_home_visits')) {
            const row = {
              id: params[0],
              organization_id: params[1],
              org_foster_parent_id: params[2],
              status: params[3],
              visit_date: params[4],
              visit_time: params[5],
              address: params[6],
              notes: params[7],
              checklist_items: JSON.parse(params[8]),
              outcome: null,
              outcome_reason: '',
              scheduled_by: params[9],
            };
            visits.push(row);
            return { rows: [row] };
          }
          if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') return { rows: [] };
          if (sql.includes('DELETE FROM foster_home_visit_attendees')) return { rows: [] };
          if (sql.includes('INSERT INTO foster_home_visit_attendees')) return { rows: [] };
          return { rows: [] };
        }),
        release: jest.fn(),
      })),
    };
  }

  it('schedules visit for admin with home_visits permission', async () => {
    const pool = buildPool();
    const app = createApp(pool);
    const res = await request(app)
      .post(`/api/organizations/${orgId}/foster-home-visits/${fosterParentId}/schedule`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        visit_date: '2026-10-01',
        visit_time: '11:00',
        address: '42 Test Road',
      });
    expect(res.status).toBe(201);
    expect(res.body.visit.visit_date).toBe('2026-10-01');
    expect(res.body.visit.address).toBe('42 Test Road');
  });

  it('rejects schedule without home_visits permission', async () => {
    const pool = buildPool({ role: 'associate' });
    const app = createApp(pool);
    const res = await request(app)
      .post(`/api/organizations/${orgId}/foster-home-visits/${fosterParentId}/schedule`)
      .set('Authorization', `Bearer ${noPermToken}`)
      .send({ visit_date: '2026-10-01', visit_time: '11:00' });
    expect(res.status).toBe(403);
  });

  it('returns candidate status without address', async () => {
    const pool = buildPool();
    pool.query.mockImplementation(async (sql, params) => {
      if (sql.includes('SELECT role') && sql.includes('organization_users')) {
        return { rows: [{ role: 'foster' }] };
      }
      if (sql.includes('FROM org_foster_parents') && sql.includes('user_id = $2')) {
        return { rows: [{ id: fosterParentId, user_id: params[1], approval_state: 'under_review' }] };
      }
      if (sql.includes('FROM org_foster_parents') && sql.includes('organization_id = $1')) {
        return { rows: [{ id: fosterParentId }] };
      }
      if (sql.includes('FROM foster_home_visits') && sql.includes('ORDER BY visit_date')) {
        return {
          rows: [{
            id: 'hv-1',
            organization_id: orgId,
            org_foster_parent_id: fosterParentId,
            status: VISIT_STATUS_SCHEDULED,
            visit_date: '2026-10-01',
            visit_time: '11:00',
            address: 'Hidden Address',
            notes: '',
            checklist_items: [],
            outcome: null,
            outcome_reason: '',
          }],
        };
      }
      if (sql.includes('FROM foster_home_visit_attendees')) return { rows: [] };
      if (sql.includes('FROM foster_home_visit_photos')) return { rows: [] };
      return { rows: [] };
    });
    const app = createApp(pool);
    const res = await request(app)
      .get(`/api/organizations/${orgId}/foster-home-visits/${fosterParentId}/status`)
      .set('Authorization', `Bearer ${fosterToken}`);
    expect(res.status).toBe(200);
    expect(res.body.active_visit.visit_date).toBe('2026-10-01');
    expect(res.body.active_visit.address).toBeUndefined();
  });
});
