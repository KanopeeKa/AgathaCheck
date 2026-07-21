#!/usr/bin/env bash
# Verify canonical+ledger bootstrap produces the same schema as legacy v3+migrations.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export PGUSER="${PGUSER:-user}"
export PGPASSWORD="${PGPASSWORD:-password}"
export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-agatha_db}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

reset_db() {
  psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d postgres -v ON_ERROR_STOP=1 <<SQL
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '${PGDATABASE}' AND pid <> pg_backend_pid();
DROP DATABASE IF EXISTS "${PGDATABASE}";
CREATE DATABASE "${PGDATABASE}" OWNER "${PGUSER}";
SQL
}

dump_normalized() {
  pg_dump -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
    --schema-only --no-owner --no-privileges \
    | node "${ROOT}/scripts/db/normalize-schema-dump.js"
}

if ! pg_isready -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -q 2>/dev/null; then
  echo "check-bootstrap-paths-equivalence: PostgreSQL not ready" >&2
  exit 1
fi

echo "==> Legacy bootstrap path"
reset_db
bash "${ROOT}/scripts/db/bootstrap-legacy-db.sh" > /dev/null
dump_normalized > "${WORK}/legacy.sql"

echo "==> Canonical bootstrap path"
reset_db
bash "${ROOT}/e2e/scripts/bootstrap-db.sh" > /dev/null
dump_normalized > "${WORK}/canonical.sql"

if diff -u "${WORK}/legacy.sql" "${WORK}/canonical.sql" > "${WORK}/diff.txt"; then
  echo "bootstrap-paths-equivalence OK"
  exit 0
fi

echo "bootstrap-paths-equivalence FAILED" >&2
cat "${WORK}/diff.txt" >&2
exit 1
