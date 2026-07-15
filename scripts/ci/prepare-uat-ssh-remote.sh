#!/usr/bin/env bash
# Build a single remote SSH script (lib + deploy body) for appleboy script_path upload.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LIB="${ROOT}/scripts/ci/assert-node-modules-symlink.lib.sh"
DEPLOY="${ROOT}/scripts/ci/uat-ssh-backend-deploy.sh"
OUT="${ROOT}/.ci-uat-ssh-remote.sh"

{
  echo '#!/usr/bin/env bash'
  echo 'set -euo pipefail'
  cat "$LIB"
  echo
  # Deploy body without shebang, set -euo, or local lib source (lib is inlined above).
  awk 'NR>4 { print }' "$DEPLOY"
} >"$OUT"
chmod +x "$OUT"
echo "Wrote ${OUT} ($(wc -l <"$OUT") lines)"
