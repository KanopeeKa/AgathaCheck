#!/usr/bin/env bash
# Bundle remote in-host smoke script for appleboy SSH upload.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REMOTE="${ROOT}/scripts/ci/uat-inhost-smoke-remote.sh"
OUT="${ROOT}/.ci-uat-inhost-smoke.sh"

cp "$REMOTE" "$OUT"
chmod +x "$OUT"

for sentinel in UAT_INHOST_SMOKE_BEGIN UAT_INHOST_SMOKE_END; do
  if ! grep -qF "$sentinel" "$OUT"; then
    echo "::error::${OUT} missing sentinel ${sentinel}" >&2
    exit 1
  fi
done

echo "Wrote ${OUT} ($(wc -l <"$OUT") lines)"
