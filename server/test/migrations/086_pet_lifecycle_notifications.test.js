import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(__dirname, '../../../db/migrations/086_pet_lifecycle_notifications.sql');
const downPath = path.resolve(__dirname, '../../../db/migrations/086_pet_lifecycle_notifications_down.sql');

describe('086_pet_lifecycle_notifications migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('creates pet_lifecycle_notifications with composite primary key', () => {
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS pet_lifecycle_notifications/);
    expect(sql).toMatch(/PRIMARY KEY \(pet_id, event, recipient_user_id\)/);
    expect(sql).toMatch(/REFERENCES pets\(id\) ON DELETE CASCADE/);
    expect(sql).not.toMatch(/gen_random_uuid/);
  });

  it('down migration drops only pet_lifecycle_notifications', () => {
    expect(downSql.trim()).toBe('DROP TABLE IF EXISTS pet_lifecycle_notifications;');
  });
});
