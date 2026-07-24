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
  local promote_run_id="${2:-}"
  local repo="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
  local token="${GITHUB_TOKEN:?GITHUB_TOKEN is required}"

  python3 - "$commit_sha" "$repo" "$token" "$promote_run_id" <<'PY'
import json
import sys
import urllib.error
import urllib.request

commit_sha, repo, token, promote_run_id = sys.argv[1:5]

def api(path: str):
    req = urllib.request.Request(
        f"https://api.github.com{path}",
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
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

def resolve_pr_number() -> int:
    pulls = api(f"/repos/{repo}/commits/{commit_sha}/pulls")
    if len(pulls) != 1:
        raise RuntimeError(f"expected 1 PR for {commit_sha}, got {len(pulls)}")
    return int(pulls[0]["number"])

def promote_yymmdd() -> str:
    if not promote_run_id:
        raise RuntimeError("promote_run_id required for fast tag lookup")
    run = api(f"/repos/{repo}/actions/runs/{promote_run_id}")
    created = run.get("created_at") or ""
    # 2026-07-24T13:50:20Z -> 260724
    if len(created) < 10:
        raise RuntimeError(f"invalid promote run created_at: {created!r}")
    return created[2:4] + created[5:7] + created[8:10]

def fast_lookup() -> str:
    pr_number = resolve_pr_number()
    yymmdd = promote_yymmdd()
    tag = f"uat-{yymmdd}-{pr_number}"
    if tag_commit_sha(tag) == commit_sha:
        return tag
    raise RuntimeError(f"tag {tag} does not point at {commit_sha}")

def slow_scan() -> str:
    page = 1
    while True:
        batch = api(f"/repos/{repo}/git/matching-refs/tags/uat-?per_page=100&page={page}")
        if not batch:
            break
        for item in batch:
            ref = item.get("ref", "")
            if not ref.startswith("refs/tags/uat-"):
                continue
            tag = ref.removeprefix("refs/tags/")
            parts = tag.split("-")
            if len(parts) != 3 or len(parts[1]) != 6 or not parts[1].isdigit() or not parts[2].isdigit():
                continue
            try:
                if tag_commit_sha(tag) == commit_sha:
                    return tag
            except Exception:
                continue
        if len(batch) < 100:
            break
        page += 1
    raise RuntimeError(f"no uat tag for commit {commit_sha}")

try:
    print(fast_lookup())
except Exception as fast_err:
    print(f"::warning::fast UAT tag lookup failed ({fast_err}); falling back to full tag scan", file=sys.stderr)
    print(slow_scan())
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

    PROMOTE_BLOCK_REASON="$(python3 - "$PROMOTE_RUN_ID" <<'PY'
import json
import os
import sys
import urllib.request

run_id = sys.argv[1]
repo = os.environ["GITHUB_REPOSITORY"]
token = os.environ["GITHUB_TOKEN"]

def api(path: str):
    req = urllib.request.Request(
        f"https://api.github.com{path}",
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    with urllib.request.urlopen(req) as resp:
        return json.load(resp)

try:
    for job in api(f"/repos/{repo}/actions/runs/{run_id}/jobs").get("jobs", []):
        if job.get("name") == "Create UAT tag" and job.get("conclusion") in ("skipped", "cancelled"):
            print("promote_tag_skipped")
            break
except Exception as err:
    # Never let a transient API hiccup (rate limit, 5xx, network blip) hard-fail
    # the whole deploy-uat run — fall through to find_uat_tag_for_commit below.
    print(f"::warning::promote-tag job lookup failed ({err}); continuing to tag resolution", file=sys.stderr)
PY
)"
    if [[ -n "$PROMOTE_BLOCK_REASON" ]]; then
      skip "$PROMOTE_BLOCK_REASON"
    fi

    if ! DEPLOY_REF="$(find_uat_tag_for_commit "$COMMIT_SHA" "$PROMOTE_RUN_ID")"; then
      echo "::warning::No uat-* tag found for promote commit ${COMMIT_SHA} — skipping deploy" >&2
      skip "no_uat_tag_for_commit"
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
