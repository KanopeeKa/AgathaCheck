#!/usr/bin/env bash
# Run Flutter tests one file at a time so a Linux flutter_tester segfault in one
# file cannot hang the entire CI job (subprocess crash leaves the parent waiting).
set -uo pipefail

cd "$(dirname "$0")/.."

failed=0
count=0
skipped=0

mapfile -t files < <(
  find test -name '*_test.dart' ! -path '*/integration/*' | sort
)

rm -rf coverage
mkdir -p coverage

for f in "${files[@]}"; do
  if grep -qE "@Tags\(\[.*skip-ci" "$f" 2>/dev/null; then
    echo "Skipping $f (skip-ci tag)"
    skipped=$((skipped + 1))
    continue
  fi

  count=$((count + 1))
  echo "::group::flutter test $f"
  if flutter test "$f" --concurrency=1 --coverage; then
    echo "PASS $f"
  else
    echo "::error::FAIL $f"
    failed=1
  fi
  echo "::endgroup::"

  # Merge partial coverage when present (best-effort).
  if [ -f coverage/lcov.info ] && command -v lcov >/dev/null 2>&1; then
    if [ -f coverage/lcov.merged.info ]; then
      lcov -a coverage/lcov.merged.info -a coverage/lcov.info \
        -o coverage/lcov.tmp.info >/dev/null 2>&1 \
        && mv coverage/lcov.tmp.info coverage/lcov.merged.info \
        || cp coverage/lcov.info coverage/lcov.merged.info
    else
      cp coverage/lcov.info coverage/lcov.merged.info
    fi
  fi
done

if [ -f coverage/lcov.merged.info ]; then
  mv coverage/lcov.merged.info coverage/lcov.info
fi

echo "Ran $count test files (skipped $skipped with skip-ci)."
exit $failed
