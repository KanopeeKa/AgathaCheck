#!/usr/bin/env bash
# Cursor Cloud environment install/update — idempotent dependency setup.
# Node backend only in server/ (Dart backend removed in PR #240).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

log() { echo ">>> [install:] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

require_cmd() {
  local name="$1"
  local hint="$2"
  if command -v "$name" >/dev/null 2>&1; then
    return 0
  fi
  die "${name} not found. ${hint}"
}

ensure_flutter() {
  export PATH="/opt/flutter/bin:${PATH}"
  if [[ -x /opt/flutter/bin/flutter ]]; then
    return 0
  fi
  die "Flutter SDK missing at /opt/flutter/bin/flutter. Rebuild the Cursor Cloud environment (.cursor/Dockerfile) or set up a snapshot with Flutter 3.32.0."
}

ensure_node() {
  require_cmd node "Install Node.js 22 (provided by .cursor/Dockerfile)."
  require_cmd npm "Install npm (bundled with Node.js)."
}

# Non-interactive install does not source ~/.bashrc (see AGENTS.md).
ensure_flutter
ensure_node

log "preflight ok (flutter $(flutter --version 2>/dev/null | head -1), node $(node --version))"

log "flutter_app"
(
  cd flutter_app
  flutter pub get
)

log "server (Node)"
(
  cd server
  npm ci
)

log "e2e"
(
  cd e2e
  npm ci
)

log "done"
