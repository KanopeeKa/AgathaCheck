import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { findTopLevelSqlTransactionViolations } from '../server/scripts/lib/migration_sql.js';

describe('check_migration_sql_transactions rules', () => {
  it('matches real DO-block migration shape', () => {
    const sample = `-- example
DO $$
BEGIN
  UPDATE health_occurrences SET updated_at = NOW() WHERE false;
END
$$;
`;
    assert.deepEqual(findTopLevelSqlTransactionViolations(sample), []);
  });

  it('flags standalone BEGIN; at file scope', () => {
    assert.equal(
      findTopLevelSqlTransactionViolations('BEGIN;\nALTER TABLE t ADD COLUMN x int;\n').length,
      1,
    );
  });
});
