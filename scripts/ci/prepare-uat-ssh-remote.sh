#!/usr/bin/env bash
# Build a single remote SSH script (lib + deploy body) for appleboy script_path upload.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NM_LIB="${ROOT}/scripts/ci/assert-node-modules-symlink.lib.sh"
HT_LIB="${ROOT}/scripts/ci/uat-htaccess.lib.sh"
DEPLOY="${ROOT}/scripts/ci/uat-ssh-backend-deploy.sh"
OUT="${ROOT}/.ci-uat-ssh-remote.sh"

{
  echo '#!/usr/bin/env bash'
  echo 'set -euo pipefail'
  cat "$NM_LIB"
  echo
  cat "$HT_LIB"
  echo
  # Deploy body starts at HOME= (libs inlined above; never source on remote).
  awk '/^HOME=.*uat_nm_home_dir/,0' "$DEPLOY"
} >"$OUT"
chmod +x "$OUT"
if grep -qE '^source .*(assert-node-modules|uat_nm|uat-htaccess|uat_htaccess)' "$OUT"; then
  echo "::error::${OUT} still sources external lib — bundle is broken for remote SSH" >&2
  exit 1
fi
for sentinel in UAT_SSH_DEPLOY_BEGIN UAT_SSH_DEPLOY_END; do
  if ! grep -qF "$sentinel" "$OUT"; then
    echo "::error::${OUT} missing required sentinel: ${sentinel}" >&2
    exit 1
  fi
done
echo "Wrote ${OUT} ($(wc -l <"$OUT") lines)"
