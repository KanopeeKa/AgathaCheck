#!/usr/bin/env bash
# Bundle remote in-host smoke script (nodevenv lib + body) for appleboy script_path upload.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NM_LIB="${ROOT}/scripts/ci/assert-node-modules-symlink.lib.sh"
REMOTE="${ROOT}/scripts/ci/uat-inhost-smoke-remote.sh"
OUT="${ROOT}/.ci-uat-inhost-smoke.sh"

{
  echo '#!/usr/bin/env bash'
  echo 'set -euo pipefail'
  cat "$NM_LIB"
  echo
  awk '/^HOME=.*uat_nm_home_dir/,0' "$REMOTE"
} >"$OUT"
chmod +x "$OUT"

if grep -qE '^source .*(assert-node-modules|uat_nm)' "$OUT"; then
  echo "::error::${OUT} still sources external lib — bundle is broken for remote SSH" >&2
  exit 1
fi
for sentinel in UAT_INHOST_SMOKE_BEGIN UAT_INHOST_SMOKE_END; do
  if ! grep -qF "$sentinel" "$OUT"; then
    echo "::error::${OUT} missing sentinel ${sentinel}" >&2
    exit 1
  fi
done
if ! grep -qF 'uat_nm_use_node' "$OUT"; then
  echo "::error::${OUT} missing uat_nm_use_node — nodevenv resolution not bundled" >&2
  exit 1
fi

echo "Wrote ${OUT} ($(wc -l <"$OUT") lines)"
