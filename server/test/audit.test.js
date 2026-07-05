import { logAuditEvent, auditContextFromReq } from '../lib/audit.js';

describe('audit helper', () => {
  it('auditContextFromReq extracts request metadata', () => {
    const req = {
      requestId: 'req-123',
      ip: '127.0.0.1',
      headers: { 'user-agent': 'jest' },
    };
    expect(auditContextFromReq(req)).toEqual({
      requestId: 'req-123',
      ipAddress: '127.0.0.1',
      userAgent: 'jest',
    });
  });

  it('logAuditEvent inserts a row with metadata', async () => {
    const inserts = [];
    const pool = {
      query: async (sql, params) => {
        inserts.push({ sql, params });
        return { rows: [{ id: 'audit-1' }] };
      },
    };

    const id = await logAuditEvent(pool, {
      actorUserId: 'user-1',
      action: 'auth.login',
      resourceType: 'user',
      resourceId: 'user-1',
      metadata: { source: 'test' },
      req: {
        requestId: 'req-abc',
        ip: '10.0.0.1',
        headers: { 'user-agent': 'jest-agent' },
      },
    });

    expect(id).toBe('audit-1');
    expect(inserts).toHaveLength(1);
    expect(inserts[0].sql).toContain('INSERT INTO audit_events');
    expect(inserts[0].params).toContain('auth.login');
    expect(inserts[0].params).toContain('user');
    expect(inserts[0].params).toContain('user-1');
    expect(inserts[0].params).toContain('req-abc');
  });

  it('logAuditEvent returns null when required fields are missing', async () => {
    const pool = { query: async () => ({ rows: [{ id: 'x' }] }) };
    const id = await logAuditEvent(pool, { action: '', resourceType: 'user' });
    expect(id).toBeNull();
  });
});
