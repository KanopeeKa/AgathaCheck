#!/usr/bin/env bash
# Run Flutter tests for one CI domain shard with coverage output.
set -uo pipefail

SHARD="${1:-}"
if [[ -z "$SHARD" ]]; then
  echo "usage: run_tests_ci_shard.sh <pet|health|org|rest>" >&2
  exit 1
fi

cd "$(dirname "$0")/.."

TEST_ARGS=(--concurrency=1 --coverage --exclude-tags=integration --exclude-tags=skip-ci)

run_paths() {
  local failed=0
  for path in "$@"; do
    if [[ ! -e "$path" ]]; then
      echo "::warning::Skipping missing test path: $path"
      continue
    fi
    echo "::group::flutter test $path"
    if flutter test "$path" "${TEST_ARGS[@]}"; then
      echo "PASS $path"
    else
      echo "::error::FAIL $path"
      failed=1
    fi
    echo "::endgroup::"
  done
  return "$failed"
}

rm -rf coverage
mkdir -p coverage

failed=0
case "$SHARD" in
  pet)
    run_paths test/features/pet_profile || failed=1
    ;;
  health)
    run_paths test/features/health_tracking || failed=1
    ;;
  org)
    run_paths test/features/organization || failed=1
    ;;
  rest)
    run_paths \
      test/features/vet \
      test/features/auth \
      test/features/sharing \
      test/features/notifications \
      test/features/weight_tracking \
      test/features/subscription \
      test/features/help \
      test/features/about \
      test/features/api_base_url_wiring_test.dart || failed=1
    ;;
  *)
    echo "::error::Unknown shard '${SHARD}' (expected pet|health|org|rest)" >&2
    exit 1
    ;;
esac

if [[ -f coverage/lcov.info ]]; then
  cp coverage/lcov.info "coverage/lcov.${SHARD}.info"
  echo "Wrote coverage/lcov.${SHARD}.info"
else
  echo "::warning::No coverage/lcov.info produced for shard ${SHARD}"
fi

exit "$failed"
