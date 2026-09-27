import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(__dirname, '../../../db/migrations/077_absence_guest_timezone.sql');
const downPath = path.resolve(__dirname, '../../../db/migrations/077_absence_guest_timezone_down.sql');

describe('077_absence_guest_timezone migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('adds timezone columns and guest access tables', () => {
    expect(sql).toMatch(/ALTER TABLE users[\s\S]*timezone/);
    expect(sql).toMatch(/ALTER TABLE planned_absences[\s\S]*timezone/);
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS planned_absence_carer_invites/);
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS planned_absence_guest_grants/);
  });

  it('down migration drops guest artifacts', () => {
    expect(downSql).toMatch(/DROP TABLE IF EXISTS planned_absence_guest_grants/);
    expect(downSql).toMatch(/DROP COLUMN IF EXISTS timezone/);
  });
});
