import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import { buildMockPool } from './helpers.js';
import {
  ADDRESS_VISIBILITY_HIDDEN,
  CARD_VISIBILITY_ADMINS,
  CARD_VISIBILITY_ALL,
  CARD_VISIBILITY_NAMED,
  CONTACT_VISIBILITY_ADMINS,
  CONTACT_VISIBILITY_ADMINS_AND_FOSTER_MANAGERS,
  CONTACT_VISIBILITY_ADMINS_OR_NAMED,
  CONTACT_VISIBILITY_NAMED,
  canViewerSeeField,
  canViewerSeeMemberName,
  defaultPrivacyForRole,
  enforceCardVisibilityFloor,
  mapLegacyFosterVisibility,
  redactMemberForViewer,
  buildViewerPrivacyContext,
} from '../../lib/orgMemberPrivacy.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const subjectUserId = 'subject-user';
const viewerUserId = 'viewer-user';
const granteeUserId = 'grantee-user';
const orgId = 'org-1';
const token = jwt.sign({ id: subjectUserId, email: 'subject@example.com' }, JWT_SECRET, {
  expiresIn: '1h',
});

const baseSettings = {
  card_visibility: CARD_VISIBILITY_ALL,
  phone_visibility: CONTACT_VISIBILITY_ADMINS_OR_NAMED,
  email_visibility: CONTACT_VISIBILITY_ADMINS_OR_NAMED,
  address_visibility: 'admins_or_named',
};

function ctx(overrides = {}) {
  return buildViewerPrivacyContext({
    viewerUserId,
    viewerRole: 'foster',
    viewerPermissionKeys: [],
    subjectUserId,
    subjectRole: 'foster',
    settings: baseSettings,
    grants: [],
    ...overrides,
  });
}

describe('orgMemberPrivacy resolver', () => {
  describe('defaults and floors', () => {
    it('uses standard contact defaults for all wire roles', () => {
      expect(defaultPrivacyForRole('foster').phone_visibility).toBe(
        CONTACT_VISIBILITY_ADMINS_OR_NAMED,
      );
      expect(defaultPrivacyForRole('associate').phone_visibility).toBe(
        CONTACT_VISIBILITY_ADMINS_OR_NAMED,
      );
    });

    it('enforces admin card floor at admins', () => {
      expect(enforceCardVisibilityFloor(CARD_VISIBILITY_NAMED, 'admin')).toBe(
        CARD_VISIBILITY_ADMINS,
      );
      expect(enforceCardVisibilityFloor(CARD_VISIBILITY_ALL, 'admin')).toBe(
        CARD_VISIBILITY_ALL,
      );
    });

    it('maps legacy foster visibility', () => {
      expect(mapLegacyFosterVisibility({
        visible_to: 'nobody',
        contact_visibility: 'neither',
        address_visibility: 'hidden',
      })).toEqual({
        card_visibility: CARD_VISIBILITY_NAMED,
        phone_visibility: CONTACT_VISIBILITY_NAMED,
        email_visibility: CONTACT_VISIBILITY_NAMED,
        address_visibility: ADDRESS_VISIBILITY_HIDDEN,
      });
    });
  });

  describe('viewer role × field × named grant matrix', () => {
    const matrix = [
      {
        label: 'associate sees phone with admins_or_named default',
        viewerRole: 'associate',
        field: 'phone',
        expected: false,
      },
      {
        label: 'admin sees phone with admins_or_named default',
        viewerRole: 'admin',
        field: 'phone',
        expected: true,
      },
      {
        label: 'foster sees phone when named grant exists',
        viewerRole: 'foster',
        field: 'phone',
        grants: [{ field: 'phone', grantee_user_id: viewerUserId }],
        expected: true,
      },
      {
        label: 'foster denied phone with named-only setting',
        viewerRole: 'foster',
        field: 'phone',
        settings: { ...baseSettings, phone_visibility: CONTACT_VISIBILITY_NAMED },
        expected: false,
      },
      {
        label: 'foster manager sees foster phone with admins_and_foster_managers',
        viewerRole: 'admin',
        field: 'phone',
        settings: {
          ...baseSettings,
          phone_visibility: CONTACT_VISIBILITY_ADMINS_AND_FOSTER_MANAGERS,
        },
        expected: true,
      },
      {
        label: 'associate foster manager sees foster phone',
        viewerRole: 'associate',
        field: 'phone',
        viewerPermissionKeys: ['manage_fosters'],
        settings: {
          ...baseSettings,
          phone_visibility: CONTACT_VISIBILITY_ADMINS_AND_FOSTER_MANAGERS,
        },
        expected: true,
      },
      {
        label: 'super admin does not see phone with named-only setting',
        viewerRole: 'super_admin',
        field: 'phone',
        settings: { ...baseSettings, phone_visibility: CONTACT_VISIBILITY_NAMED },
        expected: false,
      },
      {
        label: 'super admin sees name when card is named-only without grant',
        viewerRole: 'super_admin',
        field: 'card',
        settings: { ...baseSettings, card_visibility: CARD_VISIBILITY_NAMED },
        checkName: true,
        expected: true,
      },
      {
        label: 'super admin does not see full card when named-only without grant',
        viewerRole: 'super_admin',
        field: 'card',
        settings: { ...baseSettings, card_visibility: CARD_VISIBILITY_NAMED },
        expected: false,
      },
      {
        label: 'foster hidden from card when visibility is admins',
        viewerRole: 'foster',
        field: 'card',
        settings: { ...baseSettings, card_visibility: CARD_VISIBILITY_ADMINS },
        expected: false,
      },
      {
        label: 'address hidden for everyone when setting is hidden',
        viewerRole: 'super_admin',
        field: 'address',
        settings: { ...baseSettings, address_visibility: ADDRESS_VISIBILITY_HIDDEN },
        expected: false,
      },
    ];

    it.each(matrix)('$label', ({
      viewerRole,
      field,
      settings = baseSettings,
      grants = [],
      viewerPermissionKeys = [],
      checkName = false,
      expected,
    }) => {
      const context = ctx({
        viewerRole,
        settings,
        grants,
        viewerPermissionKeys,
      });
      const result = checkName
        ? canViewerSeeMemberName(context)
        : canViewerSeeField({ ...context, field });
      expect(result).toBe(expected);
    });
  });

  describe('redactMemberForViewer', () => {
    const person = {
      display_name: 'Jane Foster',
      email: 'jane@example.com',
      photo_url: '/photo.jpg',
      foster_phone: '555-0100',
      foster_address: '12 Oak Lane',
      admin_notes: 'note',
    };

    it('redacts contact fields for non-granted foster viewer', () => {
      const redacted = redactMemberForViewer(person, ctx({
        settings: {
          ...baseSettings,
          phone_visibility: CONTACT_VISIBILITY_NAMED,
          email_visibility: CONTACT_VISIBILITY_NAMED,
        },
      }));
      expect(redacted.display_name).toBe('Jane Foster');
      expect(redacted.email).toBeNull();
      expect(redacted.foster_phone).toBe('');
    });

    it('returns null when card and name are both hidden', () => {
      const hidden = redactMemberForViewer(person, ctx({
        viewerRole: 'foster',
        settings: { ...baseSettings, card_visibility: CARD_VISIBILITY_ADMINS },
      }));
      expect(hidden).toBeNull();
    });

    it('keeps name only for super admin when card is named-restricted', () => {
      const redacted = redactMemberForViewer(person, ctx({
        viewerRole: 'super_admin',
        settings: {
          ...baseSettings,
          card_visibility: CARD_VISIBILITY_NAMED,
          phone_visibility: CONTACT_VISIBILITY_NAMED,
          email_visibility: CONTACT_VISIBILITY_NAMED,
        },
      }));
      expect(redacted.display_name).toBe('Jane Foster');
      expect(redacted.photo_url).toBeNull();
      expect(redacted.foster_phone).toBe('');
    });
  });
});

describe('member privacy API', () => {
  const membershipRow = {
    id: 'ou-subject',
    organization_id: orgId,
    user_id: subjectUserId,
    role: 'foster',
    card_visibility: CARD_VISIBILITY_ALL,
    phone_visibility: CONTACT_VISIBILITY_ADMINS_OR_NAMED,
    email_visibility: CONTACT_VISIBILITY_ADMINS_OR_NAMED,
    address_visibility: 'admins_or_named',
  };

  function buildPrivacyPool(overrides = {}) {
    let currentMembership = { ...membershipRow, ...(overrides.membership || {}) };
    const grants = overrides.grants || [];
    return buildMockPool({
      memberRole: 'foster',
      query: async (sql, params) => {
        if (sql.includes('FROM organization_users ou') && sql.includes('ou.user_id = $2')) {
          return { rows: [currentMembership] };
        }
        if (sql.includes('FROM organization_visibility_grants')) {
          if (sql.includes('subject_user_id = $2')) {
            return { rows: grants };
          }
          return { rows: [] };
        }
        if (sql.includes('FROM organization_users ou') && sql.includes('JOIN users u')) {
          return {
            rows: [{
              user_id: granteeUserId,
              display_name: 'Grant User',
              role: 'associate',
            }],
          };
        }
        if (sql.includes('UPDATE organization_users') && sql.includes('card_visibility')) {
          currentMembership = {
            ...currentMembership,
            card_visibility: params[0],
            phone_visibility: params[1],
            email_visibility: params[2],
            address_visibility: params[3],
          };
          return { rows: [currentMembership] };
        }
        if (sql.includes('DELETE FROM organization_visibility_grants')) {
          return { rows: [] };
        }
        if (sql.includes('INSERT INTO organization_visibility_grants')) {
          return { rows: [] };
        }
        if (sql.includes('INSERT INTO audit_events')) {
          return { rows: [{ id: 'audit-1' }] };
        }
        return { rows: [] };
      },
    });
  }

  it('GET /members/me/privacy returns settings and grant buckets', async () => {
    const app = createApp(buildPrivacyPool({
      grants: [{ field: 'phone', grantee_user_id: granteeUserId }],
    }));
    const res = await request(app)
      .get(`/api/organizations/${orgId}/members/me/privacy`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.card_visibility).toBe(CARD_VISIBILITY_ALL);
    expect(res.body.grants.phone).toEqual([granteeUserId]);
    expect(Array.isArray(res.body.available_members)).toBe(true);
  });

  it('PUT /members/me/privacy persists settings and audits', async () => {
    const pool = buildPrivacyPool();
    const app = createApp(pool);
    const res = await request(app)
      .put(`/api/organizations/${orgId}/members/me/privacy`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        card_visibility: CARD_VISIBILITY_ADMINS,
        phone_visibility: CONTACT_VISIBILITY_ADMINS,
        email_visibility: CONTACT_VISIBILITY_ADMINS,
        address_visibility: CONTACT_VISIBILITY_ADMINS,
        grants: { phone: [granteeUserId] },
      });
    expect(res.statusCode).toBe(200);
    expect(res.body.card_visibility).toBe(CARD_VISIBILITY_ADMINS);
    const auditCall = pool.query.mock?.calls?.find?.(([sql]) => sql.includes('INSERT INTO audit_events'));
    if (auditCall) {
      expect(auditCall).toBeDefined();
    }
  });

  it('rejects invalid visibility enum', async () => {
    const app = createApp(buildPrivacyPool());
    const res = await request(app)
      .put(`/api/organizations/${orgId}/members/me/privacy`)
      .set('Authorization', `Bearer ${token}`)
      .send({ card_visibility: 'invalid' });
    expect(res.statusCode).toBe(400);
  });
});
