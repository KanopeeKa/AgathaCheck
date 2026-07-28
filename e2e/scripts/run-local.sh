#!/usr/bin/env bash
# Run Agatha Track E2E tests locally (PostgreSQL + Flutter web build + Node server + Playwright).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export PATH="/opt/flutter/bin:$PATH"

echo "==> Starting PostgreSQL"
sudo pg_ctlcluster 16 main start 2>/dev/null || true

echo "==> Bootstrapping database"
chmod +x "$ROOT/e2e/scripts/bootstrap-db.sh"
"$ROOT/e2e/scripts/bootstrap-db.sh"

echo "==> Building Flutter web (if missing or stale)"
if [ ! -d "$ROOT/flutter_app/build/web" ]; then
  cd "$ROOT/flutter_app"
  flutter pub get
  flutter build web --release --no-tree-shake-icons
fi

echo "==> Installing E2E dependencies"
cd "$ROOT/e2e"
npm ci
npx playwright install chromium --with-deps

echo "==> Starting Node server on :3000"
cd "$ROOT/server"
export PGUSER=user PGPASSWORD=password PGHOST=localhost PGPORT=5432 PGDATABASE=agatha_db
export E2E=1
if fuser 3000/tcp >/dev/null 2>&1; then
  echo "Port 3000 already in use — stopping existing process"
  fuser -k 3000/tcp 2>/dev/null || true
  sleep 2
fi
node bin/start.js &
SERVER_PID=$!
trap 'kill $SERVER_PID 2>/dev/null || true' EXIT
sleep 3

echo "==> Running Playwright"
cd "$ROOT/e2e"
E2E_BASE_URL="${E2E_BASE_URL:-http://localhost:3000}" npm test
