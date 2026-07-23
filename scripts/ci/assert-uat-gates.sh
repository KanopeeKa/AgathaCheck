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
  local name="$1"
  local result="$2"
  if [[ "$result" != "success" ]]; then
    return 1
  fi
  return 0
}

DEPLOY_RESULT="${DEPLOY_RESULT:-}"
SMOKE_RESULT="${SMOKE_RESULT:-}"
LIVE_SMOKE_RESULT="${LIVE_SMOKE_RESULT:-}"
FULL_E2E_RESULT="${FULL_E2E_RESULT:-}"
UAT_FULL_E2E_CADENCE_SKIP="${UAT_FULL_E2E_CADENCE_SKIP:-false}"
UAT_FULL_E2E_CADENCE_REASON="${UAT_FULL_E2E_CADENCE_REASON:-}"
DEPLOY_REF="${DEPLOY_REF:-}"
GITHUB_SHA="${GITHUB_SHA:-}"
GITHUB_RUN_ID="${GITHUB_RUN_ID:-}"
MIGRATE_STATUS_COLLECTED="${MIGRATE_STATUS_COLLECTED:-false}"
MIGRATE_PENDING_COUNT="${MIGRATE_PENDING_COUNT:-unknown}"
UAT_AUTO_MIGRATE="${UAT_AUTO_MIGRATE:-false}"

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
    "uat-e2e-smoke (live @smoke)|${LIVE_SMOKE_RESULT}"; do
    label="${row%%|*}"
    result="${row#*|}"
    if require_success "$label" "$result"; then
      printf '| %s | `%s` | yes | yes |\n' "$label" "$result"
    else
      echo "::error title=UAT gate failed::$label concluded with '$result' (expected success)" >&3
      printf '| %s | `%s` | yes | no |\n' "$label" "$result"
      failed=1
    fi
  done

  if [[ "${FULL_E2E_RESULT}" == "skipped" && "${SMOKE_RESULT}" != "success" ]]; then
    printf '| uat-e2e-full (localhost) | `skipped (smoke failed)` | no | n/a |\n'
  elif [[ "${FULL_E2E_RESULT}" == "skipped" && "${UAT_FULL_E2E_CADENCE_SKIP}" == "true" ]]; then
    echo "::notice::Full localhost E2E skipped by cadence (${UAT_FULL_E2E_CADENCE_REASON:-n/a}) — HTTP + live smoke gates still required." >&3
    printf '| uat-e2e-full (localhost) | `skipped (%s)` | cadence | yes |\n' "${UAT_FULL_E2E_CADENCE_REASON:-cadence}"
  elif require_success "uat-e2e-full (localhost)" "${FULL_E2E_RESULT}"; then
    printf '| uat-e2e-full (localhost) | `%s` | yes | yes |\n' "${FULL_E2E_RESULT}"
  else
    echo "::error title=UAT gate failed::uat-e2e-full (localhost) concluded with '${FULL_E2E_RESULT}' (expected success)" >&3
    printf '| uat-e2e-full (localhost) | `%s` | yes | no |\n' "${FULL_E2E_RESULT}"
    failed=1
  fi

  migrate_gate="skipped"
  if [[ "${MIGRATE_STATUS_COLLECTED}" == "true" ]]; then
    if [[ "${MIGRATE_PENDING_COUNT}" =~ ^[0-9]+$ ]]; then
      if [[ "${MIGRATE_PENDING_COUNT}" -eq 0 ]]; then
        migrate_gate="pass"
        printf '| migrations (live status) | `%s pending` | yes | yes |\n' "${MIGRATE_PENDING_COUNT}"
      elif [[ "${UAT_AUTO_MIGRATE}" == "true" ]]; then
        migrate_gate="fail"
        echo "::error title=UAT migrations still pending::${MIGRATE_PENDING_COUNT} pending after UAT_AUTO_MIGRATE=true" >&3
        printf '| migrations (live status) | `%s pending after auto-migrate` | yes | no |\n' "${MIGRATE_PENDING_COUNT}"
        failed=1
      else
        migrate_gate="fail"
        echo "::error title=UAT migrations pending::${MIGRATE_PENDING_COUNT} pending — set UAT_AUTO_MIGRATE=true or apply SQL manually" >&3
        printf '| migrations (live status) | `%s pending` | yes | no |\n' "${MIGRATE_PENDING_COUNT}"
        failed=1
      fi
    else
      migrate_gate="fail"
      echo "::error title=UAT migration status invalid::migrate_pending_count='${MIGRATE_PENDING_COUNT}'" >&3
      printf '| migrations (live status) | `invalid pending count` | yes | no |\n'
      failed=1
    fi
  else
    echo "::notice::Migration gate skipped — live status not collected (SSH/migrate.js status unavailable)." >&3
    printf '| migrations (live status) | `not collected` | no | n/a |\n'
  fi
  echo
} >"$summary_tmp"

append_summary <"$summary_tmp"

if [[ "$failed" -ne 0 ]]; then
  echo "::error::Not all UAT gates passed — do not deploy to PROD."
  exit 1
fi

echo "All UAT gates passed. Safe to deploy commit ${GITHUB_SHA} to PROD."
echo "::notice::Configure GitHub Environment PROD to require check: Deploy UAT / Prod ready"
