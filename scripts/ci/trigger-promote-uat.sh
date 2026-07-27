#!/usr/bin/env bash
# Dispatch promote-uat.yml after agent localhost E2E is green.
#
# Usage:
#   ./scripts/ci/trigger-promote-uat.sh --commit <sha> --pr <n>
#
# Requires: gh CLI, repo write permission for workflow_dispatch.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
COMMIT_SHA=""
PR_NUMBER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --commit) COMMIT_SHA="${2:?}"; shift 2 ;;
    --pr) PR_NUMBER="${2:?}"; shift 2 ;;
    -h|--help)
      echo "usage: trigger-promote-uat.sh --commit <sha> --pr <n>"
      exit 0
      ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$COMMIT_SHA" || -z "$PR_NUMBER" ]]; then
  echo "trigger-promote-uat: --commit and --pr are required" >&2
  exit 1
fi

WORKFLOW_FILE="${ROOT}/.github/workflows/promote-uat.yml"
if [[ ! -f "$WORKFLOW_FILE" ]]; then
  echo "trigger-promote-uat: missing ${WORKFLOW_FILE}" >&2
  exit 1
fi

echo "==> Dispatching Promote UAT for commit ${COMMIT_SHA:0:7} (PR #${PR_NUMBER})"
gh workflow run "Promote UAT (tag on merge to main)" \
  -f "commit_sha=${COMMIT_SHA}" \
  -f "pr_number=${PR_NUMBER}"

echo "==> Waiting for promote run to appear (up to 90s)"
for _ in $(seq 1 18); do
  run_id="$(gh run list --workflow=promote-uat.yml --limit 5 --json databaseId,event,status,createdAt \
    -q '[.[] | select(.event=="workflow_dispatch")][0].databaseId' 2>/dev/null || true)"
  if [[ -n "$run_id" && "$run_id" != "null" ]]; then
    echo "promote_run_id=${run_id}"
    echo "promote_run_url=$(gh run view "$run_id" --json url -q .url)"
    exit 0
  fi
  sleep 5
done

echo "::warning::Could not resolve promote workflow run id — check Actions UI" >&2
exit 0
