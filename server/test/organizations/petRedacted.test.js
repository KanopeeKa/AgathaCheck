import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';
const petId = 'pet-1';

function buildAssociatePetAccessPool({
  memberRole = 'associate',
  petRow = null,
  permissionRows = [],
} = {}) {
  const query = async (sql, params) => {
    if (sql.includes('SELECT role') && sql.includes('organization_users')) {
      return { rows: memberRole ? [{ role: memberRole }] : [] };
    }
    if (sql.includes('FROM organization_permissions')) {
      return { rows: permissionRows };
    }
    if (sql.includes('COALESCE(p.last_activity_at, p.created_at)')) {
      return {
        rows: petRow
          ? [
              {
                id: petRow.id,
                name: petRow.name,
                species: petRow.species,
                breed: petRow.breed ?? '',
                photo_path: petRow.photo_path ?? null,
                organization_id: orgId,
                last_activity_at: petRow.last_activity_at ?? null,
                created_at: petRow.created_at ?? new Date('2024-01-01T00:00:00Z'),
              },
            ]
          : [],
      };
    }
    if (sql.includes('FROM pets') && sql.includes('passed_away')) {
      if (params?.[0] === petId && params?.[1] === orgId) {
        return { rows: petRow ? [{ ...petRow, organization_id: orgId }] : [] };
      }
      return { rows: petRow ? [{ id: petId }] : [] };
    }
    if (sql.includes('SELECT organization_id FROM pets WHERE id = $1')) {
      return { rows: [{ organization_id: orgId }] };
    }
    if (sql.includes('SELECT id, name, species, breed, photo_path, date_of_birth, age, organization_id')) {
      return {
        rows: petRow
          ? [
              {
                id: petId,
                name: petRow.name,
                species: petRow.species,
                breed: petRow.breed ?? '',
                photo_path: petRow.photo_path ?? null,
                date_of_birth: petRow.date_of_birth ?? null,
                age: petRow.age ?? null,
                organization_id: orgId,
              },
            ]
          : [],
      };
    }
    if (sql.includes('SELECT id, created_at, date_of_birth FROM pets WHERE id = $1')) {
      return {
        rows: [{ id: petId, created_at: new Date('2024-01-01T00:00:00Z'), date_of_birth: null }],
      };
    }
    if (sql.includes('FROM custody_transfers')) return { rows: [] };
    if (sql.includes('FROM foster_placements')) return { rows: [] };
    if (sql.includes('FROM pet_timeline_entries')) return { rows: [] };
    if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2')) return { rows: [] };
    if (sql.includes('SELECT 1 FROM pet_access')) return { rows: [] };
    return { rows: [] };
  };

  return {
    pool: {
      query,
      connect: async () => ({ query, release: () => {} }),
      end: async () => {},
    },
  };
}

const samplePet = {
  id: petId,
  name: 'Buddy',
  species: 'dog',
  breed: 'Labrador',
  photo_path: '/photos/buddy.jpg',
  date_of_birth: new Date('2022-06-01T00:00:00Z'),
  age: 3,
};

describe('Organisation pet associate view (Option B)', () => {
  it('allows associate to list pet summary', async () => {
    const { pool } = buildAssociatePetAccessPool({ memberRole: 'associate', petRow: samplePet });
    const app = createApp(pool);

    const res = await request(app)
      .get(`/api/organizations/${orgId}/pets/summary`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].name).toBe('Buddy');
  });

  it('allows associate to fetch redacted pet detail with allowlisted fields only', async () => {
    const { pool } = buildAssociatePetAccessPool({ memberRole: 'associate', petRow: samplePet });
    const app = createApp(pool);

    const res = await request(app)
      .get(`/api/organizations/${orgId}/pets/${petId}/redacted`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({
      id: petId,
      name: 'Buddy',
      species: 'dog',
      breed: 'Labrador',
      photo_path: '/photos/buddy.jpg',
      date_of_birth: '2022-06-01',
      age: 3,
      organization_id: orgId,
    });
    expect(res.body).not.toHaveProperty('bio');
    expect(res.body).not.toHaveProperty('chip_id');
  });

  it('returns 403 for associate on pet timeline', async () => {
    const { pool } = buildAssociatePetAccessPool({ memberRole: 'associate', petRow: samplePet });
    const app = createApp(pool);

    const res = await request(app)
      .get(`/api/pets/${petId}/timeline`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toBe(403);
  });

  it('returns 403 for associate on foster-history', async () => {
    const { pool } = buildAssociatePetAccessPool({ memberRole: 'associate', petRow: samplePet });
    const app = createApp(pool);

    const res = await request(app)
      .get(`/api/organizations/${orgId}/pets/${petId}/foster-history`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toBe(403);
  });

  it('returns 403 for associate on health entries for org pet', async () => {
    const { pool } = buildAssociatePetAccessPool({ memberRole: 'associate', petRow: samplePet });
    const app = createApp(pool);

    const res = await request(app)
      .get(`/api/health-entries?pet_id=${petId}`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toBe(403);
  });

  it('returns 403 for redacted detail without view_org_pets membership', async () => {
    const { pool } = buildAssociatePetAccessPool({ memberRole: null, petRow: samplePet });
    const app = createApp(pool);

    const res = await request(app)
      .get(`/api/organizations/${orgId}/pets/${petId}/redacted`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toBe(403);
  });
});
