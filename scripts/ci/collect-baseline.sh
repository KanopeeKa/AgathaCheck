#!/usr/bin/env bash
# Collect GitHub Actions baseline metrics for CI/CD improvement tracking.
# Usage: scripts/ci/collect-baseline.sh [--limit N]
# Requires: gh CLI authenticated for the target repository.
set -euo pipefail

LIMIT="${1:-20}"
if [[ "${1:-}" == "--limit" ]]; then
  LIMIT="${2:-20}"
fi

REPO="${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)}"
if [[ -z "$REPO" ]]; then
  echo "Could not resolve repository; set GITHUB_REPOSITORY or run from a gh-authenticated clone." >&2
  exit 1
fi

duration_minutes() {
  local created="$1" updated="$2"
  python3 - "$created" "$updated" <<'PY'
import sys
from datetime import datetime

def parse(ts: str) -> datetime:
    return datetime.fromisoformat(ts.replace("Z", "+00:00"))

created, updated = parse(sys.argv[1]), parse(sys.argv[2])
print(max(0, int((updated - created).total_seconds() // 60)))
PY
}

median_p95() {
  python3 - <<'PY'
import sys

vals = sorted(int(x) for x in sys.stdin.read().split() if x.strip())
if not vals:
    print("n/a n/a 0")
    raise SystemExit(0)
n = len(vals)
mid = n // 2
median = vals[mid] if n % 2 else (vals[mid - 1] + vals[mid]) // 2
idx = max(0, min(len(vals) - 1, int(0.95 * (len(vals) - 1))))
print(median, vals[idx], n)
PY
}

summarize_workflow() {
  local workflow_file="$1"
  local workflow_name="$2"
  local runs_json
  runs_json="$(gh run list --repo "$REPO" --workflow="$workflow_file" --limit "$LIMIT" --json databaseId,conclusion,createdAt,updatedAt 2>/dev/null || echo '[]')"
  local count
  count="$(python3 -c 'import json,sys; print(len(json.load(sys.stdin)))' <<<"$runs_json")"
  if [[ "$count" -eq 0 ]]; then
    echo "| $workflow_name | \`$workflow_file\` | 0 | n/a | n/a | n/a | no runs in window |"
    return
  fi

  local durations="" failures=0 cancelled=0 success=0 latest_failed_id=""
  while IFS=$'\t' read -r id conclusion created updated; do
    case "$conclusion" in
      success) success=$((success + 1)) ;;
      failure)
        failures=$((failures + 1))
        if [[ -z "$latest_failed_id" && -n "$id" ]]; then
          latest_failed_id="$id"
        fi
        ;;
      cancelled) cancelled=$((cancelled + 1)) ;;
    esac
    if [[ -n "$created" && -n "$updated" ]]; then
      durations+="$(duration_minutes "$created" "$updated") "
    fi
  done < <(python3 -c '
import json, sys
for r in json.loads(sys.argv[1]):
    print("\t".join([
        str(r.get("databaseId", "")),
        r.get("conclusion") or "in_progress",
        r.get("createdAt") or "",
        r.get("updatedAt") or "",
    ]))
' "$runs_json")

  read -r median p95 _ <<<"$(printf '%s' "$durations" | median_p95)"
  local fail_rate
  fail_rate="$(python3 -c 'import sys; s,f,c=map(int,sys.argv[1:]); t=s+f+c; print(f"{(f/t*100):.0f}%" if t else "n/a")' "$success" "$failures" "$cancelled")"
  local top_fail="n/a"
  if [[ -n "$latest_failed_id" ]]; then
    top_fail="$(gh run view "$latest_failed_id" --repo "$REPO" --json jobs --jq '[.jobs[] | select(.conclusion=="failure") | .name] | join(", ")' 2>/dev/null || true)"
    [[ -z "$top_fail" ]] && top_fail="(see latest failed run jobs)"
  fi
  echo "| $workflow_name | \`$workflow_file\` | $count | ${median}m | ${p95}m | $fail_rate | ${top_fail:-n/a} |"
}

echo "# CI/CD baseline snapshot (generated)"
echo
echo "- **Repository:** $REPO"
echo "- **Captured at (UTC):** $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "- **Window:** last $LIMIT runs per workflow"
echo "- **Generator:** \`scripts/ci/collect-baseline.sh\`"
echo
echo "## Workflow duration summary"
echo
echo "| Workflow | File | Runs | Median | p95 | Failure rate | Sample failing jobs (latest failed run) |"
echo "|----------|------|------|--------|-----|--------------|-----------------------------------------|"
summarize_workflow "ci.yml" "CI"
summarize_workflow "deploy-uat.yml" "Deploy UAT (uat.agathatrack.com)"
summarize_workflow "deploy-prod.yml" "Deploy Production (agathatrack.com)"
summarize_workflow "e2e.yml" "E2E (Playwright)"
