#!/usr/bin/env bash
# Assert all CI caller jobs succeeded — used by ci.yml ci-gate job.
# When adding a new blocking job to ci.yml, add its needs.*.result env below
# AND add the job id to ci-gate needs: in .github/workflows/ci.yml.
# Optional CI_SCOPE_JSON (from ci-scope job) marks jobs that may be skipped.
# See docs/pipelines/ci-cd-gates.md and docs/pipelines/promotion-contract.md.
set -euo pipefail

SUMMARY_FILE="${GITHUB_STEP_SUMMARY:-}"
SCOPE_JSON="${CI_SCOPE_JSON:-}"

append_summary() {
  if [[ -n "$SUMMARY_FILE" ]]; then
    cat >>"$SUMMARY_FILE"
  fi
}

require_success() {
  local name="$1"
  local result="$2"
  [[ "$result" == "success" ]]
}

job_in_skip_list() {
  local job="$1"
  [[ -z "$SCOPE_JSON" ]] && return 1
  python3 -c 'import json,sys; job=sys.argv[1]; data=json.loads(sys.stdin.read()); sys.exit(0 if job in data.get("skip_jobs", []) else 1)' "$job" <<<"$SCOPE_JSON"
}

job_expects_skip() {
  job_in_skip_list "$@"
}

job_passes() {
  local job="$1"
  local result="$2"
  if job_expects_skip "$job"; then
    [[ "$result" == "success" || "$result" == "skipped" ]]
    return
  fi
  require_success "$job" "$result"
}

# Job id → needs.<job_id>.result (keep in sync with ci.yml ci-gate needs:)
declare -A RESULTS=(
  [startup-smoke]="${STARTUP_SMOKE:-}"
  [test-suite]="${TEST_SUITE:-}"
  [flutter-analyze]="${FLUTTER_ANALYZE:-}"
  [flutter-prep]="${FLUTTER_PREP:-}"
  [flutter-test]="${FLUTTER_TEST:-}"
  [flutter-coverage]="${FLUTTER_COVERAGE:-}"
  [flutter-integration]="${FLUTTER_INTEGRATION:-}"
  [flutter-build-web]="${FLUTTER_BUILD_WEB:-}"
  [ci-e2e-canary]="${CI_E2E_CANARY:-}"
  [ci-e2e-affected]="${CI_E2E_AFFECTED:-}"
)

# E2E jobs (canary, affected specs) skip when flutter-build-web fails or scope skips them;
# require green when the build ran and scope selected them.
e2e_job_passes() {
  local job="$1"
  local result="$2"
  local build="${FLUTTER_BUILD_WEB:-}"
  if job_expects_skip "$job"; then
    [[ "$result" == "success" || "$result" == "skipped" ]]
    return
  fi
  if [[ "$build" == "success" ]]; then
    [[ "$result" == "success" ]]
  else
    [[ "$result" == "success" || "$result" == "skipped" ]]
  fi
}

failed=0
scope_label=""
if [[ -n "$SCOPE_JSON" ]]; then
  scope_label="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("scope","?"))' <<<"$SCOPE_JSON")"
fi

# Write summary to a temp file — NOT a pipe. A pipe would run the block in a subshell and
# `failed=1` would never propagate to the exit check below.
SUMMARY_TMP="$(mktemp)"
trap 'rm -f "$SUMMARY_TMP"' EXIT

{
  echo "## CI gate summary"
  if [[ -n "$scope_label" ]]; then
    echo
    echo "CI scope: \`$scope_label\`"
  fi
  echo
  echo "| Job | Result | Pass |"
  echo "|-----|--------|------|"
  for job in startup-smoke test-suite flutter-analyze flutter-prep flutter-test \
    flutter-coverage flutter-integration flutter-build-web ci-e2e-canary ci-e2e-affected; do
    result="${RESULTS[$job]}"
    if [[ "$job" == "ci-e2e-canary" || "$job" == "ci-e2e-affected" ]]; then
      if e2e_job_passes "$job" "$result"; then
        pass="yes"
      else
        pass="**no**"
        failed=1
      fi
    elif job_passes "$job" "$result"; then
      pass="yes"
    else
      pass="**no**"
      failed=1
    fi
    if job_expects_skip "$job"; then
      pass="${pass} (scoped skip ok)"
    fi
    echo "| \`${job}\` | ${result:-unknown} | ${pass} |"
  done

  echo
  if [[ "$failed" -eq 0 ]]; then
    echo "**CI passed** — all required caller jobs succeeded."
  else
    echo "**CI gate failed** — one or more jobs did not succeed."
    echo
    echo "Granular checks remain visible on the PR; only \`ci-gate / CI passed\` is required for merge."
  fi
} >"$SUMMARY_TMP"

append_summary <"$SUMMARY_TMP"

if [[ "$failed" -ne 0 ]]; then
  echo "::error::CI gate failed — see summary table for failing jobs."
  exit 1
fi

echo "CI gate passed."
