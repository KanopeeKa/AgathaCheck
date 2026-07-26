#!/usr/bin/env bash
# Assert UAT release gates passed before PROD promotion.
# Deploy-uat is light: deploy + HTTP smoke only. Full E2E runs in pre-uat-e2e.yml.
# See docs/e2e/uat-deploy-tiers.md
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
BUILD_RESULT="${BUILD_RESULT:-}"
SMOKE_FAILURE_KIND="${SMOKE_FAILURE_KIND:-}"
DEPLOY_REF="${DEPLOY_REF:-}"
GITHUB_SHA="${GITHUB_SHA:-}"
GITHUB_RUN_ID="${GITHUB_RUN_ID:-}"
MIGRATE_STATUS_COLLECTED="${MIGRATE_STATUS_COLLECTED:-false}"
MIGRATE_PENDING_COUNT="${MIGRATE_PENDING_COUNT:-unknown}"
UAT_AUTO_MIGRATE="${UAT_AUTO_MIGRATE:-false}"
GITHUB_OUTPUT="${GITHUB_OUTPUT:-}"

emit_output() {
  local key="$1"
  local value="$2"
  if [[ -n "$GITHUB_OUTPUT" ]]; then
    printf '%s=%s\n' "$key" "$value" >>"$GITHUB_OUTPUT"
  fi
}

failed=0
summary_tmp="$(mktemp)"
trap 'rm -f "$summary_tmp"' EXIT
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
    "smoke (HTTP)|${SMOKE_RESULT}"; do
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

gate_failure_class="none"
if [[ "$failed" -ne 0 ]]; then
  gate_failure_class="infra_only"
  if [[ -n "$BUILD_RESULT" && "$BUILD_RESULT" != "success" ]]; then
    gate_failure_class="code"
  elif [[ "$migrate_gate" == "fail" ]]; then
    gate_failure_class="code"
  elif [[ "$DEPLOY_RESULT" == "success" && "$SMOKE_RESULT" != "success" ]]; then
    case "$SMOKE_FAILURE_KIND" in
      waf | apache_404 | directory_listing | flutter_spa) ;;
      *) gate_failure_class="code" ;;
    esac
  fi
fi
emit_output "gate_failure_class" "$gate_failure_class"
echo "gate_failure_class=${gate_failure_class}"

if [[ "$failed" -ne 0 ]]; then
  echo "::error::Not all UAT gates passed — do not deploy to PROD."
  exit 1
fi

echo "All UAT gates passed. Safe to deploy commit ${GITHUB_SHA} to PROD."
echo "::notice::Configure GitHub Environment PROD to require check: Deploy UAT / Prod ready"
