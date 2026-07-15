#!/usr/bin/env bash
# Fail loudly when flutter-prep-<sha>.tar.gz is missing after download-artifact.
set -euo pipefail

ARCHIVE="${1:-flutter-prep-artifact.tar.gz}"
SHA="${2:-}"

if [[ ! -f "$ARCHIVE" ]]; then
  echo "::error::Flutter prep archive not downloaded (expected ${ARCHIVE} for sha=${SHA})" >&2
  exit 1
fi

if [[ ! -s "$ARCHIVE" ]]; then
  echo "::error::Flutter prep archive downloaded but empty (${ARCHIVE})" >&2
  exit 1
fi

echo "Flutter prep archive present: ${ARCHIVE} ($(wc -c <"$ARCHIVE" | tr -d ' ') bytes)"
