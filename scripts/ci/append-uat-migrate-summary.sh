#!/usr/bin/env bash
# Write UAT migration status to the Actions job summary (Phase 5a).
#
# Environment:
#   MIGRATE_STATUS_COLLECTED — true|false
#   MIGRATE_PENDING_COUNT — integer or unknown
#   MIGRATE_AUTO_APPLIED — true|false
#   UAT_AUTO_MIGRATE — repo/environment variable value
#   UAT_SSH_ENABLED — whether SSH path was configured
set -euo pipefail

MIGRATE_STATUS_COLLECTED="${MIGRATE_STATUS_COLLECTED:-false}"
MIGRATE_PENDING_COUNT="${MIGRATE_PENDING_COUNT:-unknown}"
MIGRATE_AUTO_APPLIED="${MIGRATE_AUTO_APPLIED:-false}"
UAT_AUTO_MIGRATE="${UAT_AUTO_MIGRATE:-unset}"
UAT_SSH_ENABLED="${UAT_SSH_ENABLED:-false}"

{
  echo "## UAT database migrations"
  echo
  echo "| Field | Value |"
  echo "|-------|-------|"
  echo "| \`UAT_AUTO_MIGRATE\` | \`${UAT_AUTO_MIGRATE}\` |"
  echo "| \`UAT_SSH_ENABLED\` | \`${UAT_SSH_ENABLED}\` |"
  echo "| Status collected (live DB) | \`${MIGRATE_STATUS_COLLECTED}\` |"
  echo "| Pending count | \`${MIGRATE_PENDING_COUNT}\` |"
  echo "| Auto migrate applied | \`${MIGRATE_AUTO_APPLIED}\` |"
  echo

  if [[ "${MIGRATE_STATUS_COLLECTED}" == "true" ]]; then
    if [[ "${MIGRATE_PENDING_COUNT}" =~ ^[0-9]+$ && "${MIGRATE_PENDING_COUNT}" -gt 0 ]]; then
      echo "Pending migrations remain on UAT. \`prod-ready\` will fail unless \`UAT_AUTO_MIGRATE=true\` applied them."
    else
      echo "Live migration status OK — no pending migrations reported."
    fi
  else
    echo "Live DB migration status was **not** collected (SSH deploy did not complete or \`migrate.js status\` failed)."
    echo "FTP-only deploys still require manual SQL on UAT Postgres before live E2E."
  fi
} >>"${GITHUB_STEP_SUMMARY:-/dev/stdout}"
