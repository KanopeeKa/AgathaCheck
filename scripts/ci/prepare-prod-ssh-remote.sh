#!/usr/bin/env bash
# Build a single remote SSH script (lib + deploy body) for appleboy script_path upload.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NM_LIB="${ROOT}/scripts/ci/assert-node-modules-symlink.lib.sh"
DEPLOY="${ROOT}/scripts/ci/prod-ssh-backend-deploy.sh"
OUT="${ROOT}/.ci-prod-ssh-remote.sh"

{
  echo '#!/usr/bin/env bash'
  echo 'set -euo pipefail'
  cat "$NM_LIB"
  echo
  awk '/^HOME=.*uat_nm_home_dir/,0' "$DEPLOY"
} >"$OUT"
chmod +x "$OUT"
if grep -qE '^source .*(assert-node-modules|uat_nm)' "$OUT"; then
  echo "::error::${OUT} still sources external lib — bundle is broken for remote SSH" >&2
  exit 1
fi
for sentinel in PROD_SSH_DEPLOY_BEGIN PROD_SSH_DEPLOY_END; do
  if ! grep -qF "$sentinel" "$OUT"; then
    echo "::error::${OUT} missing required sentinel: ${sentinel}" >&2
    exit 1
  fi
done
echo "Wrote ${OUT} ($(wc -l <"$OUT") lines)"
