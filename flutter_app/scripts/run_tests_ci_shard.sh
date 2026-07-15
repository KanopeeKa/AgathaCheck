#!/usr/bin/env bash
# Run Flutter tests for one CI domain shard with coverage output.
# Tests run one file at a time (Linux flutter_tester segfault isolation).
set -uo pipefail

SHARD="${1:-}"
if [[ -z "$SHARD" ]]; then
  echo "usage: run_tests_ci_shard.sh <pet|health|org|rest>" >&2
  exit 1
fi

cd "$(dirname "$0")/.."

shard_paths() {
  case "$SHARD" in
    pet) printf '%s\n' test/features/pet_profile ;;
    health) printf '%s\n' test/features/health_tracking ;;
    org) printf '%s\n' test/features/organization ;;
    rest)
      printf '%s\n' \
        test/features/vet \
        test/features/auth \
        test/features/sharing \
        test/features/notifications \
        test/features/weight_tracking \
        test/features/subscription \
        test/features/help \
        test/features/about \
        test/features/api_base_url_wiring_test.dart
      ;;
    *)
      echo "::error::Unknown shard '${SHARD}' (expected pet|health|org|rest)" >&2
      return 1
      ;;
  esac
}

mapfile -t roots < <(shard_paths) || exit 1

mapfile -t files < <(
  for root in "${roots[@]}"; do
    if [[ -f "$root" ]]; then
      echo "$root"
    elif [[ -d "$root" ]]; then
      find "$root" -name '*_test.dart' ! -path '*/integration/*'
    fi
  done | sort -u
)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "::error::No test files found for shard ${SHARD}" >&2
  exit 1
fi

rm -rf coverage
mkdir -p coverage

failed=0
count=0
skipped=0

for f in "${files[@]}"; do
  if grep -qE "@Tags\(\[.*skip-ci" "$f" 2>/dev/null; then
    echo "Skipping $f (skip-ci tag)"
    skipped=$((skipped + 1))
    continue
  fi

  count=$((count + 1))
  echo "::group::flutter test $f"
  if flutter test "$f" --concurrency=1 --coverage --exclude-tags=integration; then
    echo "PASS $f"
  else
    echo "::error::FAIL $f"
    failed=1
  fi
  echo "::endgroup::"

  if [[ -f coverage/lcov.info ]] && command -v lcov >/dev/null 2>&1; then
    if [[ -f coverage/lcov.merged.info ]]; then
      lcov -a coverage/lcov.merged.info -a coverage/lcov.info \
        -o coverage/lcov.tmp.info >/dev/null 2>&1 \
        && mv coverage/lcov.tmp.info coverage/lcov.merged.info \
        || cp coverage/lcov.info coverage/lcov.merged.info
    else
      cp coverage/lcov.info coverage/lcov.merged.info
    fi
  fi
done

if [[ -f coverage/lcov.merged.info ]]; then
  mv coverage/lcov.merged.info coverage/lcov.info
fi

if [[ -f coverage/lcov.info ]]; then
  cp coverage/lcov.info "coverage/lcov.${SHARD}.info"
  echo "Wrote coverage/lcov.${SHARD}.info"
else
  echo "::warning::No coverage/lcov.info produced for shard ${SHARD}"
fi

echo "Ran $count test files for shard ${SHARD} (skipped $skipped with skip-ci)."
exit "$failed"
