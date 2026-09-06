import request from 'supertest';
import jwt from 'jsonwebtoken';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { createApp } from '../bin/server.js';
import { handlePetAccessQuery, handleManageEntryQuery } from './helpers/petAccessMocks.js';

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
    completed_on: null,
    recurrence_anchor: 'from_completion',
    repeat_end_date: null,
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

function entryIdFromUpdate(params) {
  if (!params) return 'he-1';
  return params[params.length - 2] ?? params[0];
}

describe('Health Entries API', () => {
  let app;
  let lastQuery;
  let queryLog;
  let uploadDir;
  let lastInsertedEntry;

  beforeAll(() => {
    uploadDir = fs.mkdtempSync(path.join(os.tmpdir(), 'health-documents-'));
    process.env.HEALTH_UPLOAD_DIR = uploadDir;
    const mockPool = {
      query: async (sql, params) => {
        lastQuery = { sql, params };
        if (queryLog) queryLog.push({ sql, params });

        const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: ['pet-1', 'pet-2'] });
        if (access) return access;

        const manageEntry = handleManageEntryQuery(sql, params, { tableName: 'health_entries he' });
        if (manageEntry) return manageEntry;

        // Pet ownership check used by create (non-LIMIT legacy pattern).
        if (sql.includes('SELECT 1 FROM pets WHERE id') && !sql.includes('LIMIT 1')) {
          if (params && params[0] === 'pet-notmine') return { rows: [] };
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

        if (sql.includes('SELECT * FROM health_entries WHERE id')) {
          if (params && params[0] === 'nonexistent') return { rows: [] };
          if (lastInsertedEntry && lastInsertedEntry.id === params[0]) {
            return { rows: [lastInsertedEntry] };
          }
          return { rows: [makeHealthRow({ id: params[0] })] };
        }

        if (sql.includes('INSERT INTO health_entries')) {
          lastInsertedEntry = makeHealthRow({
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
            completed_on: params[11],
            recurrence_anchor: params[12],
            repeat_end_date: params[13],
            notes: params[14],
            health_issue_id: params[15],
            remind_days_before: params[16],
            schedule_times: params[17],
            status: params[18],
            completed_at: null,
          });
          return { rows: [lastInsertedEntry] };
        }

        if (sql.includes('INSERT INTO health_occurrences')) {
          return { rows: [{ id: params[0] }] };
        }

        if (sql.includes('UPDATE health_entries SET next_due_date')) {
          if (lastInsertedEntry && lastInsertedEntry.id === params[1]) {
            lastInsertedEntry = {
              ...lastInsertedEntry,
              next_due_date: params[0] ? new Date(params[0]) : null,
            };
          }
          return { rows: [makeHealthRow({ id: params[1], next_due_date: params[0] ? new Date(params[0]) : null })] };
        }

        if (sql.includes('SELECT id FROM health_occurrences') && sql.includes('status = \'pending\'')) {
          return { rows: [] };
        }

        if (sql.includes('SELECT scheduled_date, scheduled_time FROM health_occurrences')) {
          return { rows: [{ scheduled_date: new Date('2026-06-30'), scheduled_time: null }] };
        }

        if (sql.includes("UPDATE health_entries SET status = 'completed', completed_on")) {
          if (params && params[2] === 'nonexistent') return { rows: [] };
          return { rows: [makeHealthRow({ id: params[2], status: 'completed', completed_at: params[1], completed_on: params[0], next_due_date: null })] };
        }

        if (sql.includes("UPDATE health_entries SET status = 'active', completed_on = NULL, completed_at = $1")) {
          if (params && params[2] === 'nonexistent') return { rows: [] };
          return { rows: [makeHealthRow({ id: params[2], status: 'active', completed_on: null, completed_at: params[0], next_due_date: params[1] })] };
        }

        if (sql.includes('UPDATE health_entries SET status = \'active\', completed_on = NULL, completed_at = NULL')) {
          if (params && params[1] === 'nonexistent') return { rows: [] };
          return { rows: [makeHealthRow({ id: params[1], status: 'active', completed_at: null, completed_on: null })] };
        }

        if (sql.includes("UPDATE health_entries SET status = 'completed', repeat_end_date")) {
          if (params && params[1] === 'nonexistent') return { rows: [] };
          return { rows: [makeHealthRow({ id: params[1], status: 'completed', repeat_end_date: params[0] })] };
        }

        if (sql.includes("UPDATE health_entries SET status = 'active', repeat_end_date = NULL")) {
          if (params && params[0] === 'nonexistent') return { rows: [] };
          return { rows: [makeHealthRow({ id: params[0], status: 'active', repeat_end_date: null, next_due_date: null })] };
        }

        if (sql.includes("UPDATE health_entries SET status = 'completed'") ||
            sql.includes('UPDATE health_entries SET status = \'completed\'')) {
          if (params && (params[2] === 'nonexistent' || params[3] === 'nonexistent')) return { rows: [] };
          return { rows: [makeHealthRow({ id: entryIdFromUpdate(params), status: 'active', completed_at: params[0], next_due_date: params[1] })] };
        }

        if (sql.includes('UPDATE health_entries SET name')) {
          if (params && params[15] === 'nonexistent') return { rows: [] };
          return {
            rows: [makeHealthRow({
              id: params[15],
              name: params[0],
              type: params[1],
              dosage: params[2],
              frequency: params[3],
            })],
          };
        }

        if (sql.includes("UPDATE health_history SET status = 'undone'")) {
          return { rows: [] };
        }

        if (sql.includes("INSERT INTO health_history") && sql.includes("'skipped'")) {
          return { rows: [] };
        }

        if (sql.includes('SELECT id FROM health_history WHERE health_entry_id') && sql.includes("'skipped'")) {
          return { rows: [] };
        }

        if (sql.includes('SELECT hh.*') && sql.includes('WHERE hh.id = $1')) {
          return {
            rows: [{
              id: params[0],
              health_entry_id: 'he-1',
              status: 'skipped',
              notes: '',
              due_date: new Date('2025-06-01'),
              completed_on: null,
              changed_at: new Date('2025-06-01'),
              marked_by_user_id: userId,
              marked_by_name: 'Test User',
            }],
          };
        }

        if (sql.includes('SELECT * FROM health_history WHERE id = $1 AND health_entry_id')) {
          if (params && params[0] === 'hh-missing') return { rows: [] };
          if (params && params[0] === 'hh-completed') {
            return {
              rows: [{
                id: params[0],
                health_entry_id: params[1],
                status: 'completed',
                due_date: new Date('2025-06-01'),
              }],
            };
          }
          return {
            rows: [{
              id: params[0],
              health_entry_id: params[1],
              status: 'skipped',
              due_date: new Date('2025-06-01'),
            }],
          };
        }

        if (sql.includes('DELETE FROM health_history WHERE id = $1')) {
          return { rows: [] };
        }

        if (sql.includes('SELECT * FROM health_history WHERE health_entry_id = $1') && sql.includes('ORDER BY changed_at DESC LIMIT 1')) {
          if (params && params[0] === 'he-no-history') return { rows: [] };
          if (params && params[0] === 'he-skipped-last') {
            return {
              rows: [{
                id: 'hh-skipped',
                health_entry_id: params[0],
                status: 'skipped',
                due_date: new Date('2025-06-01'),
              }],
            };
          }
          return {
            rows: [{
              id: 'hh-1',
              health_entry_id: params[0],
              status: 'completed',
              due_date: new Date('2025-06-01'),
              completed_on: new Date('2025-06-01'),
            }],
          };
        }

        if (sql.includes('INSERT INTO health_history')) {
          return { rows: [] };
        }

        if (sql.includes('DELETE FROM health_entries')) {
          return { rows: [] };
        }

        if (sql.includes('SELECT hh.*') || sql.includes('SELECT * FROM health_history')) {
          return {
            rows: [{
              id: 'hh-1',
              health_entry_id: params[0],
              status: 'completed',
              notes: '',
              due_date: new Date('2025-06-01'),
              completed_on: new Date('2025-06-01'),
              changed_at: new Date('2025-06-01'),
              marked_by_user_id: userId,
              marked_by_name: 'Test User',
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
    lastInsertedEntry = null;
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

    it('POST /api/health-entries/:id/close returns 401 without token', async () => {
      const res = await request(app).post('/api/health-entries/he-1/close');
      expect(res.statusCode).toBe(401);
    });

    it('POST /api/health-entries/:id/reopen returns 401 without token', async () => {
      const res = await request(app).post('/api/health-entries/he-1/reopen');
      expect(res.statusCode).toBe(401);
    });

    it('POST /api/health-entries/:id/skip returns 401 without token', async () => {
      const res = await request(app).post('/api/health-entries/he-1/skip');
      expect(res.statusCode).toBe(401);
    });

    it('POST /api/health-entries/:id/unskip returns 401 without token', async () => {
      const res = await request(app).post('/api/health-entries/he-1/unskip');
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

    it('returns start_date and next_due_date as date-only strings', async () => {
      const res = await request(app)
        .get('/api/health-entries')
        .set('Authorization', `Bearer ${token}`);
      const entry = res.body[0];
      expect(entry.start_date).toBe('2025-01-01');
      expect(entry.next_due_date).toBe('2026-01-01');
      expect(entry.start_date).not.toMatch(/T/);
      expect(entry.next_due_date).not.toMatch(/T/);
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
      expect(lines[0]).toBe('id,pet_name,name,type,dosage,frequency,start_date,next_due_date,completed_on,recurrence_anchor,notes');
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

    it('serializes calendar date columns as YYYY-MM-DD', async () => {
      const pool = {
        query: async () => ({
          rows: [makeHealthRow({
            start_date: new Date('2025-01-01T00:00:00.000Z'),
            next_due_date: new Date('2026-02-01T00:00:00.000Z'),
            completed_on: null,
          })],
        }),
        end: async () => {},
      };
      const a = createApp(pool);
      const res = await request(a)
        .get('/api/health-entries/export')
        .set('Authorization', `Bearer ${token}`);
      const dataLine = res.text.split('\n')[1];
      expect(dataLine).toContain('2025-01-01');
      expect(dataLine).toContain('2026-02-01');
      expect(dataLine).not.toMatch(/T\d{2}:/);
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

    it('maps legacy family_event and procedure types to other on read', async () => {
      for (const legacyType of ['family_event', 'procedure']) {
        const pool = {
          query: async (sql, params) => {
            const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: ['pet-1'] });
            if (access) return access;
            const manageEntry = handleManageEntryQuery(sql, params, { tableName: 'health_entries he' });
            if (manageEntry) return manageEntry;
            if (sql.includes('SELECT he.*') && sql.includes('WHERE he.id')) {
              return { rows: [makeHealthRow({ id: params[0], type: legacyType })] };
            }
            return { rows: [] };
          },
          end: async () => {},
        };
        const a = createApp(pool);
        const res = await request(a)
          .get('/api/health-entries/he-legacy')
          .set('Authorization', `Bearer ${token}`);
        expect(res.statusCode).toBe(200);
        expect(res.body).toHaveProperty('type', 'other');
      }
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
      const entry = { pet_id: 'pet-1', name: 'Simple', next_due_date: '2025-01-01' };
      const res = await request(app)
        .post('/api/health-entries')
        .set('Authorization', `Bearer ${token}`)
        .send(entry);
      expect(res.statusCode).toBe(201);
      const insertParams = queryLog.find(q => q.sql.includes('INSERT INTO health_entries')).params;
      expect(insertParams[4]).toBe('vet_visit');
      expect(insertParams[6]).toBe('once');
      expect(insertParams[10]).toBe('2025-01-01');
    });

    it('normalizes legacy ISO timestamp inputs to date-only for storage', async () => {
      const entry = {
        pet_id: 'pet-1',
        name: 'Legacy',
        next_due_date: '2026-06-30T09:00:00.000Z',
        start_date: '2026-06-30T00:00:00.000Z',
      };
      const res = await request(app)
        .post('/api/health-entries')
        .set('Authorization', `Bearer ${token}`)
        .send(entry);
      expect(res.statusCode).toBe(201);
      const insertParams = queryLog.find(q => q.sql.includes('INSERT INTO health_entries')).params;
      expect(insertParams[9]).toBe('2026-06-30');
      expect(insertParams[10]).toBe('2026-06-30');
      expect(res.body.next_due_date).toBe('2026-06-30');
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
      expect(insertParams[15]).toBe('hi-1');
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

    it('accepts canonical other type on create', async () => {
      const entry = {
        pet_id: 'pet-1',
        name: 'Grooming',
        type: 'other',
        next_due_date: '2025-01-01',
      };
      const res = await request(app)
        .post('/api/health-entries')
        .set('Authorization', `Bearer ${token}`)
        .send(entry);
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('type', 'other');
    });

    it('rejects deprecated family_event type on create', async () => {
      const entry = {
        pet_id: 'pet-1',
        name: 'Legacy care',
        type: 'family_event',
        next_due_date: '2025-01-01',
      };
      const res = await request(app)
        .post('/api/health-entries')
        .set('Authorization', `Bearer ${token}`)
        .send(entry);
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/Deprecated entry type/i);
    });

    it('rejects deprecated procedure type on create', async () => {
      const entry = {
        pet_id: 'pet-1',
        name: 'Legacy other',
        type: 'procedure',
        next_due_date: '2025-01-01',
      };
      const res = await request(app)
        .post('/api/health-entries')
        .set('Authorization', `Bearer ${token}`)
        .send(entry);
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/Deprecated entry type/i);
    });
  });

  describe('PUT /api/health-entries/:id (update)', () => {
    it('updates a health entry', async () => {
      const entry = { name: 'Updated', type: 'medication', dosage: '2ml', frequency: 'daily', next_due_date: '2026-01-01' };
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
        .send({ name: 'Nope', next_due_date: '2026-01-01' });
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error', 'Entry not found');
    });

    it('checks pet access before update', async () => {
      await request(app)
        .put('/api/health-entries/he-1')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Test', next_due_date: '2026-01-01' });
      const accessQuery = queryLog.find(
        (q) => q.sql.includes('SELECT pet_id FROM health_entries') || (q.sql.includes('SELECT 1 FROM health_entries he') && q.sql.includes('JOIN pets p')),
      );
      const updateQuery = queryLog.find(q => q.sql.includes('UPDATE health_entries SET name'));
      expect(accessQuery).toBeDefined();
      expect(updateQuery.params[15]).toBe('he-1');
    });

    it('rejects deprecated types on update', async () => {
      const res = await request(app)
        .put('/api/health-entries/he-1')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Legacy', type: 'family_event', next_due_date: '2026-01-01' });
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/Deprecated entry type/i);
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

    it('scopes delete by entry id', async () => {
      await request(app)
        .delete('/api/health-entries/he-1')
        .set('Authorization', `Bearer ${token}`);
      expect(lastQuery.sql).toContain('DELETE FROM health_entries WHERE id = $1');
      expect(lastQuery.params[0]).toBe('he-1');
    });
  });

  describe('POST /api/health-entries/:id/mark-taken', () => {
    it('marks entry as completed and inserts history', async () => {
      const res = await request(app)
        .post('/api/health-entries/he-1/mark-taken')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
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
        q.sql.includes("UPDATE health_entries SET status = 'active', completed_on = NULL"));
      expect(update).toBeDefined();
      expect(update.params[1]).toMatch(/^\d{4}-\d{2}-\d{2}$/);
      expect(update.params[1]).not.toMatch(/T/);
    });

    it('does not hang and still advances when interval is zero', async () => {
      const res = await request(app)
        .post('/api/health-entries/he-zero/mark-taken')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      const update = queryLog.find(q =>
        q.sql.includes("UPDATE health_entries SET status = 'active', completed_on = NULL"));
      expect(update.params[1]).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    });

    it('sets next_due_date to null for once entries', async () => {
      await request(app)
        .post('/api/health-entries/he-once/mark-taken')
        .set('Authorization', `Bearer ${token}`);

      const update = queryLog.find(q =>
        q.sql.includes("UPDATE health_entries SET status = 'completed', completed_on"));
      expect(update).toBeDefined();
      expect(update.sql).toContain('next_due_date = NULL');
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
        q.sql.includes("UPDATE health_entries SET status = 'active', completed_on = NULL, completed_at ="));
      expect(update).toBeDefined();
      expect(update.sql).toContain('next_due_date = CASE WHEN frequency');
    });

    it('returns 404 for nonexistent entry', async () => {
      const res = await request(app)
        .post('/api/health-entries/nonexistent/undo-complete')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
    });

    it('returns 400 when latest history is not completed', async () => {
      const res = await request(app)
        .post('/api/health-entries/he-skipped-last/undo-complete')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/unmark/i);
    });

    it('returns 400 when no history exists', async () => {
      const res = await request(app)
        .post('/api/health-entries/he-no-history/undo-complete')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(400);
    });
  });

  describe('POST /api/health-entries/:id/close', () => {
    it('sets status completed and repeat_end_date to yesterday', async () => {
      const res = await request(app)
        .post('/api/health-entries/he-1/close')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('status', 'completed');
      expect(res.body.repeat_end_date).toMatch(/^\d{4}-\d{2}-\d{2}$/);

      const update = queryLog.find(q =>
        q.sql.includes("UPDATE health_entries SET status = 'completed', repeat_end_date"));
      expect(update).toBeDefined();
      expect(update.params[0]).toMatch(/^\d{4}-\d{2}-\d{2}$/);
      expect(update.params[1]).toBe('he-1');
    });

    it('returns 404 for nonexistent entry', async () => {
      const res = await request(app)
        .post('/api/health-entries/nonexistent/close')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
    });
  });

  describe('POST /api/health-entries/:id/reopen', () => {
    it('sets status active and clears repeat_end_date and next_due_date', async () => {
      const res = await request(app)
        .post('/api/health-entries/he-1/reopen')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('status', 'active');
      expect(res.body.repeat_end_date).toBeNull();
      expect(res.body.next_due_date).toBeNull();

      const update = queryLog.find(q =>
        q.sql.includes("UPDATE health_entries SET status = 'active', repeat_end_date = NULL"));
      expect(update).toBeDefined();
      expect(update.params[0]).toBe('he-1');
    });

    it('returns 404 for nonexistent entry', async () => {
      const res = await request(app)
        .post('/api/health-entries/nonexistent/reopen')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
    });
  });

  describe('POST /api/health-entries/:id/skip', () => {
    it('inserts skipped history row without updating entry', async () => {
      const res = await request(app)
        .post('/api/health-entries/he-1/skip')
        .set('Authorization', `Bearer ${token}`)
        .send({ due_date: '2025-06-01' });
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('status', 'skipped');
      expect(res.body).toHaveProperty('due_date', '2025-06-01');

      const insert = queryLog.find(q =>
        q.sql.includes('INSERT INTO health_history') && q.sql.includes("'skipped'"));
      expect(insert).toBeDefined();
      expect(insert.params[3]).toBe('2025-06-01');

      const entryUpdate = queryLog.find(q =>
        q.sql.includes('UPDATE health_entries') && !q.sql.includes('repeat_end_date'));
      expect(entryUpdate).toBeUndefined();
    });

    it('requires due_date', async () => {
      const res = await request(app)
        .post('/api/health-entries/he-1/skip')
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/due_date/i);
    });

    it('returns 404 for nonexistent entry', async () => {
      const res = await request(app)
        .post('/api/health-entries/nonexistent/skip')
        .set('Authorization', `Bearer ${token}`)
        .send({ due_date: '2025-06-01' });
      expect(res.statusCode).toBe(404);
    });
  });

  describe('POST /api/health-entries/:id/unskip', () => {
    it('deletes skipped history row', async () => {
      const res = await request(app)
        .post('/api/health-entries/he-1/unskip')
        .set('Authorization', `Bearer ${token}`)
        .send({ history_id: 'hh-skipped' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('deleted', true);
      expect(res.body).toHaveProperty('history_id', 'hh-skipped');

      const del = queryLog.find(q => q.sql.includes('DELETE FROM health_history WHERE id'));
      expect(del).toBeDefined();
      expect(del.params[0]).toBe('hh-skipped');
    });

    it('requires history_id', async () => {
      const res = await request(app)
        .post('/api/health-entries/he-1/unskip')
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/history_id/i);
    });

    it('rejects non-skipped history rows', async () => {
      const res = await request(app)
        .post('/api/health-entries/he-1/unskip')
        .set('Authorization', `Bearer ${token}`)
        .send({ history_id: 'hh-completed' });
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/skipped/i);
    });

    it('returns 404 for missing history row', async () => {
      const res = await request(app)
        .post('/api/health-entries/he-1/unskip')
        .set('Authorization', `Bearer ${token}`)
        .send({ history_id: 'hh-missing' });
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
      expect(res.body.url).toMatch(
        /^\/api\/health-files\/[0-9a-f-]{36}$/
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
