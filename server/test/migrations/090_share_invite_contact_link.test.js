import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(
  __dirname,
  '../../../db/migrations/090_share_invite_contact_link.sql',
);
const downPath = path.resolve(
  __dirname,
  '../../../db/migrations/090_share_invite_contact_link_down.sql',
);

describe('090_share_invite_contact_link migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('adds nullable contact_id on pet_share_invites', () => {
    expect(sql).toMatch(/ALTER TABLE pet_share_invites/);
    expect(sql).toMatch(/contact_id UUID.*REFERENCES people_contacts\(id\) ON DELETE SET NULL/);
    expect(sql).toMatch(/idx_pet_share_invites_contact_id/);
    expect(sql).not.toMatch(/gen_random_uuid/);
  });

  it('down migration drops column and index', () => {
    expect(downSql).toMatch(/DROP INDEX IF EXISTS idx_pet_share_invites_contact_id/);
    expect(downSql).toMatch(/DROP COLUMN IF EXISTS contact_id/);
  });
});
