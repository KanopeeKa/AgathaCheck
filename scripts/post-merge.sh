#!/usr/bin/env bash
# Prepare the workspace after an agent task merge.
#
# Keep this hook limited to dependency/setup work. Full validation remains
# intentionally separate in scripts/pre-push.sh and the CI workflows.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

install_node_dependencies() {
  local directory="$1"

  if [[ -f "${directory}/package-lock.json" ]]; then
    echo "==> Installing locked Node dependencies in ${directory}"
    (
      cd "$directory"
      npm ci --no-audit --no-fund
    )
  fi
}

install_node_dependencies server
install_node_dependencies e2e

echo "==> Preparing the pinned Flutter SDK"
# shellcheck disable=SC1091
source "$ROOT/scripts/flutter-sdk.sh"
agatha_flutter_use
(
  cd flutter_app
  flutter pub get
)

echo "✓ Post-merge setup passed"