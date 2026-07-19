#!/usr/bin/env bash
# Dispatch deploy-prod only after UAT Prod ready succeeded.
#
# Environment:
#   DEPLOY_REF — UAT tag that was deployed (e.g. uat-260718-220)
#   UAT_RUN_ID — deploy-uat workflow run id (provenance for artifact promotion)
#   GITHUB_REPOSITORY, GITHUB_TOKEN
set -euo pipefail

DEPLOY_REF="${DEPLOY_REF:?DEPLOY_REF is required}"
UAT_RUN_ID="${UAT_RUN_ID:?UAT_RUN_ID is required}"
REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
TOKEN="${GITHUB_TOKEN:?GITHUB_TOKEN is required}"

export GH_TOKEN="$TOKEN"

if ! gh workflow run deploy-prod.yml \
  --repo "$REPO" \
  --ref main \
  -f "ref=${DEPLOY_REF}" \
  -f "uat_run_id=${UAT_RUN_ID}"; then
  echo "::error::Failed to dispatch deploy-prod workflow for UAT run ${UAT_RUN_ID}" >&2
  exit 1
fi

echo "::notice::Dispatched deploy-prod for ${DEPLOY_REF} (uat_run_id=${UAT_RUN_ID})"
