import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const ownerId = 'owner-id';
const sharedUserId = 'shared-user-id';
const petId = 'pet-1';
const ownerToken = jwt.sign({ id: ownerId, email: 'owner@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const sharedToken = jwt.sign({ id: sharedUserId, email: 'shared@example.com' }, JWT_SECRET, { expiresIn: '1h' });

function buildMockPool() {
  const sharedAccess = new Set([`${petId}:${sharedUserId}`]);

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

    if (sql.includes('SELECT he.*') && sql.includes('FROM health_entries he')) {
      return {
        rows: [{
          id: 'he-1',
          pet_id: petId,
          user_id: ownerId,
          pet_name: 'Buddy',
          name: 'Vaccine',
          type: 'vet_visit',
          dosage: '',
          frequency: 'once',
          frequency_days: null,
          frequency_interval: 1,
          start_date: new Date('2026-01-01'),
          next_due_date: new Date('2026-06-01'),
          completed_on: null,
          recurrence_anchor: 'from_completion',
          repeat_end_date: null,
          notes: '',
          health_issue_id: null,
          remind_days_before: 1,
          status: 'active',
          completed_at: null,
          created_at: new Date(),
          updated_at: new Date(),
        }],
      };
    }

    if (sql.includes('SELECT hi.*') && sql.includes('FROM health_issues hi')) {
      return {
        rows: [{
          id: 'hi-1',
          pet_id: petId,
          user_id: ownerId,
          pet_name: 'Buddy',
          name: 'Allergy',
          issue_type: 'other',
          notes: '',
          start_date: null,
          end_date: null,
          status: 'active',
          created_at: new Date(),
          updated_at: new Date(),
        }],
      };
    }

    if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2 LIMIT 1')) {
      const [pid, uid] = params;
      return { rows: uid === ownerId && pid === petId ? [{ '?column?': 1 }] : [] };
    }

    if (sql.startsWith('SELECT 1 FROM pet_access')) {
      const [pid, uid] = params;
      return { rows: sharedAccess.has(`${pid}:${uid}`) ? [{ '?column?': 1 }] : [] };
    }

    if (sql.includes('SELECT 1 FROM weight_entries we') && sql.includes('JOIN pets p')) {
      return { rows: [{ '?column?': 1 }] };
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

    if (sql.includes('UPDATE weight_entries SET')) {
      return {
        rows: [{
          id: params[4],
          pet_id: petId,
          weight: params[0],
          unit: params[1],
          date: params[2],
          notes: params[3],
          created_at: new Date(),
        }],
      };
    }

    if (sql.includes('DELETE FROM weight_entries WHERE id = $1')) {
      return { rows: [] };
    }

    if (sql.includes('SELECT 1 FROM health_entries he') && sql.includes('JOIN pets p')) {
      return { rows: [{ '?column?': 1 }] };
    }

    if (sql.includes('SELECT 1 FROM health_issues hi') && sql.includes('JOIN pets p')) {
      return { rows: [{ '?column?': 1 }] };
    }

    if (sql.includes('SELECT organization_id FROM pets WHERE id = $1')) {
      return { rows: [{ organization_id: null }] };
    }

    if (sql.includes('UPDATE pets SET name=$1')) {
      return {
        rows: [{
          id: petId,
          user_id: ownerId,
          name: params[0],
          species: params[1],
          breed: params[2],
          age: params[3],
          date_of_birth: params[4],
          weight: params[5],
          gender: params[6],
          bio: params[7],
          insurance: params[8],
          neutered_date: params[9],
          neuter_dismissed: params[10],
          chip_id: params[11],
          chip_dismissed: params[12],
          photo_path: params[13],
          vet_id: params[14],
          color_index: params[15],
          passed_away: params[16],
          organization_id: params[17],
          created_at: new Date(),
          updated_at: new Date(),
        }],
      };
    }

    if (sql.includes('DELETE FROM pets WHERE id = $1 AND user_id = $2')) {
      const [, uid] = params;
      return { rows: uid === ownerId ? [{ id: petId }] : [] };
    }

    if (sql.includes('SELECT p.user_id FROM pets p WHERE p.id = $1')) {
      return { rows: [{ user_id: ownerId }, { user_id: sharedUserId }] };
    }

    if (sql.includes('SELECT preference, value FROM notification_preferences')) {
      return { rows: [] };
    }

    if (sql.includes('SELECT 1 FROM notifications') && sql.includes('health_entry_id')) {
      return { rows: [] };
    }

    if (sql.includes('INSERT INTO notifications')) {
      return { rows: [] };
    }

    return { rows: [] };
  };

  return {
    query: handler,
    end: async () => {},
  };
}

describe('Shared pet collaborator access', () => {
  let app;

  beforeAll(() => {
    app = createApp(buildMockPool());
  });

  describe('Weight entries', () => {
    it('allows shared user to list weight entries for followed pet', async () => {
      const res = await request(app)
        .get(`/api/weight-entries?pet_id=${petId}`)
        .set('Authorization', `Bearer ${sharedToken}`);
      expect(res.statusCode).toBe(200);
      expect(res.body.length).toBe(1);
      expect(res.body[0].weight).toBe(10);
    });

    it('allows shared user to create weight entry', async () => {
      const res = await request(app)
        .post('/api/weight-entries')
        .set('Authorization', `Bearer ${sharedToken}`)
        .send({ pet_id: petId, weight: 11, unit: 'kg', date: '2026-02-01' });
      expect(res.statusCode).toBe(201);
    });

    it('denies unrelated user', async () => {
      const stranger = jwt.sign({ id: 'stranger', email: 's@example.com' }, JWT_SECRET, { expiresIn: '1h' });
      const res = await request(app)
        .get(`/api/weight-entries?pet_id=${petId}`)
        .set('Authorization', `Bearer ${stranger}`);
      expect(res.statusCode).toBe(403);
    });
  });

  describe('Health entries', () => {
    it('allows shared user to list health entries', async () => {
      const res = await request(app)
        .get(`/api/health-entries?pet_id=${petId}`)
        .set('Authorization', `Bearer ${sharedToken}`);
      expect(res.statusCode).toBe(200);
      expect(res.body.length).toBe(1);
      expect(res.body[0].name).toBe('Vaccine');
    });
  });

  describe('Health issues', () => {
    it('allows shared user to list health issues', async () => {
      const res = await request(app)
        .get(`/api/health-issues?pet_id=${petId}`)
        .set('Authorization', `Bearer ${sharedToken}`);
      expect(res.statusCode).toBe(200);
      expect(res.body.length).toBe(1);
      expect(res.body[0].name).toBe('Allergy');
    });
  });

  describe('Pet profile', () => {
    it('allows shared user to update pet profile', async () => {
      const res = await request(app)
        .put(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${sharedToken}`)
        .send({
          name: 'Buddy Updated',
          species: 'dog',
          breed: 'Lab',
        });
      expect(res.statusCode).toBe(200);
      expect(res.body.name).toBe('Buddy Updated');
    });

    it('denies shared user from deleting pet', async () => {
      const res = await request(app)
        .delete(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${sharedToken}`);
      expect(res.statusCode).toBe(404);
    });

    it('allows owner to delete pet', async () => {
      const res = await request(app)
        .delete(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${ownerToken}`);
      expect(res.statusCode).toBe(200);
    });
  });

  describe('Notifications check-due', () => {
    it('returns checked true for shared user', async () => {
      const res = await request(app)
        .post('/api/notifications/check-due')
        .set('Authorization', `Bearer ${sharedToken}`)
        .send({ pet_names: { [petId]: 'Buddy' } });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('checked', true);
    });
  });
});
