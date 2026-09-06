import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const ownerId = 'owner-id';
const orgViewerId = 'org-viewer-id';
const collaboratorId = 'collab-id';
const petId = 'pet-1';
const orgId = 'org-1';

const ownerToken = jwt.sign({ id: ownerId, email: 'owner@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgViewerToken = jwt.sign({ id: orgViewerId, email: 'viewer@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const collaboratorToken = jwt.sign({ id: collaboratorId, email: 'collab@example.com' }, JWT_SECRET, { expiresIn: '1h' });

function buildMockPool() {
  const collaboratorAccess = new Set([`${petId}:${collaboratorId}`]);
  const orgViewerAccess = new Set([`${orgId}:${orgViewerId}`]);

  const handler = async (sql, params) => {
    if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') return { rows: [] };

    if (sql.includes('SELECT we.*') && sql.includes('FROM weight_entries we')) {
      return {
        rows: [{
          id: 'we-1',
          pet_id: petId,
          user_id: ownerId,
          pet_name: 'Buddy',
          weight: 10,
          unit: 'kg',
          date: new Date('2026-01-01'),
          notes: '',
          created_at: new Date(),
        }],
      };
    }

    if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2 LIMIT 1')) {
      const [pid, uid] = params;
      return { rows: uid === ownerId && pid === petId ? [{ '?column?': 1 }] : [] };
    }

    if (sql.startsWith('SELECT 1 FROM pet_access')) {
      const [pid, uid] = params;
      return { rows: collaboratorAccess.has(`${pid}:${uid}`) ? [{ '?column?': 1 }] : [] };
    }

    if (sql.includes('JOIN organization_users ou')) {
      const [pid, uid] = params;
      if (uid !== orgViewerId) return { rows: [] };
      return { rows: orgViewerAccess.has(`${orgId}:${uid}`) ? [{ '?column?': 1 }] : [] };
    }

    if (sql.includes('SELECT pet_id FROM weight_entries WHERE id = $1')) {
      return { rows: [{ pet_id: petId }] };
    }

    if (sql.includes('INSERT INTO weight_entries')) {
      return {
        rows: [{
          id: params[0],
          pet_id: params[1],
          user_id: params[2],
          weight: params[3],
          unit: params[4],
          date: params[5],
          notes: params[6],
          created_at: new Date(),
        }],
      };
    }

    if (sql.includes('SELECT organization_id FROM pets WHERE id = $1')) {
      return { rows: [{ organization_id: orgId }] };
    }

    if (sql.includes('UPDATE pets SET weight')) {
      return { rows: [] };
    }

    return { rows: [] };
  };

  return {
    query: handler,
    end: async () => {},
  };
}

describe('pet capability auth matrix', () => {
  let app;

  beforeAll(() => {
    app = createApp(buildMockPool());
  });

  describe('weight entries', () => {
    it('allows org viewer to GET weight list (read-only)', async () => {
      const res = await request(app)
        .get(`/api/weight-entries?pet_id=${petId}`)
        .set('Authorization', `Bearer ${orgViewerToken}`);
      expect(res.statusCode).toBe(200);
      expect(res.body.length).toBe(1);
    });

    it('denies org viewer from POST weight entry', async () => {
      const res = await request(app)
        .post('/api/weight-entries')
        .set('Authorization', `Bearer ${orgViewerToken}`)
        .send({ pet_id: petId, weight: 11, unit: 'kg', date: '2026-02-01' });
      expect(res.statusCode).toBe(403);
    });

    it('allows collaborator to POST weight entry', async () => {
      const res = await request(app)
        .post('/api/weight-entries')
        .set('Authorization', `Bearer ${collaboratorToken}`)
        .send({ pet_id: petId, weight: 11, unit: 'kg', date: '2026-02-01' });
      expect(res.statusCode).toBe(201);
    });

    it('denies stranger from GET and POST', async () => {
      const stranger = jwt.sign({ id: 'stranger', email: 's@example.com' }, JWT_SECRET, { expiresIn: '1h' });
      const getRes = await request(app)
        .get(`/api/weight-entries?pet_id=${petId}`)
        .set('Authorization', `Bearer ${stranger}`);
      expect(getRes.statusCode).toBe(403);

      const postRes = await request(app)
        .post('/api/weight-entries')
        .set('Authorization', `Bearer ${stranger}`)
        .send({ pet_id: petId, weight: 11, unit: 'kg', date: '2026-02-01' });
      expect(postRes.statusCode).toBe(403);
    });

    it('allows owner to POST weight entry', async () => {
      const res = await request(app)
        .post('/api/weight-entries')
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ pet_id: petId, weight: 12, unit: 'kg', date: '2026-03-01' });
      expect(res.statusCode).toBe(201);
    });
  });
});
