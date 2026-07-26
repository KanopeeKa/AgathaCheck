#!/usr/bin/env bash
# Resolve the commit to promote after a green Pre-UAT E2E run.
# Uses origin/main HEAD — the gate job only succeeds when E2E passed for that SHA.
#
# Outputs to GITHUB_OUTPUT:
#   commit_sha
set -euo pipefail

emit_output() {
  local key="$1"
  local value="$2"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf '%s=%s\n' "$key" "$value" >>"$GITHUB_OUTPUT"
  fi
  printf '%s=%s\n' "$key" "$value"
}

git fetch origin main --depth=1
commit_sha="$(git rev-parse origin/main)"
emit_output commit_sha "$commit_sha"
echo "Promote target commit: ${commit_sha}"
