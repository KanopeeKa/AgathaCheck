#!/usr/bin/env bash
# Bump main merge counter and decide whether to run a full CI audit on main.
# Persists state in CI_AUDIT_STATE_FILE (restored/saved via Actions cache in ci-full-audit.yml).
set -euo pipefail

MERGE_THRESHOLD="${CI_FULL_AUDIT_MERGE_THRESHOLD:-12}"
STALE_DAYS="${CI_FULL_AUDIT_STALE_DAYS:-7}"
STATE_FILE="${CI_AUDIT_STATE_FILE:-.ci-full-audit-state/state.json}"

read_state() {
  python3 - "$STATE_FILE" <<'PY'
import json, pathlib, sys

path = pathlib.Path(sys.argv[1])
if not path.is_file():
    print(json.dumps({"merge_count": 0, "last_run": ""}))
else:
    data = json.loads(path.read_text())
    print(json.dumps({
        "merge_count": int(data.get("merge_count", 0)),
        "last_run": data.get("last_run") or "",
    }))
PY
}

write_state() {
  local count="$1" last="$2"
  python3 - "$STATE_FILE" "$count" "$last" <<'PY'
import json, pathlib, sys

path = pathlib.Path(sys.argv[1])
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps({
    "merge_count": int(sys.argv[2]),
    "last_run": sys.argv[3],
}, indent=2) + "\n")
PY
}

cmd="${1:-decide}"
case "$cmd" in
  decide)
    state="$(read_state)"
    count="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["merge_count"])' <<<"$state")"
    last="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["last_run"])' <<<"$state")"
    count=$((count + 1))

    should_run=false
    reason=""
    if (( count % MERGE_THRESHOLD == 0 )); then
      should_run=true
      reason="merge_count_mod_${MERGE_THRESHOLD}"
    fi

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

    new_last="$last"
    if [[ "$should_run" == true ]]; then
      new_last="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    fi
    write_state "$count" "$new_last"

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
