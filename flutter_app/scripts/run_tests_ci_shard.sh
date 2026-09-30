#!/usr/bin/env bash
# Run Flutter tests for one CI shard with coverage output.
# Shard → test files come from flutter_app/test/ci_shards.json (scripts/ci/flutter-shards.mjs).
# Tests run one file at a time (Linux flutter_tester segfault isolation).
set -uo pipefail

SHARD="${1:-}"
cd "$(dirname "$0")/.."
SHARDS_CLI="../scripts/ci/flutter-shards.mjs"

if [[ -z "$SHARD" ]]; then
  echo "usage: run_tests_ci_shard.sh <shard> (one of: $(node "$SHARDS_CLI" list | tr '\n' ' '))" >&2
  exit 1
fi

if ! shard_files="$(node "$SHARDS_CLI" files "$SHARD")"; then
  exit 1
fi
mapfile -t files <<<"$shard_files"

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

  if grep -qE "@Tags\(\[.*'frozen'" "$f" 2>/dev/null; then
    echo "Skipping $f (frozen tag)"
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

echo "Ran $count test files for shard ${SHARD} (skipped $skipped with skip-ci/frozen tags)."
exit "$failed"
