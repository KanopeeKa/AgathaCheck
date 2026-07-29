#!/usr/bin/env bash
# Resolve the commit to promote after a green Pre-UAT E2E run.
#
# Auto path (workflow_run):
#   1. PRE_UAT_HEAD_SHA — github.event.workflow_run.head_sha (push commit tested)
#   2. PRE_UAT_RUN_ID — fetch run head_sha via API (job outputs are null cross-workflow)
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

commit_sha=""
source=""

if [[ -n "${PRE_UAT_HEAD_SHA:-}" ]]; then
  commit_sha="$PRE_UAT_HEAD_SHA"
  source="workflow_run_head_sha"
elif [[ -n "${PRE_UAT_RUN_ID:-}" ]]; then
  : "${GITHUB_TOKEN:?GITHUB_TOKEN required when PRE_UAT_RUN_ID is set}"
  repo="${GITHUB_REPOSITORY:?}"
  owner="${repo%%/*}"
  name="${repo##*/}"

  run_json="$(gh api "repos/${owner}/${name}/actions/runs/${PRE_UAT_RUN_ID}")"
  run_conclusion="$(printf '%s' "$run_json" | jq -r '.conclusion // empty')"
  run_head_sha="$(printf '%s' "$run_json" | jq -r '.head_sha // empty')"

  if [[ -n "$run_head_sha" ]]; then
    if [[ -n "$run_conclusion" && "$run_conclusion" != "success" ]]; then
      echo "::error::Pre-UAT run ${PRE_UAT_RUN_ID} conclusion is ${run_conclusion}" >&2
      exit 1
    fi
    commit_sha="$run_head_sha"
    source="pre_uat_run_api_head_sha"
  fi

  if [[ -z "$commit_sha" ]]; then
    job_test_sha="$(gh api "repos/${owner}/${name}/actions/runs/${PRE_UAT_RUN_ID}/jobs" \
      --paginate \
      --jq '.jobs[] | select(.name == "Resolve test commit") | .outputs.test_sha // empty' \
      | head -1)"
    if [[ -n "$job_test_sha" ]]; then
      commit_sha="$job_test_sha"
      source="resolve_test_commit_job_output"
    fi
  fi

  if [[ -z "$commit_sha" ]]; then
    echo "::error::Could not resolve tested SHA from Pre-UAT run ${PRE_UAT_RUN_ID}" >&2
    exit 1
  fi
else
  git fetch origin main --depth=1
  commit_sha="$(git rev-parse origin/main)"
  source="origin_main_head"
fi

emit_output commit_sha "$commit_sha"
echo "Promote target commit: ${commit_sha} (source=${source})"
