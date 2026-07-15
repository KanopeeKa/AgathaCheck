#!/usr/bin/env bash
# Merge per-shard lcov files and enforce the domain coverage gate.
set -euo pipefail

cd "$(dirname "$0")/.."
INPUT_ROOT="${1:-_coverage_shards}"
THRESHOLD="${DOMAIN_COVERAGE_THRESHOLD:-65}"

shards=(pet health org rest)
merged="coverage/lcov.merged.info"
mkdir -p coverage
rm -f "$merged"

found=0
for shard in "${shards[@]}"; do
  candidates=(
    "${INPUT_ROOT}/flutter-coverage-${shard}/lcov.info"
    "${INPUT_ROOT}/flutter-coverage-${shard}/lcov.${shard}.info"
    "${INPUT_ROOT}/flutter-coverage-${shard}/coverage/lcov.info"
    "${INPUT_ROOT}/flutter-coverage-${shard}/coverage/lcov.${shard}.info"
    "coverage/lcov.${shard}.info"
  )
  file=""
  for candidate in "${candidates[@]}"; do
    if [[ -f "$candidate" ]]; then
      file="$candidate"
      break
    fi
  done
  if [[ -z "$file" ]]; then
    echo "::error::Missing lcov for shard ${shard}" >&2
    exit 1
  fi
  echo "Merging ${file}"
  if [[ ! -f "$merged" ]]; then
    cp "$file" "$merged"
  else
    lcov -a "$merged" -a "$file" -o coverage/lcov.tmp.info >/dev/null
    mv coverage/lcov.tmp.info "$merged"
  fi
  found=$((found + 1))
done

if [[ "$found" -ne ${#shards[@]} ]]; then
  echo "::error::Expected ${#shards[@]} shard coverage files, found ${found}" >&2
  exit 1
fi

cp "$merged" coverage/lcov.info
node scripts/check_domain_coverage.js --threshold "$THRESHOLD" --lcov coverage/lcov.info
echo "Merged ${found} shard coverage files"
