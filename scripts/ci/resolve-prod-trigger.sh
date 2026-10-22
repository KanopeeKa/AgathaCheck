#!/usr/bin/env bash
# Resolve deploy-prod trigger context (workflow_dispatch only).
#
# Environment:
#   EVENT_NAME — github.event_name
#   DISPATCH_REF, DISPATCH_UAT_RUN_ID — workflow_dispatch inputs
#   DEPLOY_PROOF_JOB — optional; default Prod ready (see execute-plan.config.json)
#   GITHUB_TOKEN, GITHUB_REPOSITORY
#
# Outputs to GITHUB_OUTPUT:
#   proceed (true|false), commit_sha, uat_run_id, target_ref, trigger_source
set -euo pipefail

EVENT_NAME="${EVENT_NAME:?EVENT_NAME is required}"
DEPLOY_PROOF_JOB="${DEPLOY_PROOF_JOB:-Prod ready}"
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

resolve_remote_ref_to_sha() {
  local ref="$1"
  local repo="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
  local sha

  ref="${ref#refs/heads/}"
  ref="${ref#refs/tags/}"

  if ! sha="$(gh api "repos/${repo}/commits/${ref}" --jq .sha 2>/dev/null)"; then
    fail "Could not resolve git ref '${ref}' on ${repo}"
  fi
  if [[ -z "$sha" || "$sha" == "null" ]]; then
    fail "Could not resolve git ref '${ref}' on ${repo}"
  fi
  printf '%s\n' "$sha"
}

case "$EVENT_NAME" in
  workflow_dispatch)
    DISPATCH_REF="${DISPATCH_REF:?DISPATCH_REF is required for workflow_dispatch}"
    DISPATCH_UAT_RUN_ID="${DISPATCH_UAT_RUN_ID:-}"
    if [[ -z "$DISPATCH_UAT_RUN_ID" ]]; then
      fail "uat_run_id is required for deploy-prod workflow_dispatch"
    fi

    COMMIT_SHA="$(resolve_remote_ref_to_sha "$DISPATCH_REF")"

    UAT_RUN_ID="$DISPATCH_UAT_RUN_ID" \
    DISPATCH_REF="$DISPATCH_REF" \
    REQUESTED_COMMIT_SHA="$COMMIT_SHA" \
    DEPLOY_PROOF_JOB="$DEPLOY_PROOF_JOB" \
    GITHUB_REPOSITORY="${GITHUB_REPOSITORY:?}" \
    GITHUB_TOKEN="${GITHUB_TOKEN:?}" \
      node "$ROOT/scripts/ci/resolve-prod-dispatch-guard.js"

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
