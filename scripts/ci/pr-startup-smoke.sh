#!/usr/bin/env bash
# Fast PR smoke: boot Postgres schema, start Node server, probe health endpoints.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PORT="${PORT:-3000}"
BASE_URL="http://localhost:${PORT}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-30}"
SLEEP_SECS="${SLEEP_SECS:-2}"
SERVER_LOG="$(mktemp)"
SERVER_PID=""

bash "${ROOT}/e2e/scripts/bootstrap-db.sh"

echo "==> Schema drift check (canonical vs bootstrap path)"
RESET_DB=false bash "${ROOT}/scripts/db/check-schema-equivalence.sh"

echo "==> Bootstrap path equivalence (legacy vs canonical+ledger)"
RESET_DB=false bash "${ROOT}/scripts/db/check-bootstrap-paths-equivalence.sh"

cd "${ROOT}/server"
node bin/start.js >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!

print_server_log_tail() {
  if [[ -f "$SERVER_LOG" ]]; then
    echo "::group::Server log tail (last 80 lines)"
    tail -n 80 "$SERVER_LOG" || true
    echo "::endgroup::"
  fi
}

cleanup() {
  if [[ -n "$SERVER_PID" ]]; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  rm -f "$SERVER_LOG"
}
trap cleanup EXIT

echo "Waiting for ${BASE_URL}/backend/health (up to ${MAX_ATTEMPTS} attempts)..."
healthy=false
for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  if curl -sf "${BASE_URL}/backend/health" | grep -q '"status":"OK"'; then
    echo "Backend healthy after attempt ${attempt}"
    healthy=true
    break
  fi
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "::error::Server process exited before health check passed" >&2
    print_server_log_tail
    exit 1
  fi
  echo "Waiting for server (${attempt}/${MAX_ATTEMPTS})..."
  sleep "$SLEEP_SECS"
done

if [[ "$healthy" != "true" ]]; then
  echo "::error::Server did not become healthy at ${BASE_URL}/backend/health" >&2
  print_server_log_tail
  exit 1
fi

if ! curl -sf "${BASE_URL}/backend/" | grep -q 'Backend alive'; then
  echo "::error::Backend root probe failed at ${BASE_URL}/backend/" >&2
  print_server_log_tail
  exit 1
fi
echo "Backend root OK"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  bash "${ROOT}/scripts/ci/append-summary.sh" "PR startup smoke" \
    "base_url=${BASE_URL}" \
    "health_path=/backend/health" \
    "outcome=success"
fi

echo "PR startup smoke passed"
