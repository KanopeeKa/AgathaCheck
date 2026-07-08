import {
  canonicalOrgPair,
  createConnectionRequest,
  disconnectOrgs,
} from '../lib/orgConnections.js';

describe('orgConnections', () => {
  it('canonicalOrgPair orders ids consistently', () => {
    expect(canonicalOrgPair('b-org', 'a-org')).toEqual(['a-org', 'b-org']);
    expect(canonicalOrgPair('a-org', 'b-org')).toEqual(['a-org', 'b-org']);
  });

  it('createConnectionRequest inserts pending request', async () => {
    const queries = [];
    const pool = {
      query: async (sql, params) => {
        queries.push({ sql, params });
        if (sql.includes('org_connections')) return { rows: [] };
        if (sql.includes('INSERT INTO org_connection_requests')) return { rows: [] };
        return { rows: [] };
      },
    };
    const result = await createConnectionRequest(pool, {
      requestingOrgId: 'org-a',
      targetOrgId: 'org-b',
      createdBy: 'user-1',
    });
    expect(result.token).toBeTruthy();
    expect(queries.some((q) => q.sql.includes('INSERT INTO org_connection_requests'))).toBe(true);
  });

  it('disconnectOrgs cancels pending transfers between orgs', async () => {
    const queries = [];
    const pool = {
      query: async (sql) => {
        queries.push(sql);
        return { rows: [] };
      },
    };
    await disconnectOrgs(pool, 'org-a', 'org-b', 'org-a');
    expect(queries.some((sql) => sql.includes('UPDATE custody_transfers'))).toBe(true);
    expect(queries.some((sql) => sql.includes('UPDATE org_connections'))).toBe(true);
  });
});
