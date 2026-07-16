#!/usr/bin/env bash
# Assert all CI caller jobs succeeded — used by ci.yml ci-gate job.
# When adding a new blocking job to ci.yml, add its needs.*.result env below
# AND add the job id to ci-gate needs: in .github/workflows/ci.yml.
# See docs/ci-cd-gates.md and docs/promotion-contract.md.
set -euo pipefail

SUMMARY_FILE="${GITHUB_STEP_SUMMARY:-}"

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

# Job id → needs.<job_id>.result (keep in sync with ci.yml ci-gate needs:)
declare -A RESULTS=(
  [startup-smoke]="${STARTUP_SMOKE:-}"
  [test-suite]="${TEST_SUITE:-}"
  [flutter-analyze]="${FLUTTER_ANALYZE:-}"
  [flutter-test-pet]="${FLUTTER_TEST_PET:-}"
  [flutter-test-health]="${FLUTTER_TEST_HEALTH:-}"
  [flutter-test-org]="${FLUTTER_TEST_ORG:-}"
  [flutter-test-rest]="${FLUTTER_TEST_REST:-}"
  [flutter-coverage]="${FLUTTER_COVERAGE:-}"
  [flutter-integration]="${FLUTTER_INTEGRATION:-}"
  [flutter-build-web]="${FLUTTER_BUILD_WEB:-}"
)

failed=0
{
  echo "## CI gate summary"
  echo
  echo "| Job | Result | Pass |"
  echo "|-----|--------|------|"
  for job in startup-smoke test-suite flutter-analyze \
    flutter-test-pet flutter-test-health flutter-test-org flutter-test-rest \
    flutter-coverage flutter-integration flutter-build-web; do
    result="${RESULTS[$job]}"
    if require_success "$job" "$result"; then
      pass="yes"
    else
      pass="**no**"
      failed=1
    fi
    echo "| \`${job}\` | ${result:-unknown} | ${pass} |"
  done

  echo
  if [[ "$failed" -eq 0 ]]; then
    echo "**CI passed** — all caller jobs succeeded."
  else
    echo "**CI gate failed** — one or more jobs did not succeed."
    echo
    echo "Granular checks remain visible on the PR; only \`ci-gate / CI passed\` is required for merge."
  fi
} | append_summary

if [[ "$failed" -ne 0 ]]; then
  echo "::error::CI gate failed — see summary table for failing jobs."
  exit 1
fi

echo "CI gate passed."
