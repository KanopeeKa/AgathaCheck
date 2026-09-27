import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(
  __dirname,
  '../../../db/migrations/081_health_entry_absence_resolutions.sql',
);

describe('081_health_entry_absence_resolutions migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');

  it('creates health_entry_absence_resolutions with decision and carer fields', () => {
    expect(sql).toMatch(/health_entry_absence_resolutions/);
    expect(sql).toMatch(/UNIQUE \(health_entry_id, planned_absence_id\)/);
    expect(sql).toMatch(/keep_date/);
    expect(sql).toMatch(/dates_decided_for JSONB/);
    expect(sql).not.toMatch(/gen_random_uuid/);
  });
});
