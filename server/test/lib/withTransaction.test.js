import { withTransaction } from '../../lib/db/withTransaction.js';

describe('withTransaction', () => {
  it('runs fn with a single checked-out client and commits on success', async () => {
    const queryLog = [];
    const client = {
      query: async (sql) => {
        queryLog.push(String(sql).trim());
        return { rows: [] };
      },
      release: jest.fn(),
    };
    const pool = {
      connect: jest.fn(async () => client),
    };

    const result = await withTransaction(pool, async (db) => {
      await db.query('SELECT 1');
      return { ok: true };
    });

    expect(result).toEqual({ ok: true });
    expect(pool.connect).toHaveBeenCalledTimes(1);
    expect(queryLog).toEqual(['BEGIN', 'SELECT 1', 'COMMIT']);
    expect(client.release).toHaveBeenCalledTimes(1);
  });

  it('rolls back and rethrows the original error on failure', async () => {
    const queryLog = [];
    const client = {
      query: async (sql) => {
        queryLog.push(String(sql).trim());
        return { rows: [] };
      },
      release: jest.fn(),
    };
    const pool = { connect: jest.fn(async () => client) };
    const workError = new Error('work failed');

    await expect(
      withTransaction(pool, async () => {
        throw workError;
      }),
    ).rejects.toThrow('work failed');

    expect(queryLog).toEqual(['BEGIN', 'ROLLBACK']);
    expect(client.release).toHaveBeenCalledTimes(1);
  });

  it('preserves the original error when rollback also fails', async () => {
    const client = {
      query: async (sql) => {
        if (String(sql).trim() === 'ROLLBACK') {
          throw new Error('rollback failed');
        }
        return { rows: [] };
      },
      release: jest.fn(),
    };
    const pool = { connect: jest.fn(async () => client) };
    const workError = new Error('work failed');

    await expect(
      withTransaction(pool, async () => {
        throw workError;
      }),
    ).rejects.toThrow('work failed');
  });

  it('rejects pools without connect()', async () => {
    await expect(
      withTransaction({ query: async () => ({ rows: [] }) }, async () => {}),
    ).rejects.toThrow('withTransaction requires a pg.Pool with connect()');
  });
});
