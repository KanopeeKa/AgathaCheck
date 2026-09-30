#!/usr/bin/env bash
# Local/CI replay of in-host smoke (requires PostgreSQL + migrated schema).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "${ROOT}/server"

export PGUSER="${PGUSER:-user}"
export PGPASSWORD="${PGPASSWORD:-password}"
export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-agatha_db}"

node scripts/uat-inhost-smoke.mjs --local
