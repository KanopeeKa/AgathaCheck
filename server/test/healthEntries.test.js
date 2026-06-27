import request from 'supertest';
import jwt from 'jsonwebtoken';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { createApp } from '../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

function makeHealthRow(overrides = {}) {
  return {
    id: 'he-1',
    pet_id: 'pet-1',
    user_id: userId,
    pet_name: 'Fluffy',
    name: 'Annual Checkup',
    type: 'vet_visit',
    dosage: '1ml',
    frequency: 'yearly',
    frequency_days: null,
    frequency_interval: 1,
    start_date: new Date('2025-01-01'),
    next_due_date: new Date('2026-01-01'),
    notes: 'Bring records',
    health_issue_id: null,
    remind_days_before: 7,
    status: 'active',
    completed_at: null,
    created_at: new Date('2025-01-01'),
    updated_at: new Date('2025-01-02'),
    ...overrides,
  };
}

describe('Health Entries API', () => {
  let app;
  let lastQuery;
  let queryLog;
  let uploadDir;

  beforeAll(() => {
    uploadDir = fs.mkdtempSync(path.join(os.tmpdir(), 'health-documents-'));
    process.env.HEALTH_UPLOAD_DIR = uploadDir;
    const mockPool = {
      query: async (sql, params) => {
        lastQuery = { sql, params };
        if (queryLog) queryLog.push({ sql, params });

        // Pet ownership check used by create. 'pet-notmine' simulates a pet
        // owned by another user.
        if (sql.includes('SELECT 1 FROM pets WHERE id')) {
          if (params && params[0] === 'pet-notmine') return { rows: [] };
          return { rows: [{ exists: 1 }] };
        }
        // Health-entry ownership check used by the nested history/photos routes.
        // 'he-notmine' simulates an entry owned by another user.
        if (sql.includes('SELECT 1 FROM health_entries WHERE id')) {
          if (params && params[0] === 'he-notmine') return { rows: [] };
          return { rows: [{ exists: 1 }] };
        }

        if (sql.includes('SELECT he.*') && sql.includes('WHERE he.id')) {
          if (params && params[0] === 'nonexistent') return { rows: [] };
          if (params && params[0] === 'he-zero') {
            return { rows: [makeHealthRow({ id: params[0], frequency: 'daily', frequency_interval: 0 })] };
          }
          if (params && params[0] === 'he-once') {
            return { rows: [makeHealthRow({ id: params[0], frequency: 'once' })] };
          }
          return { rows: [makeHealthRow({ id: params[0] })] };
        }

        if (sql.includes('SELECT he.*') && sql.includes('FROM health_entries')) {
          return { rows: [makeHealthRow(), makeHealthRow({ id: 'he-2', name: 'Vaccination' })] };
        }

        if (sql.includes('INSERT INTO health_entries')) {
          return {
            rows: [makeHealthRow({
              id: params[0],
              pet_id: params[1],
              user_id: params[2],
              name: params[3],
              type: params[4],
              dosage: params[5],
              frequency: params[6],
              frequency_days: params[7],
              frequency_interval: params[8],
              start_date: params[9],
              next_due_date: params[10],
              notes: params[11],
              health_issue_id: params[12],
              remind_days_before: params[13],
              status: params[14],
              completed_at: null,
            })],
          };
        }

        if (sql.includes("UPDATE health_entries SET status = 'completed'")) {
          if (params && params[0] === 'nonexistent') return { rows: [] };
          return { rows: [makeHealthRow({ id: params[0], status: 'completed', completed_at: new Date() })] };
        }

        if (sql.includes("UPDATE health_entries SET status = 'active'")) {
          if (params && params[0] === 'nonexistent') return { rows: [] };
          return { rows: [makeHealthRow({ id: params[0], status: 'active', completed_at: null })] };
        }

        if (sql.includes('UPDATE health_entries SET name')) {
          if (params && params[12] === 'nonexistent') return { rows: [] };
          return {
            rows: [makeHealthRow({
              id: params[12],
              name: params[0],
              type: params[1],
              dosage: params[2],
              frequency: params[3],
            })],
          };
        }

        if (sql.includes('INSERT INTO health_history')) {
          return { rows: [] };
        }

        if (sql.includes('DELETE FROM health_entries')) {
          return { rows: [] };
        }

        if (sql.includes('SELECT * FROM health_history')) {
          return {
            rows: [{
              id: 'hh-1',
              health_entry_id: params[0],
              status: 'completed',
              notes: 'Marked as taken',
              changed_at: new Date('2025-06-01'),
            }],
          };
        }

        if (sql.includes('SELECT * FROM health_event_photos') && sql.includes('ORDER BY')) {
          return {
            rows: [{
              id: 'photo-1',
              health_entry_id: params[0],
              url: '/uploads/photo1.jpg',
              created_at: new Date(),
            }],
          };
        }

        if (sql.includes('INSERT INTO health_event_photos')) {
          return {
            rows: [{
              id: params[0],
              health_entry_id: params[1],
              url: params[2],
              created_at: new Date(),
            }],
          };
        }

        if (sql.includes('DELETE FROM health_event_photos')) {
          return { rows: [] };
        }

        return { rows: [] };
      },
      end: async () => {},
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

  describe('Auth guard', () => {
    it('GET /api/health-entries returns 401 without token', async () => {
      const res = await request(app).get('/api/health-entries');
      expect(res.statusCode).toBe(401);
    });

    it('GET /api/health-entries/export returns 401 without token', async () => {
      const res = await request(app).get('/api/health-entries/export');
      expect(res.statusCode).toBe(401);
    });

    it('POST /api/health-entries returns 401 without token', async () => {
      const res = await request(app).post('/api/health-entries').send({});
      expect(res.statusCode).toBe(401);
    });

    it('GET /api/health-entries/:id returns 401 without token', async () => {
      const res = await request(app).get('/api/health-entries/he-1');
      expect(res.statusCode).toBe(401);
    });

    it('PUT /api/health-entries/:id returns 401 without token', async () => {
      const res = await request(app).put('/api/health-entries/he-1').send({});
      expect(res.statusCode).toBe(401);
    });

    it('DELETE /api/health-entries/:id returns 401 without token', async () => {
      const res = await request(app).delete('/api/health-entries/he-1');
      expect(res.statusCode).toBe(401);
    });

    it('POST /api/health-entries/:id/mark-taken returns 401 without token', async () => {
      const res = await request(app).post('/api/health-entries/he-1/mark-taken');
      expect(res.statusCode).toBe(401);
    });

    it('POST /api/health-entries/:id/undo-complete returns 401 without token', async () => {
      const res = await request(app).post('/api/health-entries/he-1/undo-complete');
      expect(res.statusCode).toBe(401);
    });
  });

  describe('GET /api/health-entries (list)', () => {
    it('returns array of health entries', async () => {
      const res = await request(app)
        .get('/api/health-entries')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBe(2);
    });

    it('returns entries with all mapped fields', async () => {
      const res = await request(app)
        .get('/api/health-entries')
        .set('Authorization', `Bearer ${token}`);
      const entry = res.body[0];
      expect(entry).toHaveProperty('id');
      expect(entry).toHaveProperty('pet_id');
      expect(entry).toHaveProperty('user_id');
      expect(entry).toHaveProperty('pet_name');
      expect(entry).toHaveProperty('name');
      expect(entry).toHaveProperty('type');
      expect(entry).toHaveProperty('dosage');
      expect(entry).toHaveProperty('frequency');
      expect(entry).toHaveProperty('frequency_days');
      expect(entry).toHaveProperty('frequency_interval');
      expect(entry).toHaveProperty('start_date');
      expect(entry).toHaveProperty('next_due_date');
      expect(entry).toHaveProperty('notes');
      expect(entry).toHaveProperty('health_issue_id');
      expect(entry).toHaveProperty('remind_days_before');
      expect(entry).toHaveProperty('status');
      expect(entry).toHaveProperty('completed_at');
      expect(entry).toHaveProperty('created_at');
      expect(entry).toHaveProperty('updated_at');
    });

    it('filters by pet_id query param', async () => {
      const res = await request(app)
        .get('/api/health-entries?pet_id=pet-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(lastQuery.params).toContain('pet-1');
    });
  });

  describe('GET /api/health-entries/export (CSV)', () => {
    it('returns CSV with correct content type', async () => {
      const res = await request(app)
        .get('/api/health-entries/export')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.headers['content-type']).toContain('text/csv');
    });

    it('CSV has header row', async () => {
      const res = await request(app)
        .get('/api/health-entries/export')
        .set('Authorization', `Bearer ${token}`);
      const lines = res.text.split('\n');
      expect(lines[0]).toBe('id,pet_name,name,type,dosage,frequency,start_date,next_due_date,notes');
    });

    it('escapes commas/quotes and neutralizes formula injection', async () => {
      const pool = {
        query: async () => ({
          rows: [makeHealthRow({
            name: 'Med, "special"',
            notes: '=cmd|/c calc',
          })],
        }),
        end: async () => {},
      };
      const a = createApp(pool);
      const res = await request(a)
        .get('/api/health-entries/export')
        .set('Authorization', `Bearer ${token}`);
      // Comma/quote field is wrapped in quotes with doubled inner quotes.
      expect(res.text).toContain('"Med, ""special"""');
      // Formula-trigger cell is prefixed with a single quote so spreadsheets
      // don't execute it.
      expect(res.text).toContain("'=cmd|/c calc");
    });
  });

  describe('GET /api/health-entries/:id', () => {
    it('returns a single health entry', async () => {
      const res = await request(app)
        .get('/api/health-entries/he-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('id', 'he-1');
      expect(res.body).toHaveProperty('name');
      expect(res.body).toHaveProperty('pet_name');
    });

    it('returns 404 for nonexistent entry', async () => {
      const res = await request(app)
        .get('/api/health-entries/nonexistent')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error', 'Entry not found');
    });
  });

  describe('POST /api/health-entries (create)', () => {
    it('creates a health entry with all fields', async () => {
      const entry = {
        pet_id: 'pet-1',
        name: 'Flea Treatment',
        type: 'preventive',
        dosage: '0.5ml',
        frequency: 'monthly',
        frequency_days: 30,
        frequency_interval: 1,
        start_date: '2025-06-01',
        next_due_date: '2025-07-01',
        notes: 'Apply topically',
        health_issue_id: 'issue-1',
        remind_days_before: 3,
        status: 'active',
      };
      const res = await request(app)
        .post('/api/health-entries')
        .set('Authorization', `Bearer ${token}`)
        .send(entry);
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('name', 'Flea Treatment');
      expect(res.body).toHaveProperty('type', 'preventive');
      expect(res.body).toHaveProperty('dosage', '0.5ml');
      expect(res.body).toHaveProperty('frequency', 'monthly');
      expect(res.body).toHaveProperty('status', 'active');
    });

    it('defaults type to vet_visit and frequency to once', async () => {
      const entry = { pet_id: 'pet-1', name: 'Simple' };
      const res = await request(app)
        .post('/api/health-entries')
        .set('Authorization', `Bearer ${token}`)
        .send(entry);
      expect(res.statusCode).toBe(201);
      const insertParams = queryLog.find(q => q.sql.includes('INSERT INTO health_entries')).params;
      expect(insertParams[4]).toBe('vet_visit');
      expect(insertParams[6]).toBe('once');
    });

    it('accepts camelCase field aliases', async () => {
      const entry = { petId: 'pet-2', name: 'Test', startDate: '2025-01-01', nextDueDate: '2025-02-01', healthIssueId: 'hi-1' };
      const res = await request(app)
        .post('/api/health-entries')
        .set('Authorization', `Bearer ${token}`)
        .send(entry);
      expect(res.statusCode).toBe(201);
      const insertParams = queryLog.find(q => q.sql.includes('INSERT INTO health_entries')).params;
      expect(insertParams[1]).toBe('pet-2');
      expect(insertParams[9]).toBe('2025-01-01');
      expect(insertParams[10]).toBe('2025-02-01');
      expect(insertParams[12]).toBe('hi-1');
    });

    it('returns 403 when the pet belongs to another user', async () => {
      const res = await request(app)
        .post('/api/health-entries')
        .set('Authorization', `Bearer ${token}`)
        .send({ pet_id: 'pet-notmine', name: 'Sneaky' });
      expect(res.statusCode).toBe(403);
    });

    it('returns 403 when no pet_id is provided', async () => {
      const res = await request(app)
        .post('/api/health-entries')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Orphan' });
      expect(res.statusCode).toBe(403);
    });
  });

  describe('PUT /api/health-entries/:id (update)', () => {
    it('updates a health entry', async () => {
      const entry = { name: 'Updated', type: 'medication', dosage: '2ml', frequency: 'daily' };
      const res = await request(app)
        .put('/api/health-entries/he-1')
        .set('Authorization', `Bearer ${token}`)
        .send(entry);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('name');
    });

    it('returns 404 for nonexistent entry', async () => {
      const res = await request(app)
        .put('/api/health-entries/nonexistent')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Nope' });
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error', 'Entry not found');
    });

    it('scopes update by user_id', async () => {
      await request(app)
        .put('/api/health-entries/he-1')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Test' });
      const updateQuery = queryLog.find(q => q.sql.includes('UPDATE health_entries SET name'));
      expect(updateQuery.params).toContain(userId);
    });
  });

  describe('DELETE /api/health-entries/:id', () => {
    it('deletes a health entry', async () => {
      const res = await request(app)
        .delete('/api/health-entries/he-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('deleted', true);
    });

    it('scopes delete by user_id', async () => {
      await request(app)
        .delete('/api/health-entries/he-1')
        .set('Authorization', `Bearer ${token}`);
      expect(lastQuery.params).toContain(userId);
    });
  });

  describe('POST /api/health-entries/:id/mark-taken', () => {
    it('marks entry as completed and inserts history', async () => {
      const res = await request(app)
        .post('/api/health-entries/he-1/mark-taken')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('status', 'completed');
      expect(res.body).toHaveProperty('completed_at');
      expect(res.body.completed_at).not.toBeNull();

      const historyInsert = queryLog.find(q => q.sql.includes('INSERT INTO health_history'));
      expect(historyInsert).toBeDefined();
      expect(historyInsert.params[1]).toBe('he-1');
    });

    it('advances next_due_date to a future date for recurring entries', async () => {
      await request(app)
        .post('/api/health-entries/he-1/mark-taken')
        .set('Authorization', `Bearer ${token}`);

      const update = queryLog.find(q =>
        q.sql.includes("UPDATE health_entries SET status = 'completed'"));
      expect(update).toBeDefined();
      const newDue = new Date(update.params[0]);
      expect(newDue.getTime()).toBeGreaterThan(Date.now());
      expect(newDue.getFullYear()).toBeLessThan(9999);
    });

    it('does not hang and still advances when interval is zero', async () => {
      const res = await request(app)
        .post('/api/health-entries/he-zero/mark-taken')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      const update = queryLog.find(q =>
        q.sql.includes("UPDATE health_entries SET status = 'completed'"));
      const newDue = new Date(update.params[0]);
      expect(newDue.getTime()).toBeGreaterThan(Date.now());
    });

    it('sets next_due_date to the 9999 sentinel for once entries', async () => {
      await request(app)
        .post('/api/health-entries/he-once/mark-taken')
        .set('Authorization', `Bearer ${token}`);

      const update = queryLog.find(q =>
        q.sql.includes("UPDATE health_entries SET status = 'completed'"));
      expect(update).toBeDefined();
      const newDue = new Date(update.params[0]);
      expect(newDue.getFullYear()).toBe(9999);
    });

    it('returns 404 for nonexistent entry', async () => {
      const res = await request(app)
        .post('/api/health-entries/nonexistent/mark-taken')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
    });
  });

  describe('POST /api/health-entries/:id/undo-complete', () => {
    it('sets status back to active and clears completed_at', async () => {
      const res = await request(app)
        .post('/api/health-entries/he-1/undo-complete')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('status', 'active');
      expect(res.body.completed_at).toBeNull();
    });

    it('restores next_due_date to start_date for once entries', async () => {
      await request(app)
        .post('/api/health-entries/he-1/undo-complete')
        .set('Authorization', `Bearer ${token}`);

      const update = queryLog.find(q =>
        q.sql.includes("UPDATE health_entries SET status = 'active'"));
      expect(update).toBeDefined();
      expect(update.sql).toContain("CASE WHEN frequency = 'once' THEN start_date");
    });

    it('returns 404 for nonexistent entry', async () => {
      const res = await request(app)
        .post('/api/health-entries/nonexistent/undo-complete')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
    });
  });

  describe('GET /api/health-entries/:id/history', () => {
    it('returns 401 without token', async () => {
      const res = await request(app).get('/api/health-entries/he-1/history');
      expect(res.statusCode).toBe(401);
    });

    it('returns history array with mapped fields', async () => {
      const res = await request(app)
        .get('/api/health-entries/he-1/history')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body[0]).toHaveProperty('id');
      expect(res.body[0]).toHaveProperty('health_entry_id');
      expect(res.body[0]).toHaveProperty('status');
      expect(res.body[0]).toHaveProperty('notes');
      expect(res.body[0]).toHaveProperty('changed_at');
    });

    it('returns 404 when the entry belongs to another user (IDOR)', async () => {
      const res = await request(app)
        .get('/api/health-entries/he-notmine/history')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
    });
  });

  describe('GET /api/health-entries/:id/photos', () => {
    it('returns 401 without token', async () => {
      const res = await request(app).get('/api/health-entries/he-1/photos');
      expect(res.statusCode).toBe(401);
    });

    it('returns photos array', async () => {
      const res = await request(app)
        .get('/api/health-entries/he-1/photos')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body[0]).toHaveProperty('id');
      expect(res.body[0]).toHaveProperty('health_entry_id');
      expect(res.body[0]).toHaveProperty('url');
      expect(res.body[0]).toHaveProperty('created_at');
    });

    it('returns 404 when the entry belongs to another user (IDOR)', async () => {
      const res = await request(app)
        .get('/api/health-entries/he-notmine/photos')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
    });
  });

  describe('POST /api/health-entries/:id/photos', () => {
    it('returns 401 without token', async () => {
      const res = await request(app)
        .post('/api/health-entries/he-1/photos')
        .send({ url: '/uploads/test.jpg' });
      expect(res.statusCode).toBe(401);
    });

    it('creates a photo record', async () => {
      const res = await request(app)
        .post('/api/health-entries/he-1/photos')
        .set('Authorization', `Bearer ${token}`)
        .send({ url: '/uploads/test.jpg' });
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('id');
      expect(res.body).toHaveProperty('health_entry_id');
      expect(res.body).toHaveProperty('url');
    });

    it.each([
      ['JPG', 'document.jpg', 'image/jpeg'],
      ['PNG', 'document.png', 'image/png'],
      ['PDF', 'document.pdf', 'application/pdf'],
    ])('accepts %s document uploads up to 2 MB', async (_label, filename, contentType) => {
      const res = await request(app)
        .post('/api/health-entries/he-1/photos')
        .set('Authorization', `Bearer ${token}`)
        .attach('photo', Buffer.from('document'), { filename, contentType });
      expect(res.statusCode).toBe(201);
      expect(lastQuery.params[2]).toMatch(
        new RegExp(`/uploads/health_documents/.+\\.${filename.split('.').pop()}$`)
      );
    });

    it('rejects unsupported document formats', async () => {
      const res = await request(app)
        .post('/api/health-entries/he-1/photos')
        .set('Authorization', `Bearer ${token}`)
        .attach('photo', Buffer.from('document'), {
          filename: 'document.txt',
          contentType: 'text/plain',
        });
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toBe('Only JPG, PNG, and PDF documents are allowed');
    });

    it('rejects documents larger than 2 MB', async () => {
      const res = await request(app)
        .post('/api/health-entries/he-1/photos')
        .set('Authorization', `Bearer ${token}`)
        .attach('photo', Buffer.alloc(2 * 1024 * 1024 + 1), {
          filename: 'document.pdf',
          contentType: 'application/pdf',
        });
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toBe('Document must be 2 MB or smaller');
    });

    it('returns 404 when the entry belongs to another user (IDOR)', async () => {
      const res = await request(app)
        .post('/api/health-entries/he-notmine/photos')
        .set('Authorization', `Bearer ${token}`)
        .send({ url: '/uploads/test.jpg' });
      expect(res.statusCode).toBe(404);
    });
  });

  describe('DELETE /api/health-entries/:entryId/photos/:photoId', () => {
    it('returns 401 without token', async () => {
      const res = await request(app)
        .delete('/api/health-entries/he-1/photos/photo-1');
      expect(res.statusCode).toBe(401);
    });

    it('deletes a photo', async () => {
      const res = await request(app)
        .delete('/api/health-entries/he-1/photos/photo-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('deleted', true);
    });

    it('returns 404 when the entry belongs to another user (IDOR)', async () => {
      const res = await request(app)
        .delete('/api/health-entries/he-notmine/photos/photo-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
    });
  });
});
