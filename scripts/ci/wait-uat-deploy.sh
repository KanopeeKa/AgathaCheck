#!/usr/bin/env bash
# Poll deploy-uat until prod-ready succeeds or timeout.
#
# Usage:
#   ./scripts/ci/wait-uat-deploy.sh --tag uat-260727-481
#   ./scripts/ci/wait-uat-deploy.sh --promote-run <run_id>
#
# Outputs: deploy_run_url on success; exit 1 on failure/timeout.
set -euo pipefail

DEPLOY_TAG=""
PROMOTE_RUN_ID=""
TIMEOUT_SEC="${UAT_DEPLOY_WAIT_TIMEOUT_SEC:-3600}"
POLL_SEC="${UAT_DEPLOY_POLL_SEC:-30}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag) DEPLOY_TAG="${2:?}"; shift 2 ;;
    --promote-run) PROMOTE_RUN_ID="${2:?}"; shift 2 ;;
    --timeout) TIMEOUT_SEC="${2:?}"; shift 2 ;;
    -h|--help)
      echo "usage: wait-uat-deploy.sh --tag <uat-tag> [--timeout sec]"
      echo "       wait-uat-deploy.sh --promote-run <id> [--timeout sec]"
      exit 0
      ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$DEPLOY_TAG" && -z "$PROMOTE_RUN_ID" ]]; then
  echo "wait-uat-deploy: --tag or --promote-run required" >&2
  exit 1
fi

deadline=$(( $(date +%s) + TIMEOUT_SEC ))

wait_for_promote() {
  local run_id="$1"
  echo "==> Waiting for promote run ${run_id}"
  while [[ $(date +%s) -lt $deadline ]]; do
    conclusion="$(gh run view "$run_id" --json conclusion -q .conclusion 2>/dev/null || echo "")"
    if [[ "$conclusion" == "success" ]]; then
      return 0
    fi
    if [[ -n "$conclusion" && "$conclusion" != "null" && "$conclusion" != "" ]]; then
      echo "::error::promote-uat concluded: ${conclusion}" >&2
      return 1
    fi
    sleep "$POLL_SEC"
  done
  echo "::error::promote-uat timed out after ${TIMEOUT_SEC}s" >&2
  return 1
}

find_deploy_run_for_tag() {
  local tag="$1"
  gh run list --workflow=deploy-uat.yml --limit 20 --json databaseId,headBranch,status,conclusion,createdAt \
    -q "[.[] | select(.headBranch==\"${tag}\")][0].databaseId" 2>/dev/null || true
}

find_deploy_after_promote() {
  local promote_id="$1"
  # deploy-uat triggered via workflow_run from promote
  sleep 15
  gh run list --workflow=deploy-uat.yml --limit 10 --json databaseId,event,status,conclusion,createdAt \
    -q '[.[] | select(.event=="workflow_run")][0].databaseId' 2>/dev/null || true
}

if [[ -n "$PROMOTE_RUN_ID" ]]; then
  wait_for_promote "$PROMOTE_RUN_ID" || exit 1
  DEPLOY_RUN_ID="$(find_deploy_after_promote "$PROMOTE_RUN_ID")"
else
  bash "$(cd "$(dirname "$0")" && pwd)/assert-uat-tag.sh" "$DEPLOY_TAG"
  echo "==> Waiting for deploy-uat run for tag ${DEPLOY_TAG}"
  DEPLOY_RUN_ID=""
  while [[ $(date +%s) -lt $deadline ]]; do
    DEPLOY_RUN_ID="$(find_deploy_run_for_tag "$DEPLOY_TAG")"
    if [[ -n "$DEPLOY_RUN_ID" && "$DEPLOY_RUN_ID" != "null" ]]; then
      break
    fi
    sleep "$POLL_SEC"
  done
fi

if [[ -z "$DEPLOY_RUN_ID" || "$DEPLOY_RUN_ID" == "null" ]]; then
  echo "::error::No deploy-uat run found for ${DEPLOY_TAG:-promote ${PROMOTE_RUN_ID}}" >&2
  exit 1
fi

echo "deploy_run_id=${DEPLOY_RUN_ID}"
echo "deploy_run_url=$(gh run view "$DEPLOY_RUN_ID" --json url -q .url)"

echo "==> Waiting for deploy-uat conclusion (prod-ready)"
while [[ $(date +%s) -lt $deadline ]]; do
  status_json="$(gh run view "$DEPLOY_RUN_ID" --json status,conclusion 2>/dev/null || echo '{}')"
  status="$(echo "$status_json" | jq -r .status)"
  conclusion="$(echo "$status_json" | jq -r .conclusion)"
  if [[ "$status" == "completed" ]]; then
    if [[ "$conclusion" == "success" ]]; then
      echo "UAT deploy prod-ready green"
      exit 0
    fi
    echo "::error::deploy-uat concluded: ${conclusion}" >&2
    gh run view "$DEPLOY_RUN_ID" --log-failed 2>/dev/null | tail -80 || true
    exit 1
  fi
  sleep "$POLL_SEC"
done

echo "::error::deploy-uat timed out after ${TIMEOUT_SEC}s" >&2
exit 1
