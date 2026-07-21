#!/usr/bin/env bash
# Cursor Cloud environment install/update — idempotent dependency setup.
# Node backend only in server/ (Dart backend removed in PR #240).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

echo ">>> [install:] flutter_app"
(
  cd flutter_app
  flutter pub get
)

echo ">>> [install:] server (Node)"
(
  cd server
  npm ci
)

echo ">>> [install:] e2e"
(
  cd e2e
  npm ci
)

echo ">>> [install:] done"
