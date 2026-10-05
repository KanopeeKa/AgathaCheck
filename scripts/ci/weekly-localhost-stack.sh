#!/usr/bin/env bash
# Boot PostgreSQL on ubuntu-24.04 runners, bootstrap schema, start Node for weekly advisory scans.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export PGUSER="${PGUSER:-user}"
export PGPASSWORD="${PGPASSWORD:-password}"
export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-agatha_db}"
PORT="${PORT:-3000}"
BASE_URL="http://127.0.0.1:${PORT}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-30}"

echo "==> Start PostgreSQL (pg_ctlcluster 16 main)"
sudo pg_ctlcluster 16 main start

echo "==> Install server dependencies"
cd "${ROOT}/server"
npm ci

echo "==> Bootstrap database (canonical snapshot + ledger, same as PR CI)"
chmod +x "${ROOT}/e2e/scripts/bootstrap-db.sh"
bash "${ROOT}/e2e/scripts/bootstrap-db.sh"

echo "==> Start server"
node bin/start.js &
server_pid=$!
if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "SERVER_PID=${server_pid}" >> "$GITHUB_ENV"
fi

n=0
until curl -sf "${BASE_URL}/backend/health"; do
  n=$((n + 1))
  if [ "$n" -ge "$MAX_ATTEMPTS" ]; then
    echo "weekly-localhost-stack: server not healthy at ${BASE_URL}/backend/health" >&2
    exit 1
  fi
  sleep 2
done
echo "Server healthy at ${BASE_URL}"
