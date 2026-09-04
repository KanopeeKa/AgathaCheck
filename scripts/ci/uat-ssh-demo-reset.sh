#!/usr/bin/env bash
# Remote UAT demo data reset — runs on the UAT server over SSH.
# Truncates application data and reloads the rich demo dataset.
# Does NOT drop the database or re-run migrations.
set -euo pipefail

# shellcheck source=assert-node-modules-symlink.lib.sh
source "$(cd "$(dirname "$0")" && pwd)/assert-node-modules-symlink.lib.sh"

HOME="$(uat_nm_home_dir)"
export HOME

SITE_ROOT="${UAT_SITE_ROOT:-${HOME}/uat.agathatrack.com}"
APPDIR="${SITE_ROOT}/backend"
export APP_ENV=uat
export UAT_APP_DIR="${APPDIR}"

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

if ! uat_nm_use_node; then
  echo "::error::node not found in PATH or CloudLinux nodevenv — cannot run seed scripts"
  echo "Expected: ~/nodevenv/uat.agathatrack.com/backend/<version>/bin/node"
  exit 1
fi
echo "node_bin=${UAT_NODE_BIN}"

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
