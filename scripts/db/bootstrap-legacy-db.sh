#!/usr/bin/env bash
# Legacy bootstrap path (v3 baseline + incremental migrations) — CI equivalence only.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export PGUSER="${PGUSER:-user}"
export PGPASSWORD="${PGPASSWORD:-password}"
export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-agatha_db}"

LEGACY_BASELINE="${ROOT}/db/migrations/archive/v3__initial_uuid_schema.sql"

if [[ ! -f "$LEGACY_BASELINE" ]]; then
  echo "bootstrap-legacy-db: missing ${LEGACY_BASELINE}" >&2
  exit 1
fi

echo "==> Legacy bootstrap: v3 baseline + migrate.js up"
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
  -v ON_ERROR_STOP=1 -f "$LEGACY_BASELINE"

cd "${ROOT}/server"
node scripts/migrate.js up
