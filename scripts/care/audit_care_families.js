#!/usr/bin/env node
/**
 * CP-0 report-only audit: care_family coverage on health_entries.
 *
 * Usage: node scripts/care/audit_care_families.js [--json]
 */
import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config({ path: 'server/.env' });
dotenv.config();

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  user: process.env.PGUSER || 'user',
  password: process.env.PGPASSWORD || 'password',
  host: process.env.PGHOST || 'localhost',
  port: Number(process.env.PGPORT || 5432),
  database: process.env.PGDATABASE || 'agatha_db',
});

async function main() {
  const recurringNullFamily = await pool.query(`
    SELECT COUNT(*)::int AS count
    FROM health_entries
    WHERE frequency IS NOT NULL AND frequency <> 'once'
      AND (care_family IS NULL OR care_family = '')
  `);
  const inferredOther = await pool.query(`
    SELECT COUNT(*)::int AS count
    FROM health_entries
    WHERE care_family = 'other'
  `);
  const recurringWithoutOccurrences = await pool.query(`
    SELECT COUNT(*)::int AS count
    FROM health_entries he
    WHERE he.frequency IS NOT NULL AND he.frequency <> 'once'
      AND NOT EXISTS (
        SELECT 1 FROM health_occurrences ho WHERE ho.health_entry_id = he.id
      )
  `);

  const report = {
    recurring_without_care_family: recurringNullFamily.rows[0].count,
    care_family_other_rows: inferredOther.rows[0].count,
    recurring_without_occurrences: recurringWithoutOccurrences.rows[0].count,
  };

  if (process.argv.includes('--json')) {
    console.log(JSON.stringify(report, null, 2));
  } else {
    console.log('Care family audit (report-only)');
    console.log(`  recurring without care_family: ${report.recurring_without_care_family}`);
    console.log(`  care_family = other: ${report.care_family_other_rows}`);
    console.log(`  recurring without occurrences: ${report.recurring_without_occurrences}`);
  }

  await pool.end();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
