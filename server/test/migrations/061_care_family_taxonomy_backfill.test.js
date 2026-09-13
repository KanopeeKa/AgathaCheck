import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(
  __dirname,
  '../../../db/migrations/061_care_family_taxonomy_backfill.sql',
);

describe('061_care_family_taxonomy_backfill migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');

  it('clears type-only other and wellness_review guesses before name rules', () => {
    expect(sql).toMatch(/SET care_family = NULL/);
    expect(sql).toMatch(/care_family = 'other'/);
    expect(sql).toMatch(/care_family = 'wellness_review'/);
  });

  it('applies unambiguous medication and name-based mappings', () => {
    expect(sql).toMatch(/type = 'medication'/);
    expect(sql).toMatch(/parasite_prevention/);
    expect(sql).toMatch(/vaccination/);
    expect(sql).toMatch(/weight_monitoring/);
  });

  it('is idempotent by only updating NULL care_family rows in name rules', () => {
    const nameRuleBlocks = sql.split('WHERE care_family IS NULL');
    expect(nameRuleBlocks.length).toBeGreaterThan(5);
  });
});
