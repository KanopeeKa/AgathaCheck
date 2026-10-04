import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(
  __dirname,
  '../../../db/migrations/090_household_invites.sql',
);
const downPath = path.resolve(
  __dirname,
  '../../../db/migrations/090_household_invites_down.sql',
);

describe('090_household_invites migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('creates household_invites with status check and indexes', () => {
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS household_invites/);
    expect(sql).toMatch(/household_id.*REFERENCES households\(id\) ON DELETE CASCADE/);
    expect(sql).toMatch(/contact_id.*REFERENCES people_contacts\(id\) ON DELETE SET NULL/);
    expect(sql).toMatch(/code.*UNIQUE/);
    expect(sql).toMatch(/pending.*accepted.*declined.*revoked.*expired/);
    expect(sql).toMatch(/idx_household_invites_invitee_email/);
    expect(sql).not.toMatch(/gen_random_uuid/);
  });

  it('down migration drops the table', () => {
    expect(downSql).toMatch(/DROP TABLE IF EXISTS household_invites/);
  });
});
