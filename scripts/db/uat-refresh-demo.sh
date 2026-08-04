#!/usr/bin/env bash
# Refresh UAT/demo data without dropping the database.
# Truncates application tables, then loads the rich demo dataset.
#
# Use on UAT server (APP_ENV=uat) or local non-prod when schema already exists.
# For a full local wipe including schema, use scripts/db/uat-reset.sh instead.
#
# Usage:
#   APP_ENV=uat scripts/db/uat-refresh-demo.sh
#   APP_ENV=development scripts/db/uat-refresh-demo.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export APP_ENV="${APP_ENV:-uat}"

node "${ROOT}/scripts/db/guard-non-prod-cli.js" uat-refresh-demo || {
  echo "uat-refresh-demo: refused — set APP_ENV to development, ci, or uat" >&2
  exit 1
}

# Load backend .env when present (UAT server / local dev)
if [[ -f "${ROOT}/server/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${ROOT}/server/.env"
  set +a
fi

export PGUSER="${PGUSER:-user}"
export PGPASSWORD="${PGPASSWORD:-password}"
export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-agatha_db}"

echo "==> Truncate application data (preserve schema + migrations)"
node "${ROOT}/server/db/seeds/truncate-data.js"

echo "==> Seed rich demo dataset"
cd "${ROOT}/server"
node scripts/seed.js --scenario=all

echo "uat-refresh-demo: done — see docs/e2e/uat-demo-data.md"
