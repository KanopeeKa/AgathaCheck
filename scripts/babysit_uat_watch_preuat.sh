#!/usr/bin/env bash
# Watch pre-uat-e2e.yml for a specific merge commit SHA (the PR you merged).
#
# Usage:
#   ./scripts/babysit_uat_watch_preuat.sh <merge_sha> [--json] [--timeout-min 90]
#
# Exit 0 = Pre-UAT gate green for merge_sha
# Exit 1 = failed (prints failed shard indices when detectable)
# Exit 2 = timeout / run not found yet
set -euo pipefail

MERGE_SHA="${1:?usage: babysit_uat_watch_preuat.sh <merge_sha> [--json] [--timeout-min N]}"
shift
JSON=false
TIMEOUT_MIN=90
POLL_SEC=30

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON=true; shift ;;
    --timeout-min) TIMEOUT_MIN="${2:?}"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

MERGE_SHA="${MERGE_SHA#"${MERGE_SHA%%[![:space:]]*}"}"
MERGE_SHA="${MERGE_SHA%"${MERGE_SHA##*[![:space:]]}"}"

deadline=$((SECONDS + TIMEOUT_MIN * 60))

find_run() {
  gh run list \
    --workflow=pre-uat-e2e.yml \
    --branch=main \
    --limit=30 \
    --json databaseId,headSha,status,conclusion,createdAt,url \
    2>/dev/null | python3 -c "
import json, sys
target = sys.argv[1].lower()
runs = json.load(sys.stdin)
for r in runs:
    if (r.get('headSha') or '').lower().startswith(target[:7]) or (r.get('headSha') or '').lower() == target:
        print(json.dumps(r))
        break
" "$MERGE_SHA"
}

failed_shards() {
  local run_id="$1"
  gh run view "$run_id" --json jobs 2>/dev/null | python3 -c "
import json, sys, re
data = json.load(sys.stdin)
failed = []
for j in data.get('jobs', []):
    if j.get('conclusion') != 'failure':
        continue
    name = j.get('name') or ''
    m = re.search(r'shard[\\s/_-]*(\\d+)', name, re.I)
    if m:
        failed.append(int(m.group(1)))
    elif 'Full localhost E2E' in name or 'e2e-full' in name.lower():
        failed.append(-1)
print(json.dumps(sorted(set(failed))))
"
}

while [[ $SECONDS -lt $deadline ]]; do
  run_json="$(find_run || true)"
  if [[ -z "$run_json" ]]; then
    sleep "$POLL_SEC"
    continue
  fi

  status="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["status"])' <<<"$run_json")"
  conclusion="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("conclusion") or "")' <<<"$run_json")"
  run_id="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["databaseId"])' <<<"$run_json")"
  url="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["url"])' <<<"$run_json")"

  if [[ "$status" == "completed" ]]; then
    if [[ "$conclusion" == "success" ]]; then
      if $JSON; then
        python3 -c "import json; print(json.dumps({'status':'success','run_id':$run_id,'url':'$url','merge_sha':'$MERGE_SHA'}))"
      else
        echo "Pre-UAT E2E passed for ${MERGE_SHA:0:7} (run $run_id)"
        echo "$url"
      fi
      exit 0
    fi

    shards="$(failed_shards "$run_id" || echo '[]')"
    if $JSON; then
      python3 -c "import json; print(json.dumps({'status':'failure','run_id':$run_id,'url':'$url','merge_sha':'$MERGE_SHA','failed_shards':json.loads('''$shards''')}))" 2>/dev/null || \
        echo "{\"status\":\"failure\",\"run_id\":$run_id,\"url\":\"$url\",\"merge_sha\":\"$MERGE_SHA\",\"failed_shards\":$shards}"
    else
      echo "Pre-UAT E2E failed for ${MERGE_SHA:0:7} (run $run_id)" >&2
      echo "failed_shards=$shards" >&2
      echo "$url" >&2
    fi
    exit 1
  fi

  sleep "$POLL_SEC"
done

if $JSON; then
  echo "{\"status\":\"timeout\",\"merge_sha\":\"$MERGE_SHA\"}"
else
  echo "timeout waiting for pre-uat-e2e on ${MERGE_SHA:0:7}" >&2
fi
exit 2
