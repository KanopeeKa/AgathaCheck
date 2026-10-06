import { upsertWave1Suggestion } from '../../lib/suggestions/suggestionUpsert.js';

describe('upsertWave1Suggestion', () => {
  it('inserts a new suggestion row when none exists', async () => {
    const queries = [];
    const pool = {
      query: jest.fn(async (sql, params) => {
        queries.push(sql);
        if (sql.includes('SELECT id FROM notifications')) {
          return { rows: [] };
        }
        if (sql.includes('INSERT INTO notifications')) {
          return { rows: [{ id: 'n1', user_id: params[1] }] };
        }
        return { rows: [] };
      }),
    };

    const { created, row } = await upsertWave1Suggestion(pool, {
      userId: 'u1',
      petId: 'p1',
      petName: 'Luna',
      wireType: 'suggestionWeightTrend',
      dedupeKey: 'weight_trend:p1:90d',
      title: 't',
      message: 'm',
      confidence: 0.9,
      payload: { health_adjacent: true },
    });

    expect(created).toBe(true);
    expect(row.id).toBe('n1');
    expect(queries.some((q) => q.includes('INSERT INTO notifications'))).toBe(true);
  });
});
