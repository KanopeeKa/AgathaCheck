import {
  buildAllowedActions,
  resolveSessionViewer,
  VIEWER_ROLE_FOSTER_PARTICIPANT,
  VIEWER_ROLE_READ_ONLY_HISTORY,
  VIEWER_ROLE_SHELTER_OBSERVER,
  VIEWER_ROLE_SHELTER_OPERATOR,
} from '../lib/sessionDetail.js';
import {
  SESSION_STATUS_ACTIVE,
  SESSION_STATUS_CANCELLED,
  SESSION_STATUS_PENDING_ACCEPTANCE,
  SESSION_STATUS_PREPARATION,
  SESSION_STATUS_READY_TO_START,
} from '../lib/fosterPlacements.js';

const fosterId = 'foster-1';
const adminId = 'admin-1';
const orgId = 'org-1';

function makePlacement(overrides = {}) {
  return {
    id: 'placement-1',
    organization_id: orgId,
    foster_user_id: fosterId,
    status: SESSION_STATUS_PENDING_ACCEPTANCE,
    session_type: 'standard_foster',
    shelter_start_confirmed_at: null,
    foster_start_confirmed_at: null,
    adoption_conditions: '',
    organization_name: 'Rescue Hearts',
    foster_name: 'Jane',
    foster_email: 'jane@example.com',
    session_checklist_items: {},
    ...overrides,
  };
}

function mockPool({ memberRole = 'admin' } = {}) {
  return {
    query: async (sql, params) => {
      if (sql.includes('FROM organization_users')) {
        const uid = params[1];
        if (uid === adminId && memberRole) return { rows: [{ role: memberRole }] };
        return { rows: [] };
      }
      if (sql.includes('FROM organization_permissions')) {
        return { rows: [] };
      }
      return { rows: [] };
    },
  };
}

describe('sessionDetail', () => {
  describe('resolveSessionViewer', () => {
    it('returns foster_participant for assigned foster on open session', async () => {
      const result = await resolveSessionViewer(mockPool(), {
        userId: fosterId,
        placement: makePlacement({ status: SESSION_STATUS_ACTIVE }),
      });
      expect(result).toEqual({ role: VIEWER_ROLE_FOSTER_PARTICIPANT });
    });

    it('returns read_only_history for foster on terminal session', async () => {
      const result = await resolveSessionViewer(mockPool(), {
        userId: fosterId,
        placement: makePlacement({ status: SESSION_STATUS_CANCELLED }),
      });
      expect(result).toEqual({ role: VIEWER_ROLE_READ_ONLY_HISTORY });
    });

    it('returns shelter_operator for admin with manage permission', async () => {
      const result = await resolveSessionViewer(mockPool({ memberRole: 'admin' }), {
        userId: adminId,
        placement: makePlacement({ status: SESSION_STATUS_PREPARATION }),
      });
      expect(result).toEqual({ role: VIEWER_ROLE_SHELTER_OPERATOR });
    });

    it('returns shelter_observer for associate with view permission override', async () => {
      const pool = {
        query: async (sql) => {
          if (sql.includes('FROM organization_users')) {
            return { rows: [{ role: 'associate' }] };
          }
          if (sql.includes('FROM organization_permissions')) {
            return { rows: [{ permission_key: 'view_fostering_sessions' }] };
          }
          if (sql.includes('FROM organization_role_permission_defaults')) {
            return { rows: [] };
          }
          return { rows: [] };
        },
      };
      const result = await resolveSessionViewer(pool, {
        userId: 'associate-1',
        placement: makePlacement(),
      });
      expect(result).toEqual({ role: VIEWER_ROLE_SHELTER_OBSERVER });
    });

    it('returns forbidden for non-member', async () => {
      const result = await resolveSessionViewer(mockPool({ memberRole: null }), {
        userId: 'stranger',
        placement: makePlacement(),
      });
      expect(result).toEqual({ error: 'Forbidden', status: 403 });
    });
  });

  describe('buildAllowedActions', () => {
    it('includes accept and decline for foster pending acceptance', () => {
      const actions = buildAllowedActions(
        makePlacement({ status: SESSION_STATUS_PENDING_ACCEPTANCE }),
        VIEWER_ROLE_FOSTER_PARTICIPANT,
      );
      expect(actions).toEqual(expect.arrayContaining(['accept_invite', 'decline_invite']));
      expect(actions).not.toContain('request_end');
    });

    it('includes operator lifecycle actions for preparation', () => {
      const actions = buildAllowedActions(
        makePlacement({ status: SESSION_STATUS_PREPARATION }),
        VIEWER_ROLE_SHELTER_OPERATOR,
      );
      expect(actions).toContain('transition_ready_to_start');
      expect(actions).toContain('register_export');
    });

    it('includes confirm_foster_start when ready and unconfirmed', () => {
      const actions = buildAllowedActions(
        makePlacement({ status: SESSION_STATUS_READY_TO_START }),
        VIEWER_ROLE_FOSTER_PARTICIPANT,
      );
      expect(actions).toContain('confirm_foster_start');
    });

    it('returns empty actions for read-only history', () => {
      const actions = buildAllowedActions(
        makePlacement({ status: SESSION_STATUS_CANCELLED }),
        VIEWER_ROLE_READ_ONLY_HISTORY,
      );
      expect(actions).toEqual([]);
    });

    it('returns empty actions for shelter observer', () => {
      const actions = buildAllowedActions(
        makePlacement({ status: SESSION_STATUS_ACTIVE }),
        VIEWER_ROLE_SHELTER_OBSERVER,
      );
      expect(actions).toEqual([]);
    });
  });
});
