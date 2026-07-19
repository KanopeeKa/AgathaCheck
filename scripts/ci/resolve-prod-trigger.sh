#!/usr/bin/env bash
# Resolve deploy-prod trigger context (workflow_dispatch or release).
#
# Environment:
#   EVENT_NAME — github.event_name
#   DISPATCH_REF, DISPATCH_UAT_RUN_ID — workflow_dispatch inputs
#   RELEASE_SHA — github.sha for release events
#   GITHUB_TOKEN, GITHUB_REPOSITORY
#
# Outputs to GITHUB_OUTPUT:
#   proceed (true|false), commit_sha, uat_run_id, target_ref, trigger_source
set -euo pipefail

EVENT_NAME="${EVENT_NAME:?EVENT_NAME is required}"

emit_output() {
  local key="$1"
  local value="$2"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf '%s=%s\n' "$key" "$value" >>"$GITHUB_OUTPUT"
  fi
  printf '%s=%s\n' "$key" "$value"
}

skip() {
  local reason="${1:-skipped}"
  emit_output proceed false
  emit_output skip_reason "$reason"
  echo "::notice::deploy-prod skipped (${reason})"
  exit 0
}

assert_prod_ready_success() {
  local uat_run_id="$1"
  local repo="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
  local prod_ready
  prod_ready="$(
    gh run view "$uat_run_id" --repo "$repo" --json jobs \
      --jq '.jobs[] | select(.name=="Prod ready") | .conclusion' | head -1
  )"
  if [[ "$prod_ready" != "success" ]]; then
    skip "prod_ready_not_success"
  fi
}

case "$EVENT_NAME" in
  workflow_dispatch)
    DISPATCH_REF="${DISPATCH_REF:?DISPATCH_REF is required for workflow_dispatch}"
    COMMIT_SHA="$(git rev-parse "${DISPATCH_REF}^{commit}")"
    if [[ -n "${DISPATCH_UAT_RUN_ID:-}" ]]; then
      assert_prod_ready_success "$DISPATCH_UAT_RUN_ID"
    fi
    emit_output proceed true
    emit_output commit_sha "$COMMIT_SHA"
    emit_output uat_run_id "${DISPATCH_UAT_RUN_ID:-}"
    emit_output target_ref "$DISPATCH_REF"
    emit_output trigger_source workflow_dispatch
    ;;

  release)
    COMMIT_SHA="${RELEASE_SHA:?RELEASE_SHA is required for release}"
    emit_output proceed true
    emit_output commit_sha "$COMMIT_SHA"
    emit_output uat_run_id ""
    emit_output target_ref "$COMMIT_SHA"
    emit_output trigger_source release
    ;;

  *)
    echo "::error::Unsupported EVENT_NAME: ${EVENT_NAME}" >&2
    exit 1
    ;;
esac
