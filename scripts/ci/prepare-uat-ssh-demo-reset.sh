#!/usr/bin/env bash
# Build a single remote SSH script (lib + demo reset body) for appleboy script_path upload.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NM_LIB="${ROOT}/scripts/ci/assert-node-modules-symlink.lib.sh"
RESET="${ROOT}/scripts/ci/uat-ssh-demo-reset.sh"
TAXONOMY="${ROOT}/shared/care_taxonomy.json"
OUT="${ROOT}/.ci-uat-ssh-demo-reset.sh"
MARKER='# __UAT_EMBED_CARE_TAXONOMY_JSON__'

if [[ ! -f "$TAXONOMY" ]]; then
  echo "::error::missing ${TAXONOMY} — cannot bundle demo reset" >&2
  exit 1
fi

{
  echo '#!/usr/bin/env bash'
  echo 'set -euo pipefail'
  cat "$NM_LIB"
  echo
  # Demo reset body starts at HOME= (lib inlined above; never source on remote).
  awk '/^HOME=.*uat_nm_home_dir/,0' "$RESET"
} >"$OUT"

taxonomy_block="$(mktemp)"
{
  echo "cat > \"\${APPDIR}/shared/care_taxonomy.json\" <<'__UAT_CARE_TAXONOMY__'"
  cat "$TAXONOMY"
  echo '__UAT_CARE_TAXONOMY__'
} >"$taxonomy_block"
if ! grep -qF "$MARKER" "$OUT"; then
  echo "::error::${OUT} missing taxonomy embed marker" >&2
  rm -f "$taxonomy_block"
  exit 1
fi
awk -v blockfile="$taxonomy_block" '
  index($0, "# __UAT_EMBED_CARE_TAXONOMY_JSON__") {
    while ((getline line < blockfile) > 0) print line
    close(blockfile)
    next
  }
  { print }
' "$OUT" >"${OUT}.tmp"
mv "${OUT}.tmp" "$OUT"
rm -f "$taxonomy_block"
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
