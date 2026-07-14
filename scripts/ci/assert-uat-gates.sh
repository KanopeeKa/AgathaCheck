#!/usr/bin/env bash
# Assert all UAT release gates passed before PROD promotion.
# Called from deploy-uat.yml prod-ready job. Emits a single summary table.
set -euo pipefail

SUMMARY_FILE="${GITHUB_STEP_SUMMARY:-}"

append_summary() {
  if [[ -n "$SUMMARY_FILE" ]]; then
    cat >>"$SUMMARY_FILE"
  else
    cat
  fi
}

require_success() {
  local result="$1"
  if [[ "$result" != "success" ]]; then
    return 1
  fi
  return 0
}

DEPLOY_RESULT="${DEPLOY_RESULT:-}"
SMOKE_RESULT="${SMOKE_RESULT:-}"
LIVE_SMOKE_RESULT="${LIVE_SMOKE_RESULT:-}"
FULL_E2E_RESULT="${FULL_E2E_RESULT:-}"
DEPLOY_REF="${DEPLOY_REF:-}"
GITHUB_SHA="${GITHUB_SHA:-}"
GITHUB_RUN_ID="${GITHUB_RUN_ID:-}"

failed=0
summary_tmp="$(mktemp)"
trap 'rm -f "$summary_tmp"' EXIT
# Preserve workflow-command output on the original stdout outside the summary capture block.
exec 3>&1

{
  echo "## UAT prod-ready gate summary"
  echo
  echo "| Field | Value |"
  echo "|-------|-------|"
  echo "| Deploy ref | \`${DEPLOY_REF:-unknown}\` |"
  echo "| Workflow SHA | \`${GITHUB_SHA:-unknown}\` |"
  echo "| Workflow run | ${GITHUB_RUN_ID:-unknown} |"
  echo
  echo "| Gate | Result | Required | Pass |"
  echo "|------|--------|----------|------|"

  for row in \
    "deploy|${DEPLOY_RESULT}" \
    "smoke (HTTP)|${SMOKE_RESULT}" \
    "uat-e2e-smoke (live @smoke)|${LIVE_SMOKE_RESULT}" \
    "uat-e2e-full (localhost)|${FULL_E2E_RESULT}"; do
    label="${row%%|*}"
    result="${row#*|}"
    if require_success "$result"; then
      printf '| %s | `%s` | yes | yes |\n' "$label" "$result"
    else
      echo "::error title=UAT gate failed::$label concluded with '$result' (expected success)" >&3
      printf '| %s | `%s` | yes | no |\n' "$label" "$result"
      failed=1
    fi
  done
  echo
} >"$summary_tmp"

append_summary <"$summary_tmp"

if [[ "$failed" -ne 0 ]]; then
  echo "::error::Not all UAT gates passed — do not deploy to PROD."
  exit 1
fi

echo "All UAT gates passed. Safe to deploy commit ${GITHUB_SHA} to PROD."
echo "::notice::Configure GitHub Environment PROD to require check: Deploy UAT / Prod ready"
