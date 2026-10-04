import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../../..');

export function peopleRelationshipSlotsMigrationSql() {
  return fs.readFileSync(
    path.join(repoRoot, 'db/migrations/087_people_relationship_slots.sql'),
    'utf8',
  );
}

export function peopleRelationshipSlotsDownSql() {
  return fs.readFileSync(
    path.join(repoRoot, 'db/migrations/087_people_relationship_slots_down.sql'),
    'utf8',
  );
}

export async function applyPeopleRelationshipSlotsMigration(db) {
  await db.query(peopleRelationshipSlotsMigrationSql());
}

export async function applyPeopleRelationshipSlotsDown(db) {
  await db.query(peopleRelationshipSlotsDownSql());
}
