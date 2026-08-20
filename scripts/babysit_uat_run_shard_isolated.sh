#!/usr/bin/env bash
# Run one pre-UAT shard on an isolated server port (parallel local shard workers).
# Requires babysit_uat_bootstrap_stack.sh once per machine (shared DB + web build).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARD="${1:?usage: babysit_uat_run_shard_isolated.sh <1-13>}"

if ! [[ "$SHARD" =~ ^[0-9]+$ ]] || (( SHARD < 1 || SHARD > 13 )); then
  echo "shard must be 1-13" >&2
  exit 1
fi

PORT=$((3000 + SHARD))
export PORT
export E2E_BASE_URL="http://localhost:${PORT}"
export PGUSER="${PGUSER:-user}"
export PGPASSWORD="${PGPASSWORD:-password}"
export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-agatha_db}"
export E2E=1

PID_FILE="/tmp/agatha-babysit-uat-server-${SHARD}.pid"
LOG_FILE="/tmp/agatha-babysit-uat-server-${SHARD}.log"

stop_server() {
  if [[ -f "$PID_FILE" ]]; then
    local pid
    pid="$(cat "$PID_FILE")"
    kill "$pid" 2>/dev/null || true
    rm -f "$PID_FILE"
  fi
  if fuser "${PORT}/tcp" >/dev/null 2>&1; then
    fuser -k "${PORT}/tcp" 2>/dev/null || true
    sleep 1
  fi
}

trap stop_server EXIT

stop_server

cd "${ROOT}/server"
node bin/start.js >"$LOG_FILE" 2>&1 &
echo $! >"$PID_FILE"

for attempt in $(seq 1 30); do
  if curl -sf "${E2E_BASE_URL}/landing" >/dev/null; then
    break
  fi
  if [[ "$attempt" -eq 30 ]]; then
    echo "Server failed on port ${PORT} (shard ${SHARD})" >&2
    tail -20 "$LOG_FILE" >&2 || true
    exit 1
  fi
  sleep 2
done

cd "${ROOT}/e2e"
npm run test:ci-shard -- "$SHARD"
