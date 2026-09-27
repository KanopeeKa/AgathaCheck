import request from 'supertest';
import jwt from 'jsonwebtoken';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { createApp } from '../../bin/server.js';
import { handleManageEntryQuery, handlePetAccessQuery } from '../helpers/petAccessMocks.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const entryId = 'he-1';
const occId = 'occ-1';

describe('Occurrence-scoped health documents', () => {
  let app;
  let queryLog = [];
  let uploadDir;

  beforeAll(() => {
    uploadDir = fs.mkdtempSync(path.join(os.tmpdir(), 'health-documents-'));
    process.env.HEALTH_UPLOAD_DIR = uploadDir;
    const mockPool = {
      query: async (sql, params) => {
        queryLog.push({ sql, params });
        const access = handlePetAccessQuery(sql, params, {
          userId,
          ownedPetIds: ['pet-1'],
        });
        if (access) return access;

        const manageEntry = handleManageEntryQuery(sql, params, {
          tableName: 'health_entries he',
        });
        if (manageEntry) return manageEntry;

        if (sql.includes('SELECT pet_id FROM health_entries WHERE id = $1')) {
          return { rows: [{ pet_id: 'pet-1' }] };
        }

        if (sql.includes('SELECT * FROM health_entries WHERE id = $1')) {
          return {
            rows: [{
              id: entryId,
              pet_id: 'pet-1',
              user_id: userId,
              type: 'medication',
              frequency: 'daily',
            }],
          };
        }

        if (sql.includes('FROM health_occurrences ho') && sql.includes('ho.id = $1')) {
          return {
            rows: [{
              id: occId,
              health_entry_id: entryId,
              status: 'completed',
              notes: '',
              scheduled_date: new Date('2025-06-01'),
              marked_by_name: 'Test User',
            }],
          };
        }

        if (sql.includes('SELECT id FROM health_occurrences') && sql.includes('health_entry_id = $2')) {
          return { rows: [{ id: occId }] };
        }

        if (sql.includes('INSERT INTO health_event_photos')) {
          return {
            rows: [{
              id: params[0],
              health_entry_id: params[1],
              url: params[2],
              health_occurrence_id: params[3],
              created_at: new Date(),
            }],
          };
        }

        if (sql.includes('SELECT * FROM health_event_photos') && sql.includes('ORDER BY')) {
          return {
            rows: [{
              id: 'photo-1',
              health_entry_id: entryId,
              health_occurrence_id: occId,
              url: '/uploads/x.jpg',
              created_at: new Date(),
            }],
          };
        }

        if (sql.includes('UPDATE health_occurrences SET notes = $1')) {
          return {
            rows: [{
              id: occId,
              health_entry_id: entryId,
              status: 'completed',
              notes: params[0],
              scheduled_date: new Date('2025-06-01'),
              scheduled_time: null,
              completed_on: new Date('2025-06-01'),
            }],
          };
        }

        return { rows: [] };
      },
    };
    app = createApp(mockPool);
  });

  afterAll(() => {
    delete process.env.HEALTH_UPLOAD_DIR;
    fs.rmSync(uploadDir, { recursive: true, force: true });
  });

  beforeEach(() => {
    queryLog = [];
  });

  it('POST photo stores health_occurrence_id', async () => {
    const res = await request(app)
      .post(`/api/health-entries/${entryId}/photos`)
      .set('Authorization', `Bearer ${token}`)
      .field('health_occurrence_id', occId)
      .attach('photo', Buffer.from('abc'), 'note.jpg');

    expect(res.statusCode).toBe(201);
    const insert = queryLog.find((q) => q.sql.includes('INSERT INTO health_event_photos'));
    expect(insert.params[3]).toBe(occId);
  });

  it('GET photos filters by occurrence_id', async () => {
    const res = await request(app)
      .get(`/api/health-entries/${entryId}/photos`)
      .query({ occurrence_id: occId })
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toBe(200);
    expect(res.body[0].health_occurrence_id).toBe(occId);
    expect(
      queryLog.some(
        (q) => q.sql.includes('health_occurrence_id = $2') && q.params[1] === occId,
      ),
    ).toBe(true);
  });

  it('PATCH occurrence notes on completed row', async () => {
    const res = await request(app)
      .patch(`/api/health-entries/${entryId}/occurrences/${occId}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ notes: 'Gave with food' });

    expect(res.statusCode).toBe(200);
    expect(res.body.notes).toBe('Gave with food');
  });
});
