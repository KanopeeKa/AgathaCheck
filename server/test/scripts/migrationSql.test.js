import {
  assertClientInTransaction,
  stripTopLevelTransactionWrappers,
} from '../../scripts/lib/migration_sql.js';

describe('stripTopLevelTransactionWrappers', () => {
  it('removes standalone BEGIN and COMMIT lines', () => {
    const raw = `-- header\n\nBEGIN;\nALTER TABLE t ADD COLUMN x int;\nCOMMIT;\n`;
    expect(stripTopLevelTransactionWrappers(raw)).toBe(
      '-- header\n\nALTER TABLE t ADD COLUMN x int;',
    );
  });
});

describe('assertClientInTransaction', () => {
  it('passes inside BEGIN', async () => {
    const client = {
      query: async (sql) => {
        if (sql.includes('txid_current_if_assigned')) return { rows: [{ tx: '123' }] };
        return { rows: [] };
      },
    };
    await assertClientInTransaction(client);
  });

  it('throws after nested COMMIT', async () => {
    const client = {
      query: async (sql) => {
        if (sql.includes('txid_current_if_assigned')) return { rows: [{ tx: null }] };
        return { rows: [] };
      },
    };
    await expect(assertClientInTransaction(client)).rejects.toThrow(/runner transaction/);
  });
});
