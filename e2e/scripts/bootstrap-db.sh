#!/usr/bin/env bash
# Bootstrap PostgreSQL for E2E: apply canonical schema on empty DB, then incremental migrations.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export PGUSER="${PGUSER:-user}"
export PGPASSWORD="${PGPASSWORD:-password}"
export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-agatha_db}"

echo "==> Checking database schema"
TABLE_EXISTS=$(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -tAc \
  "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users');")

if [ "$TABLE_EXISTS" != "t" ]; then
  echo "==> Empty database — applying canonical schema (v3)"
  psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
    -f "$ROOT/db/migrations/v3__initial_uuid_schema.sql"
fi

echo "==> Applying incremental migrations"
cd "$ROOT/server"
node scripts/migrate.js up
