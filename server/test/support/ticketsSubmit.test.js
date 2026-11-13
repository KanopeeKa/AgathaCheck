import request from 'supertest';
import jwt from 'jsonwebtoken';

import { createApp } from '../../bin/server.js';
import { assertMatchesSchema } from '../../lib/openapi/assertDto.js';
import { loadSupportTicketsSpec, supportTicketsResponseSchema } from '../../lib/openapi/supportTicketsSpec.js';
import { createTransactionalMockPool } from '../helpers/transactionMockPool.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'support-user-1';
const token = jwt.sign({ id: userId, email: 'account@example.com', typ: 'access' }, JWT_SECRET, {
  expiresIn: '1h',
});

const spec = loadSupportTicketsSpec();

function validPayload(overrides = {}) {
  return {
    category: 'suggestion',
    title: 'Faster pet list',
    description: 'Please add filters.',
    locale: 'en',
    email: 'visitor@example.com',
    context: {
      version: '1.0.0',
      platform: 'web',
    },
    ...overrides,
  };
}

function assertResponse(status, body) {
  const schema = supportTicketsResponseSchema(spec, '/tickets', 'post', status);
  assertMatchesSchema(spec, schema, body);
}

function createSupportMockPool() {
  let ticketCount = 0;
  return createTransactionalMockPool(async (sql, params) => {
    const text = String(sql);

    if (text.includes('SELECT 1 FROM users WHERE id = $1')) {
      return { rows: [{ '?column?': 1 }] };
    }
    if (text.includes('SELECT email FROM users WHERE id = $1')) {
      return { rows: [{ email: 'account@example.com' }] };
    }
    if (text.includes('COUNT(*)::int AS c') && text.includes('support_tickets')) {
      return { rows: [{ c: ticketCount, oldest: new Date() }] };
    }
    if (text.startsWith('INSERT INTO support_tickets')) {
      ticketCount += 1;
      return { rowCount: 1 };
    }
    if (text.startsWith('INSERT INTO support_outbox')) {
      return { rowCount: 2 };
    }
    if (text === 'BEGIN' || text === 'COMMIT' || text === 'ROLLBACK') {
      return { rows: [], command: text };
    }
    return { rows: [] };
  });
}

describe('POST /api/support/tickets', () => {
  let app;

  beforeAll(() => {
    app = createApp(createSupportMockPool());
  });

  it('returns 401 for an invalid bearer token', async () => {
    const res = await request(app)
      .post('/api/support/tickets')
      .set('Authorization', 'Bearer not-a-valid-jwt')
      .send(validPayload());
    expect(res.statusCode).toBe(401);
    expect(res.body.error).toMatch(/invalid|expired/i);
    assertResponse(401, res.body);
  });

  it('uses the signed-in account email and ignores body email', async () => {
    const res = await request(app)
      .post('/api/support/tickets')
      .set('Authorization', `Bearer ${token}`)
      .send(validPayload({ email: 'other@example.com' }));
    expect(res.statusCode).toBe(201);
    expect(res.body.reference).toMatch(/^AT-[0-9A-HJKMNP-TV-Z]{8}$/);
    assertResponse(201, res.body);
  });

  it('accepts signed-out JSON submit and returns a reference', async () => {
    const res = await request(app)
      .post('/api/support/tickets')
      .send(validPayload());
    expect(res.statusCode).toBe(201);
    expect(res.body.reference).toMatch(/^AT-/);
    assertResponse(201, res.body);
  });
});
