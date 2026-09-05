#!/usr/bin/env bash
# Build a single remote SSH script (lib + demo reset body) for appleboy script_path upload.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NM_LIB="${ROOT}/scripts/ci/assert-node-modules-symlink.lib.sh"
RESET="${ROOT}/scripts/ci/uat-ssh-demo-reset.sh"
OUT="${ROOT}/.ci-uat-ssh-demo-reset.sh"

{
  echo '#!/usr/bin/env bash'
  echo 'set -euo pipefail'
  cat "$NM_LIB"
  echo
  # Demo reset body starts at HOME= (lib inlined above; never source on remote).
  awk '/^HOME=.*uat_nm_home_dir/,0' "$RESET"
} >"$OUT"
chmod +x "$OUT"
if grep -qE '^source .*(assert-node-modules|uat_nm)' "$OUT"; then
  echo "::error::${OUT} still sources external lib — bundle is broken for remote SSH" >&2
  exit 1
fi
for sentinel in UAT_DEMO_RESET_BEGIN UAT_DEMO_RESET_END; do
  if ! grep -qF "$sentinel" "$OUT"; then
    echo "::error::${OUT} missing required sentinel: ${sentinel}" >&2
    exit 1
  fi
done
echo "Wrote ${OUT} ($(wc -l <"$OUT") lines)"
