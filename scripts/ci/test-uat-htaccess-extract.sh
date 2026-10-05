#!/usr/bin/env bash
# Regression: uat_extract_cloudlinux_blocks must not swallow SPA rules below Passenger END.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=scripts/ci/uat-htaccess.lib.sh
source "${ROOT}/scripts/ci/uat-htaccess.lib.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

site="${tmpdir}/site"
mkdir -p "$site"

cat >"${site}/.htaccess" <<'EOF'
# CLOUDLINUX PASSENGER CONFIGURATION BEGIN
PassengerEnabled on
# CLOUDLINUX PASSENGER CONFIGURATION END
RewriteCond %{REQUEST_URI} !^/backend
RewriteRule ^ index.html [L]
EOF

extracted="$(uat_extract_cloudlinux_blocks "${site}/.htaccess")"
if echo "$extracted" | grep -q 'RewriteCond'; then
  echo "::error::extract included SPA rules below Passenger END" >&2
  exit 1
fi

printf 'line1-spa\n' >"${site}/htaccess.spa"

line_count=0
for _ in 1 2 3; do
  preserved="$(uat_extract_cloudlinux_blocks "${site}/.htaccess")"
  UAT_HT_ROOT_APPLIED="false"
  UAT_HT_PASSENGER_MERGED_TO_ROOT="false"
  uat_htaccess_apply_spa_merge "$site" "$preserved"
  line_count="$(wc -l <"${site}/.htaccess" | tr -d ' ')"
done

expected=5
if [[ "$line_count" != "$expected" ]]; then
  echo "::error::htaccess grew to ${line_count} lines after 3 merges (expected ${expected})" >&2
  cat "${site}/.htaccess" >&2
  exit 1
fi

echo "uat-htaccess extract regression OK (${line_count} lines stable after 3 merges)"
