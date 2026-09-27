import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(
  __dirname,
  '../../../db/migrations/079_care_provider_used.sql',
);

describe('079_care_provider_used migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');

  it('adds typed provider on entries and provider used on occurrences', () => {
    expect(sql).toMatch(/provider_typed_name TEXT/);
    expect(sql).toMatch(/provider_contact_snapshot JSONB/);
    expect(sql).not.toMatch(/gen_random_uuid/);
  });
});
