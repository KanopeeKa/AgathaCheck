#!/usr/bin/env bash
# Resolve deploy-prod trigger context (workflow_dispatch only).
#
# Environment:
#   EVENT_NAME — github.event_name
#   DISPATCH_REF, DISPATCH_UAT_RUN_ID — workflow_dispatch inputs
#   DEPLOY_PROOF_JOB — optional override; default uat.deploy_proof_job in .github/execute-plan.config.json
#   GITHUB_TOKEN, GITHUB_REPOSITORY
#
# Outputs to GITHUB_OUTPUT:
#   proceed (true|false), commit_sha, uat_run_id, target_ref, trigger_source
set -euo pipefail

EVENT_NAME="${EVENT_NAME:?EVENT_NAME is required}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

emit_output() {
  local key="$1"
  local value="$2"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf '%s=%s\n' "$key" "$value" >>"$GITHUB_OUTPUT"
  fi
  printf '%s=%s\n' "$key" "$value"
}

fail() {
  echo "::error::$1" >&2
  exit 1
}

case "$EVENT_NAME" in
  workflow_dispatch)
    DISPATCH_REF="${DISPATCH_REF:?DISPATCH_REF is required for workflow_dispatch}"
    DISPATCH_UAT_RUN_ID="${DISPATCH_UAT_RUN_ID:-}"
    if [[ -z "$DISPATCH_UAT_RUN_ID" ]]; then
      fail "uat_run_id is required for deploy-prod workflow_dispatch"
    fi

    COMMIT_SHA="$(
      UAT_RUN_ID="$DISPATCH_UAT_RUN_ID" \
      DISPATCH_REF="$DISPATCH_REF" \
      DEPLOY_PROOF_JOB="${DEPLOY_PROOF_JOB:-}" \
      GITHUB_REPOSITORY="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}" \
      GITHUB_TOKEN="${GITHUB_TOKEN:?GITHUB_TOKEN is required}" \
        node "$ROOT/scripts/ci/resolve-prod-dispatch-guard.js"
    )" || fail "deploy-prod dispatch guard refused ref '${DISPATCH_REF}' (uat_run_id=${DISPATCH_UAT_RUN_ID})"
    [[ "$COMMIT_SHA" =~ ^[0-9a-f]{40}$ ]] || fail "deploy-prod dispatch guard returned no commit SHA"

    emit_output proceed true
    emit_output commit_sha "$COMMIT_SHA"
    emit_output uat_run_id "$DISPATCH_UAT_RUN_ID"
    emit_output target_ref "$DISPATCH_REF"
    emit_output trigger_source workflow_dispatch
    ;;

  *)
    fail "Unsupported EVENT_NAME for deploy-prod: ${EVENT_NAME}"
    ;;
esac
