#!/usr/bin/env bash
# Restore Flutter prep outputs staged by flutter-analyze (mocks + legal assets).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

ARCHIVE="${1:-flutter-prep-artifact.tar.gz}"
WORKDIR="${2:-flutter-prep-artifact}"

if [[ ! -f "$ARCHIVE" ]]; then
  echo "::error::Flutter prep archive not found: ${ARCHIVE}" >&2
  exit 1
fi

if [[ ! -s "$ARCHIVE" ]]; then
  echo "::error::Flutter prep archive is empty: ${ARCHIVE}" >&2
  exit 1
fi

rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
if ! tar -xzf "$ARCHIVE" -C "$WORKDIR"; then
  echo "::error::Flutter prep archive is corrupt or unreadable: ${ARCHIVE}" >&2
  exit 1
fi

if [[ ! -f "$WORKDIR/manifest.json" ]]; then
  echo "::error::Flutter prep manifest missing in ${ARCHIVE}" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "::error::jq is required to validate Flutter prep manifest" >&2
  exit 1
fi

expected_mocks="$(jq -r '.mock_files // empty' "$WORKDIR/manifest.json")"
expected_legal="$(jq -r '.legal_files // empty' "$WORKDIR/manifest.json")"
if [[ -z "$expected_mocks" || -z "$expected_legal" ]]; then
  echo "::error::Flutter prep manifest missing mock_files or legal_files" >&2
  exit 1
fi

mock_count=0
while IFS= read -r -d '' file; do
  rel="${file#$WORKDIR/flutter_app/}"
  dest="flutter_app/$rel"
  mkdir -p "$(dirname "$dest")"
  cp "$file" "$dest"
  mock_count=$((mock_count + 1))
done < <(find "$WORKDIR/flutter_app/test" -name '*.mocks.dart' -print0 2>/dev/null || true)

if [[ "$mock_count" -ne "$expected_mocks" ]]; then
  echo "::error::Mock file count mismatch (restored=${mock_count}, manifest=${expected_mocks})" >&2
  exit 1
fi

if [[ ! -d "$WORKDIR/flutter_app/assets/legal" ]]; then
  echo "::error::Legal assets missing from prep archive" >&2
  exit 1
fi

rm -rf flutter_app/assets/legal
mkdir -p flutter_app/assets
cp -a "$WORKDIR/flutter_app/assets/legal" flutter_app/assets/legal

legal_count="$(find flutter_app/assets/legal -type f | wc -l | tr -d ' ')"
if [[ "$legal_count" -lt "$expected_legal" ]]; then
  echo "::error::Legal file count mismatch (restored=${legal_count}, manifest=${expected_legal})" >&2
  exit 1
fi

echo "Restored Flutter prep archive from ${ARCHIVE} (mocks=${mock_count}, legal=${legal_count})"
cat "$WORKDIR/manifest.json"
rm -rf "$WORKDIR"
