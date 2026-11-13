import request from 'supertest';
import jwt from 'jsonwebtoken';

import { createApp } from '../../bin/server.js';
import { createTransactionalMockPool } from '../helpers/transactionMockPool.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const staffUserId = 'staff-user-1';
const regularUserId = 'regular-user-2';
const staffToken = jwt.sign(
  { id: staffUserId, email: 'staff@example.com', typ: 'access' },
  JWT_SECRET,
  { expiresIn: '1h' },
);
const regularToken = jwt.sign(
  { id: regularUserId, email: 'user@example.com', typ: 'access' },
  JWT_SECRET,
  { expiresIn: '1h' },
);

const ticketId = '11111111-1111-4111-8111-111111111111';

function createStaffMockPool() {
  return createTransactionalMockPool(async (sql, params) => {
    const text = String(sql);

    if (text.includes('SELECT 1 FROM users WHERE id = $1')) {
      return { rows: [{ '?column?': 1 }] };
    }
    if (text.includes('SELECT is_support_staff FROM users WHERE id = $1')) {
      const id = params?.[0];
      if (id === staffUserId) {
        return { rows: [{ is_support_staff: true }] };
      }
      if (id === regularUserId) {
        return { rows: [{ is_support_staff: false }] };
      }
      return { rows: [] };
    }
    if (text.includes('FROM support_tickets') && text.includes('ORDER BY created_at DESC')) {
      return {
        rows: [
          {
            id: ticketId,
            reference: 'AT-12345678',
            category: 'bug',
            title: 'Test ticket',
            signed_in: true,
            reporter_email: 'user@example.com',
            created_at: new Date('2026-01-01T00:00:00.000Z'),
            github_issue_number: null,
          },
        ],
      };
    }
    if (text.includes('FROM support_outbox') && text.includes('ticket_id = ANY')) {
      return {
        rows: [{ ticket_id: ticketId, kind: 'github_issue', status: 'failed' }],
      };
    }
    if (text.includes('FROM support_tickets') && text.includes('WHERE id = $1')) {
      return {
        rows: [
          {
            id: ticketId,
            reference: 'AT-12345678',
            user_id: regularUserId,
            reporter_email: 'user@example.com',
            reporter_email_normalised: 'user@example.com',
            signed_in: true,
            submit_ip: null,
            category: 'bug',
            title: 'Test ticket',
            description: 'Details',
            expected: null,
            actual: null,
            steps: null,
            frequency: null,
            context: {},
            locale: 'en',
            created_at: new Date('2026-01-01T00:00:00.000Z'),
            github_issue_number: null,
          },
        ],
      };
    }
    if (text.includes('FROM support_attachments')) {
      return { rows: [] };
    }
    if (text.includes('FROM support_outbox') && text.includes('WHERE ticket_id = $1')) {
      return {
        rows: [
          {
            id: '22222222-2222-4222-8222-222222222222',
            kind: 'receipt',
            status: 'pending',
            attempts: 0,
            github_issue_number: null,
            last_error: null,
            created_at: new Date('2026-01-01T00:00:00.000Z'),
            updated_at: new Date('2026-01-01T00:00:00.000Z'),
          },
        ],
      };
    }
    if (text === 'BEGIN' || text === 'COMMIT' || text === 'ROLLBACK') {
      return { rows: [], command: text };
    }
    return { rows: [] };
  });
}

describe('GET /api/support/staff/tickets', () => {
  let app;

  beforeAll(() => {
    app = createApp(createStaffMockPool());
  });

  it('returns 401 without a bearer token', async () => {
    const res = await request(app).get('/api/support/staff/tickets');
    expect(res.statusCode).toBe(401);
  });

  it('returns 403 for a signed-in user who is not staff', async () => {
    const res = await request(app)
      .get('/api/support/staff/tickets')
      .set('Authorization', `Bearer ${regularToken}`);
    expect(res.statusCode).toBe(403);
    expect(res.body.error).toMatch(/forbidden/i);
  });

  it('lists tickets for staff with outbox alerts', async () => {
    const res = await request(app)
      .get('/api/support/staff/tickets')
      .set('Authorization', `Bearer ${staffToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.tickets).toHaveLength(1);
    expect(res.body.tickets[0].reference).toBe('AT-12345678');
    expect(res.body.tickets[0].outbox_alerts).toEqual([
      { kind: 'github_issue', status: 'failed' },
    ]);
  });

  it('returns ticket detail for staff', async () => {
    const res = await request(app)
      .get(`/api/support/staff/tickets/${ticketId}`)
      .set('Authorization', `Bearer ${staffToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.ticket.reference).toBe('AT-12345678');
    expect(res.body.outbox).toHaveLength(1);
  });
});
