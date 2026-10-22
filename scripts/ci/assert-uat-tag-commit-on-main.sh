#!/usr/bin/env bash
# Require a uat-* tag to point at a commit that is on branch main (via GitHub API).
#
# Usage: assert-uat-tag-commit-on-main.sh <uat-tag>
# Requires GITHUB_REPOSITORY and GITHUB_TOKEN.
set -euo pipefail

TAG="${1:?usage: assert-uat-tag-commit-on-main.sh <uat-tag>}"
repo="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
token="${GITHUB_TOKEN:?GITHUB_TOKEN is required}"

TAG="${TAG#refs/tags/}"

api() {
  curl -fsS \
    -H "Authorization: Bearer ${token}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${repo}/$1"
}

resolve_tag_sha() {
  local ref_json
  if ! ref_json="$(api "git/ref/tags/${TAG}" 2>/dev/null)"; then
    echo "::error::UAT tag '${TAG}' was not found on ${repo}." >&2
    exit 1
  fi
  local obj_type obj_sha
  obj_type="$(printf '%s' "$ref_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["object"]["type"])')"
  obj_sha="$(printf '%s' "$ref_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["object"]["sha"])')"
  if [[ "$obj_type" == "commit" ]]; then
    printf '%s\n' "$obj_sha"
    return 0
  fi
  api "git/tags/${obj_sha}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["object"]["sha"])'
}

COMMIT_SHA="$(resolve_tag_sha)"

if ! branches="$(api "commits/${COMMIT_SHA}/branches-where-head" 2>/dev/null)"; then
  echo "::error::Could not resolve branches for commit ${COMMIT_SHA} (tag ${TAG})." >&2
  exit 1
fi

if ! printf '%s' "$branches" | python3 -c 'import json,sys; names={b["name"] for b in json.load(sys.stdin)}; sys.exit(0 if "main" in names else 1)'; then
  echo "::error::UAT tag ${TAG} (${COMMIT_SHA}) is not on branch main — deploy refused." >&2
  exit 1
fi

echo "UAT tag ${TAG} commit ${COMMIT_SHA} is on main"
