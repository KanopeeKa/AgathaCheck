import { test } from 'node:test';
import assert from 'node:assert/strict';
import { normalizeSchemaDump } from '../db/normalize-schema-dump.js';

test('normalizeSchemaDump strips pg_dump noise and preserves DDL', () => {
  const raw = `
-- PostgreSQL dump
SET statement_timeout = 0;
SELECT pg_catalog.set_config('search_path', '', false);

CREATE TABLE public.users (
    id uuid NOT NULL
);

-- another comment
`;

  const normalized = normalizeSchemaDump(raw);
  assert.equal(
    normalized,
    `CREATE TABLE public.users (
    id uuid NOT NULL
);\n`
  );
});
