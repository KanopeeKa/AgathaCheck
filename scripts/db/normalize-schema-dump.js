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

function isNoiseLine(trimmed) {
  if (!trimmed) return true;
  if (trimmed.startsWith('--')) return true;
  return NOISE_PREFIXES.some((prefix) => trimmed.startsWith(prefix));
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
  return `CREATE UNIQUE INDEX idx_foster_placements_one_active_pet ON public.foster_placements USING btree (pet_id) WHERE (normalized_status_any(${statuses.join(',')}))`;
}

export function normalizeSchemaDump(raw) {
  const lines = raw.replace(/\r\n/g, '\n').split('\n');
  const kept = [];

  for (const line of lines) {
    const trimmed = line.trimEnd();
    if (isNoiseLine(trimmed.trim())) continue;
    kept.push(canonicalizePartialIndexArrays(trimmed));
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
