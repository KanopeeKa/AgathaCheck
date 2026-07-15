#!/usr/bin/env bash
# Restore Flutter prep outputs staged by flutter-analyze (mocks + legal assets).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

INPUT="${1:-.flutter-prep-artifact}"

if [[ ! -d "$INPUT" ]]; then
  echo "::error::Flutter prep artifact directory not found: ${INPUT}" >&2
  exit 1
fi

if [[ ! -f "$INPUT/manifest.json" ]]; then
  echo "::error::Flutter prep manifest missing in ${INPUT}" >&2
  exit 1
fi

mock_count=0
while IFS= read -r -d '' file; do
  rel="${file#$INPUT/flutter_app/}"
  dest="flutter_app/$rel"
  mkdir -p "$(dirname "$dest")"
  cp "$file" "$dest"
  mock_count=$((mock_count + 1))
done < <(find "$INPUT/flutter_app/test" -name '*.mocks.dart' -print0 2>/dev/null || true)

if [[ -d "$INPUT/flutter_app/assets/legal" ]]; then
  rm -rf flutter_app/assets/legal
  mkdir -p flutter_app/assets
  cp -a "$INPUT/flutter_app/assets/legal" flutter_app/assets/legal
fi

echo "Restored Flutter prep artifact from ${INPUT} (mocks=${mock_count})"
cat "$INPUT/manifest.json"
