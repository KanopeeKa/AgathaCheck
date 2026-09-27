import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(
  __dirname,
  '../../../db/migrations/072_people_contacts_foundation.sql',
);
const downPath = path.resolve(
  __dirname,
  '../../../db/migrations/072_people_contacts_foundation_down.sql',
);

describe('072_people_contacts_foundation migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('creates directory, contact, role, note, and pet relationship tables', () => {
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS people_directories/);
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS people_contacts/);
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS people_contact_roles/);
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS people_contact_private_notes/);
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS pet_contact_relationships/);
    expect(sql).toMatch(/linked_user_id\s+UUID REFERENCES users\(id\) ON DELETE SET NULL/);
    expect(sql).toMatch(/relationship_kind IN/);
    expect(sql).toMatch(/primary_vet/);
  });

  it('down migration drops tables in dependency order', () => {
    expect(downSql).toMatch(/DROP TABLE IF EXISTS pet_contact_relationships/);
    expect(downSql).toMatch(/DROP TABLE IF EXISTS people_directories/);
  });
});
