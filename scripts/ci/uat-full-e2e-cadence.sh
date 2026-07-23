#!/usr/bin/env bash
# Decide whether UAT deploy should run the full localhost Playwright shard matrix.
# Persists state in CI cache (see deploy-uat.yml uat-full-e2e-decide job).
#
# Default threshold 1 = every merge (current prod-ready behaviour).
# Set UAT_FULL_E2E_MERGE_THRESHOLD=3 to run full E2E every 3rd promote (coordinator may lower).
set -euo pipefail

MERGE_THRESHOLD="${UAT_FULL_E2E_MERGE_THRESHOLD:-1}"
FORCE_RUN="${UAT_FULL_E2E_FORCE_RUN:-false}"
STATE_FILE="${UAT_FULL_E2E_STATE_FILE:-.ci-uat-full-e2e-state/state.json}"

read_state() {
  python3 - "$STATE_FILE" <<'PY'
import json, pathlib, sys

path = pathlib.Path(sys.argv[1])
if not path.is_file():
    print(json.dumps({"merge_count": 0, "last_full_run": ""}))
else:
    data = json.loads(path.read_text())
    print(json.dumps({
        "merge_count": int(data.get("merge_count", 0)),
        "last_full_run": data.get("last_full_run") or "",
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
    "last_full_run": sys.argv[3],
}, indent=2) + "\n")
PY
}

cmd="${1:-decide}"
case "$cmd" in
  decide)
    state="$(read_state)"
    count="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["merge_count"])' <<<"$state")"
    last="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["last_full_run"])' <<<"$state")"
    count=$((count + 1))

    should_run=false
    reason=""

    if [[ "$FORCE_RUN" == "true" ]]; then
      should_run=true
      reason="force_run"
    elif (( MERGE_THRESHOLD < 1 )); then
      should_run=true
      reason="threshold_disabled"
    elif [[ -z "$last" ]]; then
      should_run=true
      reason="first_full_e2e"
    elif (( count % MERGE_THRESHOLD == 0 )); then
      should_run=true
      reason="merge_count_mod_${MERGE_THRESHOLD}"
    else
      should_run=false
      reason="cadence_skip_mod_${MERGE_THRESHOLD}"
    fi

    new_last="$last"
    if [[ "$should_run" == true ]]; then
      new_last="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    fi
    write_state "$count" "$new_last"

    echo "merge_count=$count"
    echo "should_run=$should_run"
    echo "reason=$reason"
    echo "threshold=$MERGE_THRESHOLD"
    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
      {
        echo "merge_count=$count"
        echo "should_run=$should_run"
        echo "reason=$reason"
        echo "threshold=$MERGE_THRESHOLD"
      } >>"$GITHUB_OUTPUT"
    fi
    ;;
  *)
    echo "usage: uat-full-e2e-cadence.sh decide" >&2
    exit 1
    ;;
esac
