import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(__dirname, '../../../db/migrations/087_account_erasure_operations.sql');
const downPath = path.resolve(__dirname, '../../../db/migrations/087_account_erasure_operations_down.sql');

describe('087_account_erasure_operations migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('creates account_erasure_operations without gen_random_uuid defaults', () => {
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS account_erasure_operations/);
    expect(sql).not.toMatch(/gen_random_uuid/);
    expect(sql).toMatch(/status IN \('accepted', 'in_progress', 'completed', 'failed'\)/);
    expect(sql).toMatch(/idx_account_erasure_operations_user_id/);
    expect(sql).not.toMatch(/REFERENCES/);
  });

  it('down migration drops only account_erasure_operations', () => {
    expect(downSql.trim()).toBe('DROP TABLE IF EXISTS account_erasure_operations;');
  });
});
