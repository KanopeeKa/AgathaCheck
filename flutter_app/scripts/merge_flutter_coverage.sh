#!/usr/bin/env bash
# Merge per-shard lcov files and enforce the domain coverage gate.
set -euo pipefail

cd "$(dirname "$0")/.."
INPUT_ROOT="${1:-_coverage_shards}"
THRESHOLD="${DOMAIN_COVERAGE_THRESHOLD:-70}"

# Shard ids come from flutter_app/test/ci_shards.json (single source of truth).
mapfile -t shards < <(node ../scripts/ci/flutter-shards.mjs list)
if [[ ${#shards[@]} -eq 0 ]]; then
  echo "::error::No Flutter shards listed in test/ci_shards.json" >&2
  exit 1
fi
mkdir -p coverage
inputs=()
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
  inputs+=("$file")
done
found=${#inputs[@]}

if [[ "$found" -ne ${#shards[@]} ]]; then
  echo "::error::Expected ${#shards[@]} shard coverage files, found ${found}" >&2
  exit 1
fi

node ../scripts/ci/lcov-merge.mjs --out coverage/lcov.info "${inputs[@]}"
node scripts/check_domain_coverage.js --threshold "$THRESHOLD" --lcov coverage/lcov.info
echo "Merged ${found} shard coverage files"
