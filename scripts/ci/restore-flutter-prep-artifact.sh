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

rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
tar -xzf "$ARCHIVE" -C "$WORKDIR"

if [[ ! -f "$WORKDIR/manifest.json" ]]; then
  echo "::error::Flutter prep manifest missing in ${ARCHIVE}" >&2
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

if [[ -d "$WORKDIR/flutter_app/assets/legal" ]]; then
  rm -rf flutter_app/assets/legal
  mkdir -p flutter_app/assets
  cp -a "$WORKDIR/flutter_app/assets/legal" flutter_app/assets/legal
fi

echo "Restored Flutter prep archive from ${ARCHIVE} (mocks=${mock_count})"
cat "$WORKDIR/manifest.json"
rm -rf "$WORKDIR"
