#!/usr/bin/env bash
# Resolve exactly one merged PR for a commit on main (promotion contract).
#
# Outputs to GITHUB_OUTPUT when set:
#   pr_number, promotion_status (ok|blocked), promotion_block_reason
#
# Environment:
#   COMMIT_SHA — commit to resolve (default: GITHUB_SHA)
#   GITHUB_REPOSITORY, GITHUB_TOKEN
set -euo pipefail

SHA="${COMMIT_SHA:-${GITHUB_SHA:-}}"
if [[ -z "$SHA" ]]; then
  echo "::error::COMMIT_SHA or GITHUB_SHA is required" >&2
  exit 1
fi

REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
TOKEN="${GITHUB_TOKEN:?GITHUB_TOKEN is required}"

emit_output() {
  local key="$1"
  local value="$2"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf '%s=%s\n' "$key" "$value" >>"$GITHUB_OUTPUT"
  fi
  printf '%s=%s\n' "$key" "$value"
}

block() {
  local reason="$1"
  local message="$2"
  echo "::error::${message}" >&2
  emit_output promotion_status blocked
  emit_output promotion_block_reason "$reason"
  exit 1
}

pulls_json="$(
  curl -fsS \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${REPO}/commits/${SHA}/pulls"
)"

count="$(printf '%s' "$pulls_json" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')"

if [[ "$count" -eq 0 ]]; then
  block no_pr "No associated pull request for commit ${SHA} — direct pushes to main are not promoted"
fi

if [[ "$count" -gt 1 ]]; then
  pr_list="$(printf '%s' "$pulls_json" | python3 -c 'import json,sys; print(", ".join(f"#{p[\"number\"]}" for p in json.load(sys.stdin)))')"
  block ambiguous_pr "Ambiguous promotion: ${count} PRs linked to ${SHA}: ${pr_list}"
fi

pr_number="$(printf '%s' "$pulls_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["number"])')"

emit_output pr_number "$pr_number"
emit_output promotion_status ok
emit_output promotion_block_reason ""
echo "Resolved PR #${pr_number} for commit ${SHA}"
