#!/usr/bin/env bash
# Resolve deploy-uat trigger context (tag push, workflow_run from promote-uat, dispatch).
#
# GitHub does not fire tag-push workflows for refs created with the default
# GITHUB_TOKEN (see promotion-contract.md). workflow_run from promote-uat is the
# primary auto-deploy path after merge to main.
#
# Environment:
#   EVENT_NAME — github.event_name
#   WORKFLOW_RUN_ID, WORKFLOW_RUN_CONCLUSION, WORKFLOW_RUN_HEAD_SHA — workflow_run
#   DISPATCH_REF — workflow_dispatch inputs.deploy_ref
#   GITHUB_REF_NAME — github.ref_name (tag push)
#   GITHUB_REPOSITORY, GITHUB_TOKEN
#
# Outputs to GITHUB_OUTPUT:
#   proceed (true|false), deploy_ref, trigger_source, promote_run_id
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
  echo "::notice::deploy-uat skipped (${reason})"
  exit 0
}

find_uat_tag_for_commit() {
  local commit_sha="$1"
  local repo="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
  local token="${GITHUB_TOKEN:?GITHUB_TOKEN is required}"

  python3 - "$commit_sha" "$repo" "$token" <<'PY'
import json
import sys
import urllib.request

commit_sha, repo, token = sys.argv[1:4]

def api(path: str):
    req = urllib.request.Request(
        f"https://api.github.com{path}",
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
        },
    )
    with urllib.request.urlopen(req) as resp:
        return json.load(resp)

def tag_commit_sha(tag_name: str) -> str:
    ref = api(f"/repos/{repo}/git/ref/tags/{tag_name}")
    obj = ref["object"]
    if obj["type"] == "commit":
        return obj["sha"]
    tag_obj = api(f"/repos/{repo}/git/tags/{obj['sha']}")
    return tag_obj["object"]["sha"]

refs = api(f"/repos/{repo}/git/matching-refs/tags/uat-")
for item in refs:
    ref = item.get("ref", "")
    if not ref.startswith("refs/tags/uat-"):
        continue
    tag = ref.removeprefix("refs/tags/")
    parts = tag.split("-")
    if len(parts) != 3 or len(parts[1]) != 6 or not parts[1].isdigit() or not parts[2].isdigit():
        continue
    try:
        if tag_commit_sha(tag) == commit_sha:
            print(tag)
            raise SystemExit(0)
    except Exception:
        continue
raise SystemExit(1)
PY
}

case "$EVENT_NAME" in
  push)
    DEPLOY_REF="${GITHUB_REF_NAME:?GITHUB_REF_NAME is required for push}"
    bash "$(cd "$(dirname "$0")/../.." && pwd)/scripts/ci/assert-uat-tag.sh" "$DEPLOY_REF"
    emit_output proceed true
    emit_output deploy_ref "$DEPLOY_REF"
    emit_output trigger_source tag_push
    emit_output promote_run_id ""
    ;;

  workflow_dispatch)
    DEPLOY_REF="${DISPATCH_REF:?DISPATCH_REF is required for workflow_dispatch}"
    bash "$(cd "$(dirname "$0")/../.." && pwd)/scripts/ci/assert-uat-tag.sh" "$DEPLOY_REF"
    emit_output proceed true
    emit_output deploy_ref "$DEPLOY_REF"
    emit_output trigger_source workflow_dispatch
    emit_output promote_run_id ""
    ;;

  workflow_run)
    if [[ "${WORKFLOW_RUN_CONCLUSION:-}" != "success" ]]; then
      skip "promote_uat_not_success"
    fi

    PROMOTE_RUN_ID="${WORKFLOW_RUN_ID:?WORKFLOW_RUN_ID is required for workflow_run}"
    COMMIT_SHA="${WORKFLOW_RUN_HEAD_SHA:?WORKFLOW_RUN_HEAD_SHA is required for workflow_run}"

    if ! DEPLOY_REF="$(find_uat_tag_for_commit "$COMMIT_SHA")"; then
      echo "::error::No uat-* tag found for promote commit ${COMMIT_SHA}" >&2
      emit_output proceed false
      emit_output skip_reason no_uat_tag_for_commit
      exit 1
    fi

    emit_output proceed true
    emit_output deploy_ref "$DEPLOY_REF"
    emit_output trigger_source workflow_run
    emit_output promote_run_id "$PROMOTE_RUN_ID"
    ;;

  *)
    echo "::error::Unsupported EVENT_NAME: ${EVENT_NAME}" >&2
    exit 1
    ;;
esac
