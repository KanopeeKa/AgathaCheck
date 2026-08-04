#!/usr/bin/env bash
# Remote UAT demo data reset — runs on the UAT server over SSH.
# Truncates application data and reloads the rich demo dataset.
# Does NOT drop the database or re-run migrations.
set -euo pipefail

SITE_ROOT="${UAT_SITE_ROOT:-${HOME}/uat.agathatrack.com}"
APPDIR="${SITE_ROOT}/backend"
export APP_ENV=uat

echo "UAT_DEMO_RESET_BEGIN"
echo "=== UAT demo data reset ==="
echo "app_dir=${APPDIR}"

cd "${APPDIR}"

if [[ ! -f .env ]]; then
  echo "::error::backend/.env not found — cannot connect to database"
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

if ! command -v node >/dev/null 2>&1; then
  echo "::error::node not found in PATH"
  exit 1
fi

echo "=== Truncate application data ==="
node db/seeds/truncate-data.js

echo "=== Seed rich demo dataset ==="
node scripts/seed.js --scenario=all

echo "=== Restart Passenger ==="
mkdir -p tmp
touch tmp/restart.txt

echo "UAT_DEMO_RESET_END"
echo "=== UAT demo data reset complete ==="
echo "Credentials: docs/e2e/uat-demo-data.md"
