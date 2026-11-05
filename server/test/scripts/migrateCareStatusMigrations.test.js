import { describe, expect, it } from '@jest/globals';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const migratePath = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '../../scripts/migrate.js',
);

describe('migrate.js care status migrations', () => {
  it('registers 104/105 SQL hooks for production migrate up', () => {
    const source = fs.readFileSync(migratePath, 'utf8');
    expect(source).toMatch(/'104_care_date_outcome\.sql': migrateCareDateOutcome/);
    expect(source).toMatch(/'105_care_item_closed\.sql': migrateCareItemClosed/);
    const repoRoot = path.resolve(path.dirname(migratePath), '../..');
    expect(fs.existsSync(path.join(repoRoot, 'db/migrations/104_care_date_outcome.sql'))).toBe(true);
    expect(fs.existsSync(path.join(repoRoot, 'db/migrations/105_care_item_closed.sql'))).toBe(true);
  });
});
