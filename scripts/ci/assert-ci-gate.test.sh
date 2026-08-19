#!/usr/bin/env bash
# Regression tests for scripts/ci/assert-ci-gate.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GATE="$ROOT/scripts/ci/assert-ci-gate.sh"

all_success_env() {
  export STARTUP_SMOKE=success
  export TEST_SUITE=success
  export FLUTTER_ANALYZE=success
  export FLUTTER_TEST_PET_CORE=success
  export FLUTTER_TEST_PET_SCREENS=success
  export FLUTTER_TEST_PET_WIDGETS=success
  export FLUTTER_TEST_HEALTH=success
  export FLUTTER_TEST_ORG=success
  export FLUTTER_TEST_REST_A=success
  export FLUTTER_TEST_REST_B=success
  export FLUTTER_COVERAGE=success
  export FLUTTER_INTEGRATION=success
  export FLUTTER_BUILD_WEB=success
  export CI_E2E_CANARY=success
  unset CI_E2E_ORG
}

run_gate() {
  GITHUB_STEP_SUMMARY="$(mktemp)"
  export GITHUB_STEP_SUMMARY
  set +e
  bash "$GATE" >/dev/null 2>&1
  local code=$?
  set -e
  rm -f "$GITHUB_STEP_SUMMARY"
  return "$code"
}

assert_exit() {
  local want="$1"
  local msg="$2"
  if run_gate; then
    local got=0
  else
    local got=$?
  fi
  if [[ "$got" -ne "$want" ]]; then
    echo "FAIL: $msg (exit=$got want=$want)" >&2
    exit 1
  fi
}

# All green → pass
unset CI_SCOPE_JSON
all_success_env
assert_exit 0 "all jobs success"

# Single failure → fail
all_success_env
export FLUTTER_COVERAGE=failure
assert_exit 1 "flutter-coverage failure fails gate"

# Scoped skip: skipped job in skip_jobs is ok
all_success_env
export FLUTTER_ANALYZE=skipped
export FLUTTER_TEST_PET_CORE=skipped
export FLUTTER_TEST_PET_SCREENS=skipped
export FLUTTER_TEST_PET_WIDGETS=skipped
export FLUTTER_TEST_HEALTH=skipped
export FLUTTER_TEST_ORG=skipped
export FLUTTER_TEST_REST_A=skipped
export FLUTTER_TEST_REST_B=skipped
export FLUTTER_COVERAGE=skipped
export FLUTTER_INTEGRATION=skipped
export FLUTTER_BUILD_WEB=skipped
export CI_E2E_CANARY=skipped
export CI_SCOPE_JSON='{"scope":"SERVER_ONLY","skip_jobs":["flutter-analyze","flutter-test-pet-core","flutter-test-pet-screens","flutter-test-pet-widgets","flutter-test-health","flutter-test-org","flutter-test-rest-a","flutter-test-rest-b","flutter-coverage","flutter-integration","flutter-build-web","ci-e2e-canary"]}'
assert_exit 0 "scoped skips accepted when listed in skip_jobs"

# Skipped job not in skip_jobs → fail
all_success_env
export FLUTTER_COVERAGE=skipped
export CI_SCOPE_JSON='{"scope":"FULL","skip_jobs":[]}'
assert_exit 1 "unscoped skipped job fails gate"

# ci-e2e-canary must pass when flutter-build-web succeeded
all_success_env
export CI_E2E_CANARY=failure
assert_exit 1 "canary failure fails when build succeeded"

# ci-e2e-canary may skip when flutter-build-web did not succeed
all_success_env
export FLUTTER_BUILD_WEB=skipped
export CI_E2E_CANARY=skipped
export CI_SCOPE_JSON='{"scope":"SERVER_ONLY","skip_jobs":["flutter-analyze","flutter-test-pet-core","flutter-test-pet-screens","flutter-test-pet-widgets","flutter-test-health","flutter-test-org","flutter-test-rest-a","flutter-test-rest-b","flutter-coverage","flutter-integration","flutter-build-web","ci-e2e-canary"]}'
assert_exit 0 "canary skip ok when build skipped (scoped)"

# ci-e2e-org is optional (ci-full-audit only)
all_success_env
export CI_E2E_ORG=success
assert_exit 0 "optional org journey success passes gate"

all_success_env
export CI_E2E_ORG=failure
assert_exit 1 "optional org journey failure fails gate when CI_E2E_ORG set"

echo "assert-ci-gate tests passed"
