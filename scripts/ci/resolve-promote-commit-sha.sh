#!/usr/bin/env bash
# Resolve the commit to promote after a green Pre-UAT E2E run.
#
# Auto path (workflow_run): PRE_UAT_RUN_ID — read test_sha from the Pre-UAT
#   "Resolve test commit" job output (the SHA that run actually tested).
# Fallback: origin/main HEAD when PRE_UAT_RUN_ID is unset (manual / legacy).
#
# Outputs to GITHUB_OUTPUT:
#   commit_sha
set -euo pipefail

emit_output() {
  local key="$1"
  local value="$2"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf '%s=%s\n' "$key" "$value" >>"$GITHUB_OUTPUT"
  fi
  printf '%s=%s\n' "$key" "$value"
}

if [[ -n "${PRE_UAT_RUN_ID:-}" ]]; then
  : "${GITHUB_TOKEN:?GITHUB_TOKEN required when PRE_UAT_RUN_ID is set}"
  repo="${GITHUB_REPOSITORY:?}"
  owner="${repo%%/*}"
  name="${repo##*/}"

  test_sha="$(gh api "repos/${owner}/${name}/actions/runs/${PRE_UAT_RUN_ID}/jobs" \
    --paginate \
    --jq '.jobs[] | select(.name == "Resolve test commit") | .outputs.test_sha' \
    | head -1)"

  if [[ -z "$test_sha" ]]; then
    echo "::error::Could not read test_sha from Pre-UAT run ${PRE_UAT_RUN_ID}" >&2
    exit 1
  fi

  commit_sha="$test_sha"
else
  git fetch origin main --depth=1
  commit_sha="$(git rev-parse origin/main)"
fi

emit_output commit_sha "$commit_sha"
echo "Promote target commit: ${commit_sha}"
