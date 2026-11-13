#!/usr/bin/env node
/**
 * Normalize pg_dump --schema-only output for stable drift comparison.
 * Strips pg_dump noise (SET, comments, ownership) while preserving DDL order.
 *
 * Usage:
 *   pg_dump ... | node scripts/db/normalize-schema-dump.js
 *   node scripts/db/normalize-schema-dump.js path/to/dump.sql
 */
import fs from 'fs';
import { fileURLToPath } from 'url';

const NOISE_PREFIXES = [
  'SET ',
  'SELECT pg_catalog.',
  '\\restrict',
  '\\unrestrict',
];

function isNoiseLine(trimmed, rawLine) {
  if (!trimmed) return true;
  if (trimmed.startsWith('--')) return true;
  // pg_dump session SET commands are top-level; preserve SET inside function bodies.
  if (trimmed.startsWith('SET ') && /^\s/.test(rawLine)) return false;
  return NOISE_PREFIXES.some((prefix) => trimmed.startsWith(prefix));
}

/**
 * PostgreSQL 18 pg_dump emits `ALTER COLUMN … SET (pg_attver=N)`.
 * The number is a catalog counter, not schema, and differs between dumps.
 * Drop a line whose SET list is only pg_attver; keep any other storage option.
 */
function withoutPgAttver(line) {
  if (!/^\s*ALTER TABLE\b/.test(line) || !line.includes('pg_attver=')) return line;
  const next = line
    .replace(/\s*,\s*pg_attver=\d+/g, '')
    .replace(/pg_attver=\d+\s*,\s*/g, '')
    .replace(/pg_attver=\d+/g, '');
  if (/\bSET\s*\(\s*\)/.test(next)) return null;
  return next;
}

function canonicalizeCheckConstraintArrays(line) {
  if (!line.includes('::text = ANY')) return line;
  const castArrayMatch = line.match(
    /::text = ANY \(ARRAY\[((?:\('[^']+'::character varying\)::text,?\s*)+)\]\)/
  );
  if (!castArrayMatch) return line;
  const values = [...castArrayMatch[1].matchAll(/\('([^']+)'::character varying\)::text/g)].map(
    (m) => m[1]
  );
  if (values.length === 0) return line;
  const arrayLiteral = values.map((v) => `'${v}'::character varying`).join(', ');
  return line.replace(
    /::text = ANY \(ARRAY\[[^\]]+\]\)/,
    `::text = ANY ((ARRAY[${arrayLiteral}])::text[])`
  );
}

function canonicalizePartialIndexArrays(line) {
  if (!line.includes('idx_foster_placements_one_active_pet')) return line;
  const statuses = [...line.matchAll(/'([a-z_]+)'/g)]
    .map((m) => m[1])
    .filter((s) =>
      [
        'pending',
        'in_progress',
        'waiting_adoption_confirmation',
        'pending_adoption_conditions',
      ].includes(s)
    )
    .sort();
  if (statuses.length === 0) return line;
  return `CREATE UNIQUE INDEX idx_foster_placements_one_active_pet ON public.foster_placements USING btree (pet_id) WHERE (normalized_status_any(${statuses.join(',')}));`;
}

export function normalizeSchemaDump(raw) {
  const lines = raw.replace(/\r\n/g, '\n').split('\n');
  const kept = [];

  for (const line of lines) {
    const trimmed = line.trimEnd();
    if (isNoiseLine(trimmed.trim(), line)) continue;
    const stable = withoutPgAttver(trimmed);
    if (stable === null) continue;
    kept.push(canonicalizeCheckConstraintArrays(canonicalizePartialIndexArrays(stable)));
  }

  return `${kept.join('\n').trim()}\n`;
}

function main() {
  const input = process.argv[2]
    ? fs.readFileSync(process.argv[2], 'utf8')
    : fs.readFileSync(0, 'utf8');
  process.stdout.write(normalizeSchemaDump(input));
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main();
}
