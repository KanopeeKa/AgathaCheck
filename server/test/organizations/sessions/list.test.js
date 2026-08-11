import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../../bin/server.js';
import { buildMockPool } from '../helpers.js';
import {
  SESSION_STATUS_ACTIVE,
  SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT,
} from '../../../lib/fosterPlacements.js';
import { DERIVED_STATUS_NEARLY_FINISHED } from '../../../lib/deriveSessionStatus.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'admin-user';
const token = jwt.sign({ id: userId, email: 'admin@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';

function isoDateDaysFromNow(days) {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}

function makePlacementRow(overrides = {}) {
  return {
    id: 'placement-1',
    organization_id: orgId,
    pet_id: 'pet-1',
    foster_user_id: 'foster-1',
    org_foster_parent_id: null,
    status: SESSION_STATUS_ACTIVE,
    session_type: 'standard_foster',
    start_date: '2026-07-01',
    end_date: '2026-08-07',
    notes: '',
    adoption_conditions: '',
    created_at: new Date('2026-07-01'),
    updated_at: new Date('2026-07-01'),
    pet_name: 'Buddy',
    pet_species: 'dog',
    organization_name: 'Rescue Hearts',
    foster_name: 'Jane Foster',
    foster_email: 'jane@example.com',
    ...overrides,
  };
}

function buildSessionsPool(rows, overrides = {}) {
  return buildMockPool({
    memberRole: overrides.memberRole ?? 'admin',
    query: async (sql, params) => {
      if (sql.includes('SELECT role FROM organization_users')) {
        return { rows: [{ role: overrides.memberRole ?? 'admin' }] };
      }
      if (sql.includes('SELECT permission_key FROM org_permission_overrides')) {
        return { rows: [] };
      }
      if (sql.includes('FROM foster_placements fp') && sql.includes('fp.organization_id = $1')) {
        let filtered = [...rows];
        const petName = params?.find((value) => typeof value === 'string' && value.includes('%Buddy%'));
        if (petName) {
          filtered = filtered.filter((row) => row.pet_name.includes('Buddy'));
        }
        const fosterName = params?.find((value) => typeof value === 'string' && value.includes('%Jane%'));
        if (fosterName) {
          filtered = filtered.filter((row) => row.foster_name.includes('Jane'));
        }
        const inViewFilter = sql.includes(SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT);
        if (inViewFilter && sql.includes(`fp.session_type = '${SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT}'`)) {
          filtered = filtered.filter((row) => row.session_type === SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT);
        }
        return { rows: filtered };
      }
      return { rows: [] };
    },
  });
}

describe('GET /:orgId/placements list filters', () => {
  it('returns derived_status for nearly finished sessions', async () => {
    const app = createApp(buildSessionsPool([
      makePlacementRow({ end_date: isoDateDaysFromNow(5) }),
    ]));
    const res = await request(app)
      .get(`/api/organizations/${orgId}/placements`)
      .set('Authorization', `Bearer ${token}`)
      .query({ derived_status: DERIVED_STATUS_NEARLY_FINISHED });
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].derived_status).toBe(DERIVED_STATUS_NEARLY_FINISHED);
    expect(res.body[0].nearly_finished).toBe(true);
  });

  it('filters by pet name and foster name', async () => {
    const app = createApp(buildSessionsPool([
      makePlacementRow(),
      makePlacementRow({
        id: 'placement-2',
        pet_name: 'Milo',
        foster_name: 'Sam Foster',
        foster_email: 'sam@example.com',
      }),
    ]));
    const res = await request(app)
      .get(`/api/organizations/${orgId}/placements`)
      .set('Authorization', `Bearer ${token}`)
      .query({ pet_name: 'Buddy', foster_name: 'Jane' });
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].pet_name).toBe('Buddy');
    expect(res.body[0].foster_name).toBe('Jane Foster');
  });

  it('requires view_fostering_sessions permission', async () => {
    const app = createApp(buildSessionsPool([makePlacementRow()], { memberRole: 'associate' }));
    const res = await request(app)
      .get(`/api/organizations/${orgId}/placements`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(403);
  });
});
