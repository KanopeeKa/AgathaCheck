import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import { buildMockPool, makeOrgRow } from './helpers.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';

const PUBLIC_ALLOWLIST = [
  'id',
  'name',
  'type',
  'logo_url',
  'photo_url',
  'description',
  'bio',
  'town',
  'administrative_area',
  'public_profile_metadata',
  'legal_identifier_1',
  'legal_identifier_2',
  'legal_identifier_3',
  'email',
  'phone',
  'website',
];

function makePublicOrgRow(overrides = {}) {
  return makeOrgRow({
    town: 'Springfield',
    administrative_area: 'IL',
    description: 'A caring rescue',
    legal_identifier_1: 'RNA-123',
    legal_identifier_2: 'SIREN-456',
    legal_identifier_3: 'SIRET-789',
    public_profile_metadata: { postcode: '62701', internal_secret: 'leak' },
    is_discoverable: true,
    ...overrides,
  });
}

describe('GET /organizations/:id/public', () => {
  it('returns only public-tier fields for anonymous callers', async () => {
    const pool = buildMockPool({
      query: async (sql) => {
        if (sql.includes('SELECT * FROM organizations WHERE id = $1')) {
          return { rows: [makePublicOrgRow()] };
        }
        return { rows: [] };
      },
    });
    const app = createApp(pool);
    const res = await request(app).get(`/api/organizations/${orgId}/public`);
    expect(res.statusCode).toBe(200);
    expect(Object.keys(res.body).sort()).toEqual(PUBLIC_ALLOWLIST.sort());
    expect(res.body.id).toBe(orgId);
    expect(res.body.name).toBe('Test Org');
    expect(res.body.town).toBe('Springfield');
    expect(res.body.public_profile_metadata).toEqual({ postcode: '62701' });
    expect(res.body).not.toHaveProperty('address');
    expect(res.body.bio).toBe('A test organization');
    expect(res.body).not.toHaveProperty('role');
    expect(res.body).not.toHaveProperty('member_count');
    expect(res.body).not.toHaveProperty('primary_contact');
  });

  it('returns public tier only when Bearer token is present', async () => {
    const pool = buildMockPool({
      query: async (sql) => {
        if (sql.includes('SELECT * FROM organizations WHERE id = $1')) {
          return { rows: [makePublicOrgRow()] };
        }
        return { rows: [] };
      },
    });
    const app = createApp(pool);
    const res = await request(app)
      .get(`/api/organizations/${orgId}/public`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(Object.keys(res.body).sort()).toEqual(PUBLIC_ALLOWLIST.sort());
    expect(res.body).not.toHaveProperty('member_count');
  });

  it('returns 404 for opted-out org when caller is not an active member', async () => {
    const pool = buildMockPool({
      query: async (sql) => {
        if (sql.includes('SELECT * FROM organizations WHERE id = $1')) {
          return { rows: [makePublicOrgRow({ is_discoverable: false })] };
        }
        return { rows: [] };
      },
    });
    const app = createApp(pool);
    const res = await request(app).get(`/api/organizations/${orgId}/public`);
    expect(res.statusCode).toBe(404);
    expect(res.body.error).toBe('Organization not found');
  });

  it('allows active members to read opted-out org public profile', async () => {
    const pool = buildMockPool({
      query: async (sql) => {
        if (sql.includes('SELECT * FROM organizations WHERE id = $1')) {
          return { rows: [makePublicOrgRow({ is_discoverable: false })] };
        }
        if (sql.includes('SELECT role FROM organization_users WHERE organization_id')) {
          return { rows: [{ role: 'admin' }] };
        }
        return { rows: [] };
      },
    });
    const app = createApp(pool);
    const res = await request(app)
      .get(`/api/organizations/${orgId}/public`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.id).toBe(orgId);
    expect(res.body.name).toBe('Test Org');
  });
});
