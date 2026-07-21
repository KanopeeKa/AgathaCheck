#!/usr/bin/env bash
# Phase 1: verify committed canonical.sql matches schema built via bootstrap path.
# Requires a running PostgreSQL matching e2e defaults (or PG* env vars).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export PGUSER="${PGUSER:-user}"
export PGPASSWORD="${PGPASSWORD:-password}"
export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-agatha_db}"
CANONICAL="${ROOT}/db/schema/canonical.sql"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if ! command -v psql >/dev/null 2>&1; then
  echo "check-schema-equivalence: psql not found" >&2
  exit 1
fi

if ! pg_isready -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -q 2>/dev/null; then
  echo "check-schema-equivalence: PostgreSQL not ready at ${PGHOST}:${PGPORT}" >&2
  exit 1
fi

if [[ ! -f "$CANONICAL" ]]; then
  echo "check-schema-equivalence: missing ${CANONICAL}" >&2
  echo "Run: scripts/db/regenerate-canonical.sh" >&2
  exit 1
fi

echo "==> migration manifest"
node "${ROOT}/scripts/db/check-migration-manifest.js"

echo "==> build schema via bootstrap path (baseline + incremental migrations)"
RESET_DB="${RESET_DB:-true}"
if [[ "$RESET_DB" == "true" ]]; then
  psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d postgres -v ON_ERROR_STOP=1 <<SQL
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '${PGDATABASE}' AND pid <> pg_backend_pid();
DROP DATABASE IF EXISTS "${PGDATABASE}";
CREATE DATABASE "${PGDATABASE}" OWNER "${PGUSER}";
SQL
fi

bash "${ROOT}/e2e/scripts/bootstrap-db.sh"

echo "==> dump and normalize live schema"
pg_dump -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
  --schema-only --no-owner --no-privileges \
  | node "${ROOT}/scripts/db/normalize-schema-dump.js" > "${WORK}/built.sql"

node "${ROOT}/scripts/db/normalize-schema-dump.js" "$CANONICAL" > "${WORK}/canonical.sql"

if diff -u "${WORK}/canonical.sql" "${WORK}/built.sql" > "${WORK}/diff.txt"; then
  echo "schema-equivalence OK (canonical matches bootstrap path)"
  exit 0
fi

echo "schema-equivalence FAILED: committed canonical differs from bootstrap-built schema" >&2
echo "Regenerate with: scripts/db/regenerate-canonical.sh" >&2
echo "::group::Schema diff (canonical vs built)"
cat "${WORK}/diff.txt" >&2 || true
echo "::endgroup::"
exit 1
