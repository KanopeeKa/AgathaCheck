/**
 * Mock pg.Pool with connect() for withTransaction-aware unit tests.
 *
 * @param {(sql: string, params?: unknown[]) => Promise<{ rows: unknown[], rowCount?: number }>} [queryHandler]
 */
export function createTransactionalMockPool(queryHandler) {
  let txDepth = 0;
  const baseQuery = queryHandler || (async () => ({ rows: [] }));

  const client = {
    query: async (sql, params) => {
      const cmd = String(sql).trim();
      if (cmd === 'BEGIN' || cmd === 'COMMIT' || cmd === 'ROLLBACK') {
        if (cmd === 'BEGIN') txDepth += 1;
        if (cmd === 'COMMIT' || cmd === 'ROLLBACK') txDepth = Math.max(0, txDepth - 1);
        return { rows: [], command: cmd };
      }
      return baseQuery(sql, params);
    },
    release: async () => {},
  };

  const pool = {
    query: (sql, params) => client.query(sql, params),
    connect: async () => client,
    end: async () => {},
    getTxDepth: () => txDepth,
  };
  return pool;
}
