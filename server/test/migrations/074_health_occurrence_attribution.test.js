import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(
  __dirname,
  '../../../db/migrations/074_health_occurrence_attribution.sql',
);
const downPath = path.resolve(
  __dirname,
  '../../../db/migrations/074_health_occurrence_attribution_down.sql',
);

describe('074_health_occurrence_attribution migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('adds provider and attribution columns with SET NULL user FKs', () => {
    expect(sql).toMatch(/provider_contact_id UUID/);
    expect(sql).toMatch(/performed_by_user_id UUID/);
    expect(sql).toMatch(/performed_by_snapshot JSONB/);
    expect(sql).toMatch(/marked_by_snapshot JSONB/);
    expect(sql).toMatch(/REFERENCES users\(id\) ON DELETE SET NULL/);
    expect(sql).not.toMatch(/gen_random_uuid/);
  });

  it('down migration drops attribution columns', () => {
    expect(downSql).toMatch(/DROP COLUMN IF EXISTS provider_contact_id/);
    expect(downSql).toMatch(/DROP COLUMN IF EXISTS performed_by_user_id/);
  });
});
