#!/usr/bin/env bash
# Run in-host loopback smoke on the UAT server (bundled for appleboy script_path).
set -euo pipefail

SITE_ROOT="${UAT_SITE_ROOT:-${HOME}/uat.agathatrack.com}"
APPDIR="${SITE_ROOT}/backend"

echo "UAT_INHOST_SMOKE_BEGIN"
echo "site_root=${SITE_ROOT}"
echo "app_dir=${APPDIR}"

if [[ ! -d "$APPDIR" ]]; then
  echo "::error::Backend directory missing: ${APPDIR}"
  exit 1
fi

cd "$APPDIR"

echo "=== Migration status (fail on pending) ==="
status_out="$(node scripts/migrate.js status 2>&1)" || {
  echo "$status_out"
  echo "::error::migrate.js status failed"
  exit 1
}
echo "$status_out"
if grep -qE '\[PENDING\]| [1-9][0-9]* pending' <<<"$status_out"; then
  echo "::error::Pending migrations on UAT — run node scripts/migrate.js up"
  exit 1
fi

PORT="$(node -e "const n=require('net').createServer();n.listen(0,'127.0.0.1',()=>{console.log(n.address().port);n.close()});")"
export PORT
export HOST=127.0.0.1

echo "=== Start loopback server on 127.0.0.1:${PORT} ==="
node bin/start.js &
SERVER_PID=$!
cleanup() {
  if kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

for attempt in $(seq 1 45); do
  if curl -sf "http://127.0.0.1:${PORT}/backend/health" >/dev/null; then
    echo "loopback_health=ok attempt=${attempt}"
    break
  fi
  if [[ "$attempt" -eq 45 ]]; then
    echo "::error::Loopback health never became ready"
    exit 1
  fi
  sleep 2
done

echo "=== In-host API smoke ==="
node scripts/uat-inhost-smoke.mjs --base-url "http://127.0.0.1:${PORT}" --skip-migrations

echo "UAT_INHOST_SMOKE_END"
