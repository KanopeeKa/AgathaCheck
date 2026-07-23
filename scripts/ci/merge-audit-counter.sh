#!/usr/bin/env bash
# Bump main merge counter and decide whether to run a full CI audit on main.
# Uses repository variables CI_FULL_AUDIT_MERGE_COUNT and CI_FULL_AUDIT_LAST_RUN.
set -euo pipefail

MERGE_THRESHOLD="${CI_FULL_AUDIT_MERGE_THRESHOLD:-12}"
STALE_DAYS="${CI_FULL_AUDIT_STALE_DAYS:-7}"
VAR_COUNT="CI_FULL_AUDIT_MERGE_COUNT"
VAR_LAST="CI_FULL_AUDIT_LAST_RUN"
REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY required}"

read_var() {
  local name="$1" default="${2:-0}"
  gh api "repos/${REPO}/actions/variables/${name}" --jq .value 2>/dev/null || echo "$default"
}

write_var() {
  local name="$1" value="$2"
  if gh api "repos/${REPO}/actions/variables/${name}" >/dev/null 2>&1; then
    gh api "repos/${REPO}/actions/variables/${name}" -X PATCH -f value="$value" >/dev/null
  else
    gh api "repos/${REPO}/actions/variables" -X POST \
      -f name="$name" -f value="$value" >/dev/null
  fi
}

cmd="${1:-decide}"
case "$cmd" in
  decide)
    count="$(read_var "$VAR_COUNT" 0)"
    count=$((count + 1))
    write_var "$VAR_COUNT" "$count"

    should_run=false
    reason=""
    if (( count % MERGE_THRESHOLD == 0 )); then
      should_run=true
      reason="merge_count_mod_${MERGE_THRESHOLD}"
    fi

    last="$(read_var "$VAR_LAST" "")"
    if [[ "$should_run" != true && -n "$last" ]]; then
      if python3 - "$last" "$STALE_DAYS" <<'PY'
import sys
from datetime import datetime, timezone

last = datetime.fromisoformat(sys.argv[1].replace("Z", "+00:00"))
days = int(sys.argv[2])
age = (datetime.now(timezone.utc) - last).total_seconds() / 86400
sys.exit(0 if age >= days else 1)
PY
      then
        should_run=true
        reason="stale_${STALE_DAYS}d"
      fi
    elif [[ "$should_run" != true && -z "$last" ]]; then
      should_run=true
      reason="first_audit"
    fi

    if [[ "$should_run" == true ]]; then
      write_var "$VAR_LAST" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    fi

    echo "merge_count=$count"
    echo "should_run=$should_run"
    echo "reason=$reason"
    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
      {
        echo "merge_count=$count"
        echo "should_run=$should_run"
        echo "reason=$reason"
      } >>"$GITHUB_OUTPUT"
    fi
    ;;
  *)
    echo "usage: merge-audit-counter.sh decide" >&2
    exit 1
    ;;
esac
