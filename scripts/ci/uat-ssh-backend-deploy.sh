#!/usr/bin/env bash
# UAT post-FTP backend steps over SSH (single bundled script via workflow Prepare step).
#
# Env:
#   UAT_SITE_ROOT, PKG_CHANGED, POST_RESTART_RETRIES, POST_RESTART_SLEEP_SEC
set -euo pipefail

# shellcheck source=assert-node-modules-symlink.lib.sh
source "$(cd "$(dirname "$0")" && pwd)/assert-node-modules-symlink.lib.sh"

HOME="$(uat_nm_home_dir)"
export HOME
export UAT_DEPLOY_STATE_FILE="$(uat_nm_state_file)"

SITE_ROOT="${UAT_SITE_ROOT:-${HOME}/uat.agathatrack.com}"
APPDIR="${SITE_ROOT}/backend"
POST_RESTART_RETRIES="${POST_RESTART_RETRIES:-3}"
POST_RESTART_SLEEP_SEC="${POST_RESTART_SLEEP_SEC:-10}"
PKG_CHANGED="${PKG_CHANGED:-false}"

export UAT_SITE_ROOT
export UAT_APP_DIR="$APPDIR"

echo "=== UAT SSH backend deploy ==="
echo "site_root=${SITE_ROOT}"
echo "app_dir=${APPDIR}"
echo "pkg_changed=${PKG_CHANGED}"

if [[ "$PKG_CHANGED" == "true" ]]; then
  echo "::warning title=Dependencies changed::server/package.json or package-lock.json changed in this deploy."
  echo "::warning::Manual action required: cPanel → Setup Node.js App → Run NPM Install → Restart"
fi

echo "=== SPA .htaccess at domain root ==="
if [[ -f "${SITE_ROOT}/htaccess.spa" ]]; then
  install -m 644 "${SITE_ROOT}/htaccess.spa" "${SITE_ROOT}/.htaccess"
  echo "Installed ${SITE_ROOT}/.htaccess from htaccess.spa"
elif [[ -f "${SITE_ROOT}/.htaccess" ]]; then
  echo "OK: ${SITE_ROOT}/.htaccess already present"
else
  echo "::warning::no htaccess.spa or .htaccess at domain root — Flutter deep links may break"
fi

echo "=== Passenger .htaccess in backend ==="
PASSENGER_HTACCESS_OK="false"
if [[ -f "${APPDIR}/.htaccess" ]] && grep -qE 'Passenger(AppRoot|Enabled|BaseURI)' "${APPDIR}/.htaccess" 2>/dev/null; then
  PASSENGER_HTACCESS_OK="true"
  echo "OK: backend/.htaccess contains Passenger directives"
else
  echo "::error::backend/.htaccess missing or not a Passenger config"
  echo "Action: cPanel → Setup Node.js App → app root ${APPDIR#"$HOME"/} → startup bin/start.js → Save → Restart"
  exit 1
fi
export PASSENGER_HTACCESS_OK

echo "=== node_modules invariant (pre-restart) ==="
uat_nm_assert pre 1 0

echo "=== triggering Passenger restart ==="
mkdir -p "${APPDIR}/tmp"
touch "${APPDIR}/tmp/restart.txt"
echo "Passenger restart triggered via tmp/restart.txt"

echo "=== node_modules invariant (post-restart) ==="
uat_nm_assert post "$POST_RESTART_RETRIES" "$POST_RESTART_SLEEP_SEC"

echo "=== UAT SSH backend deploy complete ==="
echo "deploy_state_file=${UAT_DEPLOY_STATE_FILE}"
cat "${UAT_DEPLOY_STATE_FILE}" 2>/dev/null || true
