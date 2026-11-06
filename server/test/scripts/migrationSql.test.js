import {
  assertRunnerTransactionUnchanged,
  captureRunnerTransactionId,
  findTopLevelSqlTransactionViolations,
  stripTopLevelSqlTransactionWrappers,
} from '../../scripts/lib/migration_sql.js';

describe('stripTopLevelSqlTransactionWrappers', () => {
  it('removes semicolon BEGIN/COMMIT outside dollar quotes', () => {
    const raw = `-- header\n\nBEGIN;\nALTER TABLE t ADD COLUMN x int;\nCOMMIT;\n`;
    expect(stripTopLevelSqlTransactionWrappers(raw)).toBe(
      '-- header\n\nALTER TABLE t ADD COLUMN x int;',
    );
  });

  it('preserves PL/pgSQL BEGIN inside DO $$', () => {
    const raw = 'DO $$\nBEGIN\n  PERFORM 1;\nEND\n$$;\n';
    expect(stripTopLevelSqlTransactionWrappers(raw)).toBe(raw.trim());
  });
});

describe('findTopLevelSqlTransactionViolations', () => {
  it('flags semicolon BEGIN/COMMIT outside dollar quotes', () => {
    const raw = `-- header\n\nBEGIN;\nALTER TABLE t ADD COLUMN x int;\nCOMMIT;\n`;
    const v = findTopLevelSqlTransactionViolations(raw);
    expect(v.map((x) => x.kind)).toEqual(['BEGIN', 'COMMIT']);
  });

  it('allows PL/pgSQL BEGIN inside DO $$', () => {
    const raw = 'DO $$\nBEGIN\n  PERFORM 1;\nEND\n$$;\n';
    expect(findTopLevelSqlTransactionViolations(raw)).toEqual([]);
  });
});

describe('assertRunnerTransactionUnchanged', () => {
  it('passes when txid is unchanged', async () => {
    const client = {
      query: async (sql) => {
        if (sql.includes('txid_current()')) return { rows: [{ tx: '99' }] };
        return { rows: [] };
      },
    };
    const txBefore = await captureRunnerTransactionId(client);
    await assertRunnerTransactionUnchanged(client, txBefore);
  });

  it('throws when txid changes after COMMIT', async () => {
    let pass = 0;
    const client = {
      query: async (sql) => {
        if (sql.includes('txid_current()')) {
          pass += 1;
          return { rows: [{ tx: pass === 1 ? '10' : '11' }] };
        }
        return { rows: [] };
      },
    };
    const txBefore = await captureRunnerTransactionId(client);
    await expect(assertRunnerTransactionUnchanged(client, txBefore)).rejects.toThrow(
      /runner transaction/,
    );
  });
});
