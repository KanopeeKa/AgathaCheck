import { readFileSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '../../../..');
const MAP_PATH = path.join(REPO_ROOT, 'docs/engineering/privacy/erasure-data-map.json');

/**
 * @typedef {{ table: string, column: string, source: 'foreign_key' | 'column', pg_on_delete?: string }} UserLinkBinding
 */

const FK_SQL = `
  SELECT
    kcu.table_name AS table_name,
    kcu.column_name AS column_name,
    CASE rc.delete_rule
      WHEN 'CASCADE' THEN 'c'
      WHEN 'SET NULL' THEN 'n'
      WHEN 'NO ACTION' THEN 'a'
      WHEN 'RESTRICT' THEN 'r'
      ELSE LOWER(SUBSTRING(rc.delete_rule FROM 1 FOR 1))
    END AS pg_on_delete
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.table_schema = kcu.table_schema
  JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
   AND ccu.table_schema = tc.table_schema
  JOIN information_schema.referential_constraints rc
    ON rc.constraint_name = tc.constraint_name
   AND rc.constraint_schema = tc.table_schema
  WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
    AND ccu.table_name = 'users'
    AND ccu.column_name = 'id'
  ORDER BY kcu.table_name, kcu.column_name
`;

const COLUMN_SQL = `
  SELECT c.table_name, c.column_name
  FROM information_schema.columns c
  WHERE c.table_schema = 'public'
    AND (
      c.column_name = 'user_id'
      OR c.column_name LIKE '%\\_user_id' ESCAPE '\\'
      OR c.column_name LIKE '%\\_by' ESCAPE '\\'
      OR c.column_name LIKE '%\\_by_user_id' ESCAPE '\\'
      OR c.column_name IN ('email', 'invitee_email')
    )
  ORDER BY c.table_name, c.column_name
`;

/**
 * @param {import('pg').Pool} pool
 * @returns {Promise<UserLinkBinding[]>}
 */
export async function discoverUserLinkedBindings(pool) {
  const fkResult = await pool.query(FK_SQL);
  const fkKeys = new Set();
  /** @type {UserLinkBinding[]} */
  const bindings = fkResult.rows.map((row) => {
    const key = `${row.table_name}.${row.column_name}`;
    fkKeys.add(key);
    return {
      table: row.table_name,
      column: row.column_name,
      source: 'foreign_key',
      pg_on_delete: row.pg_on_delete,
    };
  });

  const colResult = await pool.query(COLUMN_SQL);
  for (const row of colResult.rows) {
    const key = `${row.table_name}.${row.column_name}`;
    if (fkKeys.has(key)) continue;
    bindings.push({
      table: row.table_name,
      column: row.column_name,
      source: 'column',
    });
  }

  bindings.sort((a, b) => {
    const ta = `${a.table}.${a.column}`;
    const tb = `${b.table}.${b.column}`;
    return ta.localeCompare(tb);
  });

  return bindings;
}

export function erasureDataMapPath() {
  return MAP_PATH;
}

export function loadErasureDataMap() {
  const raw = readFileSync(MAP_PATH, 'utf8');
  return JSON.parse(raw);
}

export function bindingKey(table, column) {
  return `${table}.${column}`;
}
