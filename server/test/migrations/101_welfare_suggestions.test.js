import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(__dirname, '../../../db/migrations/101_welfare_suggestions.sql');
const downPath = path.resolve(__dirname, '../../../db/migrations/101_welfare_suggestions_down.sql');

describe('101_welfare_suggestions migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('creates welfare_suggestions with dedupe unique index', () => {
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS welfare_suggestions/);
    expect(sql).toMatch(/subject_key/);
    expect(sql).toMatch(/dedupe_key/);
    expect(sql).toMatch(/primary_outcome/);
    expect(sql).toMatch(/welfare_suggestions_pet_dedupe_idx/);
  });

  it('down migration drops table', () => {
    expect(downSql).toMatch(/DROP TABLE IF EXISTS welfare_suggestions/);
  });
});
