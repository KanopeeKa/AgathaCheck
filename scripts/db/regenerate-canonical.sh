#!/usr/bin/env bash
# Regenerate db/schema/canonical.sql from the authoritative bootstrap path.
# Run after adding migrations, then commit canonical.sql + migration-manifest.json.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export PGUSER="${PGUSER:-user}"
export PGPASSWORD="${PGPASSWORD:-password}"
export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-agatha_db}"
CANONICAL="${ROOT}/db/schema/canonical.sql"
HEADER="${ROOT}/db/schema/canonical.header.sql"

if ! pg_isready -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -q 2>/dev/null; then
  echo "regenerate-canonical: PostgreSQL not ready at ${PGHOST}:${PGPORT}" >&2
  exit 1
fi

psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d postgres -v ON_ERROR_STOP=1 <<SQL
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '${PGDATABASE}' AND pid <> pg_backend_pid();
DROP DATABASE IF EXISTS "${PGDATABASE}";
CREATE DATABASE "${PGDATABASE}" OWNER "${PGUSER}";
SQL

bash "${ROOT}/e2e/scripts/bootstrap-db.sh"

mkdir -p "$(dirname "$CANONICAL")"

{
  cat "$HEADER"
  pg_dump -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
    --schema-only --no-owner --no-privileges
} | node "${ROOT}/scripts/db/normalize-schema-dump.js" > "$CANONICAL"

echo "Wrote ${CANONICAL}"
echo "Next: node scripts/db/check-migration-manifest.js && scripts/db/check-schema-equivalence.sh"
