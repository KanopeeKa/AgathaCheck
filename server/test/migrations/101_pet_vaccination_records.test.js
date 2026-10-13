import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(
  __dirname,
  '../../../db/migrations/101_pet_vaccination_records.sql',
);
const downPath = path.resolve(
  __dirname,
  '../../../db/migrations/101_pet_vaccination_records_down.sql',
);

describe('101_pet_vaccination_records migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('creates pet_vaccination_records without pets summary column', () => {
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS pet_vaccination_records/);
    expect(sql).toMatch(/vaccine_name/);
    expect(sql).toMatch(/administered_on/);
    expect(sql).not.toMatch(/vaccination_status_summary/);
  });

  it('down migration drops table', () => {
    expect(downSql).toMatch(/DROP TABLE IF EXISTS pet_vaccination_records/);
  });
});
