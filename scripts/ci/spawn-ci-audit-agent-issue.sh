#!/usr/bin/env bash
# Open a GitHub issue to spawn agent-dispatch on CI full-audit failure.
set -euo pipefail

SHA="${AUDIT_SHA:-${GITHUB_SHA:-unknown}}"
RUN_URL="${AUDIT_RUN_URL:-}"
SUMMARY="${AUDIT_SUMMARY:-CI full audit failed on main}"

REPO="${GITHUB_REPOSITORY:?}"
title="ci-audit: full suite failed on main@${SHA:0:7}"
body="$(cat <<EOF
## CI full audit failure (non-blocking advisory)

**Commit:** \`${SHA}\`
**Workflow run:** ${RUN_URL:-n/a}

${SUMMARY}

### Agent task

1. Check out \`${SHA}\` on branch \`cursor/ci-audit-fix-${SHA:0:7}-b697\`
2. Reproduce failing gate(s) locally with \`./scripts/pre-push.sh\`
3. Open PR to \`main\` with minimal fix — do **not** weaken gates

<!-- ci-audit-agent -->
EOF
)"

ensure_label() {
  local name="$1" color="$2" desc="$3"
  gh label list --json name --jq '.[].name' | grep -Fxq "$name" \
    || gh label create "$name" --color "$color" --description "$desc"
}

ensure_label "ci-audit" "B60205" "CI full audit failure — agent may auto-fix"
ensure_label "agent-approved" "0E8A16" "Passed deterministic triage"

existing="$(gh issue list --state open --label ci-audit --search "in:title ${SHA:0:7}" --json number --jq '.[0].number' 2>/dev/null || true)"
if [[ -n "$existing" && "$existing" != "null" ]]; then
  echo "Issue already open: #${existing}"
  exit 0
fi

gh issue create --title "$title" --body "$body" --label ci-audit --label agent-approved
