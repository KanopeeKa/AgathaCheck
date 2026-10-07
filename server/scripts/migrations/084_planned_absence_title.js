import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const upSql = fs.readFileSync(
  path.resolve(__dirname, '../../../db/migrations/084_planned_absence_title.sql'),
  'utf8',
);
const downSql = fs.readFileSync(
  path.resolve(__dirname, '../../../db/migrations/084_planned_absence_title_down.sql'),
  'utf8',
);

export async function up(client) {
  await client.query(upSql);
}

export async function down(client) {
  await client.query(downSql);
}
