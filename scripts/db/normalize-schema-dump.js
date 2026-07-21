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

export function normalizeSchemaDump(raw) {
  const lines = raw.replace(/\r\n/g, '\n').split('\n');
  const kept = [];

  for (const line of lines) {
    const trimmed = line.trimEnd();
    if (isNoiseLine(trimmed.trim())) continue;
    kept.push(trimmed);
  }

  return `${kept.join('\n').trim()}\n`;
}

function main() {
  const input = process.argv[2]
    ? fs.readFileSync(process.argv[2], 'utf8')
    : fs.readFileSync(0, 'utf8');
  process.stdout.write(normalizeSchemaDump(input));
}

main();
