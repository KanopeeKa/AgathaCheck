import { runAuditRetention } from '../lib/auditRetention.js';

describe('audit retention', () => {
  it('runs hot, warm, and cold transitions', async () => {
    const queries = [];
    const pool = {
      query: async (sql, params) => {
        queries.push({ sql, params });
        return { rowCount: queries.length, rows: [] };
      },
    };

    const counts = await runAuditRetention(pool);

    expect(queries).toHaveLength(3);
    expect(queries[0].sql).toContain("retention_tier = 'warm'");
    expect(queries[1].sql).toContain("retention_tier = 'cold'");
    expect(queries[2].sql).toContain('DELETE FROM audit_events');
    expect(counts).toEqual({ hotToWarm: 1, warmToCold: 2, coldPurge: 3 });
  });
});
