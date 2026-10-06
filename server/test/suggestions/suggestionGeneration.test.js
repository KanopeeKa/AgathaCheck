import { runSuggestionGeneration } from '../../lib/suggestions/suggestionGeneration.js';

function mockPool(handlers = {}) {
  return {
    query: jest.fn(async (sql, params) => {
      for (const [pattern, fn] of Object.entries(handlers)) {
        if (sql.includes(pattern)) return fn(sql, params);
      }
      return { rows: [] };
    }),
  };
}

describe('runSuggestionGeneration', () => {
  it('expires stale suggestions and returns stats for empty pet list', async () => {
    const pool = mockPool({
      'suggestion_expires_at': () => ({ rows: [] }),
      'FROM pets p': () => ({ rows: [] }),
    });
    const stats = await runSuggestionGeneration(pool, { limit: 0 });
    expect(stats.pets).toBe(0);
    expect(stats.upserted).toBe(0);
  });
});
