import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../../..');

export function weightMonitoringUnifyMigrationSql() {
  return fs.readFileSync(
    path.join(repoRoot, 'db/migrations/092_weight_monitoring_unify.sql'),
    'utf8',
  );
}

export function weightMonitoringUnifyDownSql() {
  return fs.readFileSync(
    path.join(repoRoot, 'db/migrations/092_weight_monitoring_unify_down.sql'),
    'utf8',
  );
}

export async function applyWeightMonitoringUnifyMigration(db) {
  await db.query(weightMonitoringUnifyMigrationSql());
}

export async function applyWeightMonitoringUnifyDown(db) {
  await db.query(weightMonitoringUnifyDownSql());
}
