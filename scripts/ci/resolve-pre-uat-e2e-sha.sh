#!/usr/bin/env bash
# Resolve the commit SHA for pre-UAT E2E (always latest origin/main HEAD).
# Queued workflow runs bundle merges: each run tests HEAD at job start.
#
# Outputs to GITHUB_OUTPUT:
#   test_sha
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
test_sha="$(git rev-parse origin/main)"

emit_output test_sha "$test_sha"
echo "Pre-UAT E2E will test origin/main at ${test_sha}"
