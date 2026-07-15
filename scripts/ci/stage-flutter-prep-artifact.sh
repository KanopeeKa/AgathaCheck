#!/usr/bin/env bash
# Stage canonical Flutter prep outputs (codegen mocks + synced legal assets).
# Run once in flutter-analyze after build_runner and sync_legal_documents.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

STAGING="${1:-flutter-prep-artifact}"
ARCHIVE="${2:-flutter-prep-artifact.tar.gz}"
rm -rf "$STAGING" "$ARCHIVE"
mkdir -p "$STAGING/flutter_app/assets"

mock_count=0
while IFS= read -r -d '' file; do
  rel="${file#flutter_app/}"
  dest="$STAGING/flutter_app/$rel"
  mkdir -p "$(dirname "$dest")"
  cp "$file" "$dest"
  mock_count=$((mock_count + 1))
done < <(find flutter_app/test -name '*.mocks.dart' -print0 2>/dev/null || true)

if [[ "$mock_count" -eq 0 ]]; then
  echo "::error::No *.mocks.dart files to stage — run build_runner before staging" >&2
  exit 1
fi

if [[ ! -d flutter_app/assets/legal ]]; then
  echo "::error::flutter_app/assets/legal missing — run sync_legal_documents before staging" >&2
  exit 1
fi

cp -a flutter_app/assets/legal "$STAGING/flutter_app/assets/legal"

legal_count="$(find flutter_app/assets/legal -type f | wc -l | tr -d ' ')"
if [[ "$legal_count" -eq 0 ]]; then
  echo "::error::No legal asset files to stage" >&2
  exit 1
fi

cat >"$STAGING/manifest.json" <<EOF
{
  "sha": "${GITHUB_SHA:-local}",
  "mock_files": ${mock_count},
  "legal_files": ${legal_count},
  "staged_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

tar -czf "$ARCHIVE" -C "$STAGING" .
rm -rf "$STAGING"

if [[ ! -s "$ARCHIVE" ]]; then
  echo "::error::Flutter prep archive is empty after staging" >&2
  exit 1
fi

echo "Staged Flutter prep archive: mocks=${mock_count} legal=${legal_count} -> ${ARCHIVE}"
