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

function makeIssueRow(overrides = {}) {
  return {
    id: 'hi-1',
    pet_id: 'pet-1',
    user_id: userId,
    pet_name: 'Fluffy',
    name: 'Seasonal Allergy',
    issue_type: 'allergy',
    notes: 'Occurs in spring',
    start_date: new Date('2025-03-01'),
    end_date: new Date('2025-06-01'),
    status: 'active',
    created_at: new Date('2025-01-01'),
    updated_at: new Date('2025-01-02'),
    ...overrides,
  };
}

describe('Health Issues API', () => {
  let app;
  let lastQuery;
  let uploadDir;
  let documentCount = 0;

  beforeAll(() => {
    uploadDir = fs.mkdtempSync(path.join(os.tmpdir(), 'health-issue-documents-'));
    process.env.HEALTH_UPLOAD_DIR = uploadDir;
    const mockPool = {
      query: async (sql, params) => {
        lastQuery = { sql, params };

        const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: ['pet-1', 'pet-2'] });
        if (access) return access;

        const manageIssue = handleManageEntryQuery(sql, params, { tableName: 'health_issues hi' });
        if (manageIssue) return manageIssue;

        // Pet ownership check (create). 'pet-notmine' => another user's pet.
        if (sql.includes('SELECT 1 FROM pets WHERE id') && !sql.includes('LIMIT 1')) {
          if (params && params[0] === 'pet-notmine') return { rows: [] };
          return { rows: [{ exists: 1 }] };
        }

        if (sql.includes('SELECT hi.*') && sql.includes('WHERE hi.id')) {
          if (params && params[0] === 'nonexistent') return { rows: [] };
          return { rows: [makeIssueRow({ id: params[0] })] };
        }

        if (sql.includes('SELECT hi.*') && sql.includes('FROM health_issues')) {
          return { rows: [makeIssueRow(), makeIssueRow({ id: 'hi-2', name: 'Ear Infection' })] };
        }

        if (sql.includes('SELECT * FROM health_issues WHERE id')) {
          if (params && params[0] === 'nonexistent') return { rows: [] };
          return { rows: [makeIssueRow({ id: params[0] })] };
        }

        if (sql.includes('INSERT INTO health_issues')) {
          return {
            rows: [makeIssueRow({
              id: params[0],
              pet_id: params[1],
              user_id: params[2],
              name: params[3],
              issue_type: params[4],
              notes: params[5],
              start_date: params[6],
              end_date: params[7],
              status: params[8],
            })],
          };
        }

        if (sql.includes('UPDATE health_issues SET')) {
          if (params && params[6] === 'nonexistent') return { rows: [] };
          return {
            rows: [makeIssueRow({
              id: params[6],
              name: params[0],
              issue_type: params[1],
              notes: params[2],
              start_date: params[3],
              end_date: params[4],
              status: params[5],
            })],
          };
        }

        if (sql.includes('DELETE FROM health_issues')) {
          return { rows: [] };
        }

        if (sql.includes('SELECT url FROM health_issue_documents WHERE health_issue_id')) {
          return {
            rows: [{ url: '/uploads/health_documents/doc-1.pdf' }],
          };
        }

        if (sql.includes('SELECT * FROM health_issue_documents') && sql.includes('ORDER BY')) {
          return {
            rows: [{
              id: 'doc-1',
              health_issue_id: params[0],
              url: '/uploads/health_documents/doc-1.pdf',
              created_at: new Date(),
            }],
          };
        }

        if (sql.includes('SELECT COUNT(*)::int AS count FROM health_issue_documents')) {
          return { rows: [{ count: documentCount }] };
        }

        if (sql.includes('INSERT INTO health_issue_documents')) {
          documentCount += 1;
          return {
            rows: [{
              id: params[0],
              health_issue_id: params[1],
              url: params[2],
              created_at: new Date(),
            }],
          };
        }

        if (sql.includes('SELECT url FROM health_issue_documents WHERE id =')) {
          return {
            rows: [{ url: '/uploads/health_documents/doc-1.pdf' }],
          };
        }

        if (sql.includes('DELETE FROM health_issue_documents')) {
          documentCount = Math.max(0, documentCount - 1);
          return { rows: [] };
        }

        if (sql.includes('SELECT * FROM health_issue_events') && sql.includes('ORDER BY')) {
          return {
            rows: [{
              id: 'evt-1',
              health_issue_id: params[0],
              event_type: 'note',
              notes: 'Flare up',
              created_at: new Date(),
            }],
          };
        }

        if (sql.includes('DELETE FROM health_issue_events')) {
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
    if (uploadDir && fs.existsSync(uploadDir)) {
      fs.rmSync(uploadDir, { recursive: true, force: true });
    }
  });

  beforeEach(() => {
    documentCount = 0;
  });

  describe('Auth guard', () => {
    it('GET /api/health-issues returns 401 without token', async () => {
      const res = await request(app).get('/api/health-issues');
      expect(res.statusCode).toBe(401);
    });

    it('GET /api/health-issues/:id returns 401 without token', async () => {
      const res = await request(app).get('/api/health-issues/hi-1');
      expect(res.statusCode).toBe(401);
    });

    it('POST /api/health-issues returns 401 without token', async () => {
      const res = await request(app).post('/api/health-issues').send({});
      expect(res.statusCode).toBe(401);
    });

    it('PUT /api/health-issues/:id returns 401 without token', async () => {
      const res = await request(app).put('/api/health-issues/hi-1').send({});
      expect(res.statusCode).toBe(401);
    });

    it('DELETE /api/health-issues/:id returns 401 without token', async () => {
      const res = await request(app).delete('/api/health-issues/hi-1');
      expect(res.statusCode).toBe(401);
    });

    it('returns 401 with invalid token', async () => {
      const res = await request(app)
        .get('/api/health-issues')
        .set('Authorization', 'Bearer invalid.token');
      expect(res.statusCode).toBe(401);
    });
  });

  describe('GET /api/health-issues (list)', () => {
    it('returns array of health issues', async () => {
      const res = await request(app)
        .get('/api/health-issues')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBe(2);
    });

    it('returns issues with all mapped fields', async () => {
      const res = await request(app)
        .get('/api/health-issues')
        .set('Authorization', `Bearer ${token}`);
      const issue = res.body[0];
      expect(issue).toHaveProperty('id');
      expect(issue).toHaveProperty('pet_id');
      expect(issue).toHaveProperty('user_id');
      expect(issue).toHaveProperty('pet_name');
      expect(issue).toHaveProperty('title');
      expect(issue).toHaveProperty('name');
      expect(issue).toHaveProperty('description');
      expect(issue).toHaveProperty('issue_type');
      expect(issue).toHaveProperty('notes');
      expect(issue).toHaveProperty('start_date');
      expect(issue).toHaveProperty('end_date');
      expect(issue).toHaveProperty('status');
      expect(issue).toHaveProperty('created_at');
      expect(issue).toHaveProperty('updated_at');
    });

    it('returns start_date and end_date as date-only strings', async () => {
      const res = await request(app)
        .get('/api/health-issues')
        .set('Authorization', `Bearer ${token}`);
      const issue = res.body[0];
      expect(issue.start_date).toBe('2025-03-01');
      expect(issue.end_date).toBe('2025-06-01');
      expect(issue.start_date).not.toMatch(/T/);
    });

    it('title is alias for name', async () => {
      const res = await request(app)
        .get('/api/health-issues')
        .set('Authorization', `Bearer ${token}`);
      expect(res.body[0].title).toBe(res.body[0].name);
    });

    it('description is alias for notes', async () => {
      const res = await request(app)
        .get('/api/health-issues')
        .set('Authorization', `Bearer ${token}`);
      expect(res.body[0].description).toBe(res.body[0].notes);
    });

    it('filters by pet_id query param', async () => {
      const res = await request(app)
        .get('/api/health-issues?pet_id=pet-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(lastQuery.params).toContain('pet-1');
    });

    it('scopes query by user_id', async () => {
      await request(app)
        .get('/api/health-issues')
        .set('Authorization', `Bearer ${token}`);
      expect(lastQuery.params).toContain(userId);
    });
  });

  describe('GET /api/health-issues/:id', () => {
    it('returns a single health issue', async () => {
      const res = await request(app)
        .get('/api/health-issues/hi-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('id', 'hi-1');
      expect(res.body).toHaveProperty('name');
      expect(res.body).toHaveProperty('issue_type');
    });

    it('returns 404 for nonexistent issue', async () => {
      const res = await request(app)
        .get('/api/health-issues/nonexistent')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error', 'Not found');
    });

    it('scopes query by user_id', async () => {
      await request(app)
        .get('/api/health-issues/hi-1')
        .set('Authorization', `Bearer ${token}`);
      expect(lastQuery.params).toContain(userId);
    });
  });

  describe('POST /api/health-issues (create)', () => {
    it('creates a health issue with all fields', async () => {
      const issue = {
        pet_id: 'pet-1',
        title: 'Limping',
        issue_type: 'injury',
        notes: 'Left front leg',
        start_date: '2025-06-01',
        end_date: '2025-07-01',
        status: 'active',
      };
      const res = await request(app)
        .post('/api/health-issues')
        .set('Authorization', `Bearer ${token}`)
        .send(issue);
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('name', 'Limping');
      expect(res.body).toHaveProperty('title', 'Limping');
      expect(res.body).toHaveProperty('issue_type', 'injury');
      expect(res.body).toHaveProperty('notes', 'Left front leg');
    });

    it('accepts name instead of title', async () => {
      const issue = { pet_id: 'pet-1', name: 'Rash', issue_type: 'skin' };
      const res = await request(app)
        .post('/api/health-issues')
        .set('Authorization', `Bearer ${token}`)
        .send(issue);
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('name', 'Rash');
      expect(res.body).toHaveProperty('title', 'Rash');
    });

    it('accepts description as alias for notes', async () => {
      const issue = { pet_id: 'pet-1', name: 'Test', description: 'Some description' };
      const res = await request(app)
        .post('/api/health-issues')
        .set('Authorization', `Bearer ${token}`)
        .send(issue);
      expect(res.statusCode).toBe(201);
      expect(lastQuery.params[5]).toBe('Some description');
    });

    it('normalizes ISO timestamps to date-only on create', async () => {
      await request(app)
        .post('/api/health-issues')
        .set('Authorization', `Bearer ${token}`)
        .send({
          pet_id: 'pet-1',
          name: 'Seasonal',
          start_date: '2025-06-01T00:00:00.000Z',
          end_date: '2025-07-01T00:00:00.000Z',
        });
      expect(lastQuery.params[6]).toBe('2025-06-01');
      expect(lastQuery.params[7]).toBe('2025-07-01');
    });

    it('defaults issue_type to other', async () => {
      const issue = { pet_id: 'pet-1', name: 'Unknown' };
      const res = await request(app)
        .post('/api/health-issues')
        .set('Authorization', `Bearer ${token}`)
        .send(issue);
      expect(res.statusCode).toBe(201);
      expect(lastQuery.params[4]).toBe('other');
    });

    it('defaults status to active', async () => {
      const issue = { pet_id: 'pet-1', name: 'Test' };
      const res = await request(app)
        .post('/api/health-issues')
        .set('Authorization', `Bearer ${token}`)
        .send(issue);
      expect(res.statusCode).toBe(201);
      expect(lastQuery.params[8]).toBe('active');
    });

    it('accepts camelCase aliases for dates', async () => {
      const issue = { pet_id: 'pet-1', name: 'Test', startDate: '2025-01-01', endDate: '2025-02-01' };
      const res = await request(app)
        .post('/api/health-issues')
        .set('Authorization', `Bearer ${token}`)
        .send(issue);
      expect(res.statusCode).toBe(201);
      expect(lastQuery.params[6]).toBe('2025-01-01');
      expect(lastQuery.params[7]).toBe('2025-02-01');
    });

    it('returns 403 when the pet belongs to another user', async () => {
      const res = await request(app)
        .post('/api/health-issues')
        .set('Authorization', `Bearer ${token}`)
        .send({ pet_id: 'pet-notmine', name: 'Sneaky' });
      expect(res.statusCode).toBe(403);
    });
  });

  describe('PUT /api/health-issues/:id (update)', () => {
    it('updates a health issue', async () => {
      const issue = {
        name: 'Updated Issue',
        issue_type: 'chronic',
        notes: 'Updated notes',
        start_date: '2025-01-01',
        end_date: '2025-12-31',
        status: 'resolved',
      };
      const res = await request(app)
        .put('/api/health-issues/hi-1')
        .set('Authorization', `Bearer ${token}`)
        .send(issue);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('name');
    });

    it('returns 404 for nonexistent issue', async () => {
      const res = await request(app)
        .put('/api/health-issues/nonexistent')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Nope' });
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error', 'Not found');
    });

    it('checks pet access before update', async () => {
      await request(app)
        .put('/api/health-issues/hi-1')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Test' });
      expect(lastQuery.sql).toContain('UPDATE health_issues SET');
      expect(lastQuery.params[6]).toBe('hi-1');
    });
  });

  describe('DELETE /api/health-issues/:id', () => {
    it('deletes a health issue', async () => {
      const res = await request(app)
        .delete('/api/health-issues/hi-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('deleted', true);
    });

    it('scopes delete by issue id', async () => {
      await request(app)
        .delete('/api/health-issues/hi-1')
        .set('Authorization', `Bearer ${token}`);
      expect(lastQuery.sql).toContain('DELETE FROM health_issues WHERE id = $1');
      expect(lastQuery.params[0]).toBe('hi-1');
    });

    it('removes document files from disk when deleting an issue', async () => {
      const docPath = path.join(uploadDir, 'doc-1.pdf');
      fs.writeFileSync(docPath, 'pdf-content');
      const res = await request(app)
        .delete('/api/health-issues/hi-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(fs.existsSync(docPath)).toBe(false);
    });
  });

  describe('GET /api/health-issues/:id/documents', () => {
    it('returns 401 without token', async () => {
      const res = await request(app).get('/api/health-issues/hi-1/documents');
      expect(res.statusCode).toBe(401);
    });

    it('returns documents array', async () => {
      const res = await request(app)
        .get('/api/health-issues/hi-1/documents')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body[0]).toHaveProperty('id');
      expect(res.body[0]).toHaveProperty('health_issue_id');
      expect(res.body[0]).toHaveProperty('url');
      expect(res.body[0]).toHaveProperty('created_at');
    });

    it('returns 404 when the issue belongs to another user (IDOR)', async () => {
      const res = await request(app)
        .get('/api/health-issues/hi-notmine/documents')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
    });
  });

  describe('POST /api/health-issues/:id/documents', () => {
    it('returns 401 without token', async () => {
      const res = await request(app)
        .post('/api/health-issues/hi-1/documents')
        .send({ url: '/uploads/test.jpg' });
      expect(res.statusCode).toBe(401);
    });

    it('creates a document record', async () => {
      const res = await request(app)
        .post('/api/health-issues/hi-1/documents')
        .set('Authorization', `Bearer ${token}`)
        .send({ url: '/uploads/test.jpg' });
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('id');
      expect(res.body).toHaveProperty('health_issue_id');
      expect(res.body).toHaveProperty('url');
    });

    it.each([
      ['JPG', 'document.jpg', 'image/jpeg'],
      ['PNG', 'document.png', 'image/png'],
      ['PDF', 'document.pdf', 'application/pdf'],
    ])('accepts %s document uploads up to 2 MB', async (_label, filename, contentType) => {
      const res = await request(app)
        .post('/api/health-issues/hi-1/documents')
        .set('Authorization', `Bearer ${token}`)
        .attach('photo', Buffer.from('document'), { filename, contentType });
      expect(res.statusCode).toBe(201);
      expect(res.body.url).toMatch(
        new RegExp(`/uploads/health_documents/.+\\.${filename.split('.').pop()}$`)
      );
    });

    it('rejects unsupported file types', async () => {
      const res = await request(app)
        .post('/api/health-issues/hi-1/documents')
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
        .post('/api/health-issues/hi-1/documents')
        .set('Authorization', `Bearer ${token}`)
        .attach('photo', Buffer.alloc(2 * 1024 * 1024 + 1), {
          filename: 'document.pdf',
          contentType: 'application/pdf',
        });
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toBe('Document must be 2 MB or smaller');
    });

    it('rejects more than 4 documents per issue', async () => {
      documentCount = 4;
      const res = await request(app)
        .post('/api/health-issues/hi-1/documents')
        .set('Authorization', `Bearer ${token}`)
        .send({ url: '/uploads/test.jpg' });
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toBe('Maximum 4 documents per health issue');
    });

    it('returns 404 when the issue belongs to another user (IDOR)', async () => {
      const res = await request(app)
        .post('/api/health-issues/hi-notmine/documents')
        .set('Authorization', `Bearer ${token}`)
        .send({ url: '/uploads/test.jpg' });
      expect(res.statusCode).toBe(404);
    });
  });

  describe('DELETE /api/health-issues/:issueId/documents/:documentId', () => {
    it('returns 401 without token', async () => {
      const res = await request(app)
        .delete('/api/health-issues/hi-1/documents/doc-1');
      expect(res.statusCode).toBe(401);
    });

    it('deletes a document and returns success', async () => {
      const res = await request(app)
        .delete('/api/health-issues/hi-1/documents/doc-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('deleted', true);
    });

    it('removes the document file from disk', async () => {
      const docPath = path.join(uploadDir, 'doc-1.pdf');
      fs.writeFileSync(docPath, 'pdf-content');
      const res = await request(app)
        .delete('/api/health-issues/hi-1/documents/doc-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(fs.existsSync(docPath)).toBe(false);
    });

    it('returns 404 when the issue belongs to another user (IDOR)', async () => {
      const res = await request(app)
        .delete('/api/health-issues/hi-notmine/documents/doc-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
    });
  });

  describe('GET /api/health-issues/:issueId/events', () => {
    it('returns 401 without token', async () => {
      const res = await request(app).get('/api/health-issues/hi-1/events');
      expect(res.statusCode).toBe(401);
    });

    it('returns events array', async () => {
      const res = await request(app)
        .get('/api/health-issues/hi-1/events')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body[0]).toHaveProperty('id');
      expect(res.body[0]).toHaveProperty('health_issue_id');
    });

    it('returns 404 when the issue belongs to another user (IDOR)', async () => {
      const res = await request(app)
        .get('/api/health-issues/hi-notmine/events')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
    });
  });

  describe('DELETE /api/health-issues/:issueId/events/:entryId', () => {
    it('returns 401 without token', async () => {
      const res = await request(app).delete('/api/health-issues/hi-1/events/evt-1');
      expect(res.statusCode).toBe(401);
    });

    it('deletes an event and returns success', async () => {
      const res = await request(app)
        .delete('/api/health-issues/hi-1/events/evt-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Event deleted');
    });

    it('passes correct params to query', async () => {
      await request(app)
        .delete('/api/health-issues/hi-1/events/evt-1')
        .set('Authorization', `Bearer ${token}`);
      expect(lastQuery.params[0]).toBe('evt-1');
      expect(lastQuery.params[1]).toBe('hi-1');
    });

    it('returns 404 when the issue belongs to another user (IDOR)', async () => {
      const res = await request(app)
        .delete('/api/health-issues/hi-notmine/events/evt-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
    });
  });
});
