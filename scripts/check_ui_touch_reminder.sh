#!/usr/bin/env bash
# Advisory reminder when a diff touches Flutter presentation UI.
# Called from pre-push-changed.sh — never fails the gate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MERGE_BASE="${1:-origin/main}"
CHANGED="$(git diff --name-only "$MERGE_BASE" HEAD 2>/dev/null || true; git diff --name-only 2>/dev/null || true; git diff --cached --name-only 2>/dev/null || true)"
CHANGED="$(echo "$CHANGED" | sort -u | grep -v '^$' || true)"

if [[ -z "$CHANGED" ]]; then
  exit 0
fi

ui_paths=()
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  case "$f" in
    flutter_app/lib/features/*/presentation/*|flutter_app/lib/core/theme/*|flutter_app/lib/core/router/*)
      ui_paths+=("$f")
      ;;
  esac
done <<< "$CHANGED"

if [[ ${#ui_paths[@]} -eq 0 ]]; then
  exit 0
fi

echo ""
echo "==> UI touch reminder (${#ui_paths[@]} presentation/theme/router file(s))"
echo "    Run the /ui-check skill before opening or updating the PR."
echo "    Skill: .cursor/skills/ui-check/SKILL.md"
echo "    Escalate to /ui-design-deep for theme, landing/auth, or multi-screen flows."
echo "    Touched:"
printf '      - %s\n' "${ui_paths[@]}"
echo ""
