#!/usr/bin/env bash
# Bootstrap PostgreSQL for E2E/dev: canonical snapshot + migration ledger on empty DB.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export PGUSER="${PGUSER:-user}"
export PGPASSWORD="${PGPASSWORD:-password}"
export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-agatha_db}"
CANONICAL="${ROOT}/db/schema/canonical.sql"

echo "==> Checking database schema"
TABLE_EXISTS=$(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -tAc \
  "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users');")

if [ "$TABLE_EXISTS" != "t" ]; then
  echo "==> Empty database — applying canonical snapshot"
  if [[ ! -f "$CANONICAL" ]]; then
    echo "bootstrap-db: missing ${CANONICAL}" >&2
    exit 1
  fi
  psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
    -v ON_ERROR_STOP=1 -f "$CANONICAL"
  cd "${ROOT}/server"
  node scripts/seed-migration-ledger.js
else
  echo "==> Existing database — applying pending migrations only"
  cd "${ROOT}/server"
  node scripts/migrate.js up
fi
