import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(__dirname, '../../../db/migrations/076_households.sql');
const downPath = path.resolve(__dirname, '../../../db/migrations/076_households_down.sql');

describe('076_households migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('creates household tables and extends people_directories', () => {
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS households/);
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS household_members/);
    expect(sql).toMatch(/access_tier IN \('full_access', 'can_log_care'\)/);
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS household_pets/);
    expect(sql).toMatch(/PRIMARY KEY \(pet_id\)/);
    expect(sql).toMatch(/household_id UUID/);
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS pet_access_events/);
  });

  it('down migration drops household artifacts', () => {
    expect(downSql).toMatch(/DROP TABLE IF EXISTS pet_access_events/);
    expect(downSql).toMatch(/DROP TABLE IF EXISTS households/);
  });
});
