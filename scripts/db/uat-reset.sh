#!/usr/bin/env bash
# Reset a non-prod database and load UAT demo personas.
# Requires PostgreSQL and refuses APP_ENV=production.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export PGUSER="${PGUSER:-user}"
export PGPASSWORD="${PGPASSWORD:-password}"
export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-agatha_db}"
export APP_ENV="${APP_ENV:-development}"

node "${ROOT}/scripts/db/guard-non-prod-cli.js" uat-reset || {
  echo "uat-reset: refused — set APP_ENV to development, ci, or uat" >&2
  exit 1
}

echo "==> Reset database ${PGDATABASE}"
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d postgres -v ON_ERROR_STOP=1 <<SQL
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '${PGDATABASE}' AND pid <> pg_backend_pid();
DROP DATABASE IF EXISTS "${PGDATABASE}";
CREATE DATABASE "${PGDATABASE}" OWNER "${PGUSER}";
SQL

echo "==> Bootstrap schema"
bash "${ROOT}/e2e/scripts/bootstrap-db.sh"

echo "==> Seed UAT demo personas"
cd "${ROOT}/server"
node scripts/seed.js --scenario=all

echo "uat-reset: done — see docs/e2e/uat-demo-data.md"
