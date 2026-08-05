#!/usr/bin/env bash
# Boot local stack for babysit-uat shard runs (PG + web build + server on :3000).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="/opt/flutter/bin:${PATH:-}"

echo "==> PostgreSQL"
sudo pg_ctlcluster 16 main start 2>/dev/null || true

echo "==> DB bootstrap"
chmod +x "${ROOT}/e2e/scripts/bootstrap-db.sh"
"${ROOT}/e2e/scripts/bootstrap-db.sh"

echo "==> Flutter web build"
cd "${ROOT}/flutter_app"
flutter pub get
flutter build web --release --no-tree-shake-icons

echo "==> E2E deps"
cd "${ROOT}/e2e"
npm ci
npx playwright install chromium --with-deps

echo "==> Backend (port 3000)"
cd "${ROOT}/server"
export PGUSER=user PGPASSWORD=password PGHOST=localhost PGPORT=5432 PGDATABASE=agatha_db
export E2E=1
if fuser 3000/tcp >/dev/null 2>&1; then
  echo "Port 3000 in use — stopping existing process"
  fuser -k 3000/tcp 2>/dev/null || true
  sleep 2
fi
node bin/start.js &
SERVER_PID=$!
echo "$SERVER_PID" > /tmp/agatha-babysit-uat-server.pid
sleep 3

if ! curl -sf http://localhost:3000/ >/dev/null; then
  echo "Server failed to start on :3000" >&2
  kill "$SERVER_PID" 2>/dev/null || true
  exit 1
fi

echo "babysit-uat stack ready (pid $SERVER_PID)"
