#!/usr/bin/env bash
# Fail when active source imports frozen feature modules.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATTERN='(features/(organization|fostering_session)/|/(organization|fostering_session)/(presentation|domain|data)/)'

ACTIVE_FLUTTER_DIRS=(
  "$ROOT/flutter_app/lib/core"
  "$ROOT/flutter_app/lib/features/auth"
  "$ROOT/flutter_app/lib/features/experience"
  "$ROOT/flutter_app/lib/features/pet_profile"
  "$ROOT/flutter_app/lib/features/vet"
  "$ROOT/flutter_app/lib/features/health_tracking"
  "$ROOT/flutter_app/lib/features/notifications"
  "$ROOT/flutter_app/lib/features/sharing"
  "$ROOT/flutter_app/lib/features/weight_tracking"
  "$ROOT/flutter_app/lib/features/subscription"
  "$ROOT/flutter_app/lib/features/about"
  "$ROOT/flutter_app/lib/features/help"
  "$ROOT/flutter_app/lib/l10n"
)

scan_flutter_active() {
  local hits=""
  for dir in "${ACTIVE_FLUTTER_DIRS[@]}"; do
    [[ -d "$dir" ]] || continue
    local part
    part="$(rg -n "$PATTERN" "$dir" 2>/dev/null || true)"
    [[ -n "$part" ]] && hits+="$part"$'\n'
  done

  if [[ -n "$hits" ]]; then
    echo "::error::Frozen domain boundary violation (flutter):"
    echo "$hits"
    return 1
  fi
  return 0
}

scan_server_routes() {
  local hits=""
  for file in "$ROOT/server/routes"/*.js; do
    [[ -f "$file" ]] || continue
    case "$(basename "$file")" in
      organizations.js|fosterPlacements.js|custodyTransfers.js) continue ;;
    esac
    local part
    part="$(rg -n 'routes/(organizations|fosterPlacements|custodyTransfers)' "$file" 2>/dev/null || true)"
    [[ -n "$part" ]] && hits+="$part"$'\n'
  done

  if [[ -n "$hits" ]]; then
    echo "::error::Frozen domain boundary violation (server routes):"
    echo "$hits"
    return 1
  fi
  return 0
}

failed=0
scan_flutter_active || failed=1
scan_server_routes || failed=1

if [[ "$failed" -ne 0 ]]; then
  echo '::error::Active code must not import frozen organization/fostering_session modules.'
  exit 1
fi

echo 'Frozen domain boundary check: OK'
