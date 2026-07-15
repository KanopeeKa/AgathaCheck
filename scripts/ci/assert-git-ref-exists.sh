#!/usr/bin/env bash
# Assert a branch or tag exists on origin via the GitHub API (no local clone).
#
# Usage:
#   scripts/ci/assert-git-ref-exists.sh <branch-or-tag> [branch-prefix-hint]
#
# Requires GITHUB_REPOSITORY and GITHUB_TOKEN.
set -euo pipefail

ref="${1:?usage: assert-git-ref-exists.sh <branch-or-tag> [branch-prefix-hint]}"
hint="${2:-}"
ref="${ref#refs/heads/}"
ref="${ref#refs/tags/}"

repo="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
token="${GITHUB_TOKEN:?GITHUB_TOKEN is required}"

api() {
  curl -fsS \
    -H "Authorization: Bearer ${token}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${repo}/$1"
}

for kind in heads tags; do
  if api "git/ref/${kind}/${ref}" >/dev/null 2>&1; then
    echo "Found ref ${kind}/${ref} on ${repo}"
    exit 0
  fi
done

echo "::error::Git ref '${ref}' was not found on ${repo}." >&2
if [[ -n "${hint}" ]]; then
  echo "::error::Create and push the branch first, or choose an existing ${hint} branch." >&2
  if branches="$(api "git/matching-refs/${hint}" 2>/dev/null || true)"; then
    if [[ -n "${branches}" && "${branches}" != "[]" ]]; then
      echo "Matching branches on origin:" >&2
      printf '%s\n' "${branches}" | jq -r '.[].ref | sub("refs/heads/"; "")' 2>/dev/null | head -15 >&2 || true
    fi
  fi
else
  echo "::error::Verify the ref name and that it has been pushed to origin." >&2
fi
exit 1
