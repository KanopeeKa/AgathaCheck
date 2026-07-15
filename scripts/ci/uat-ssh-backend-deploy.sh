#!/usr/bin/env bash
# UAT post-FTP backend steps over SSH (single bundled script via workflow Prepare step).
#
# Env:
#   UAT_SITE_ROOT, PKG_CHANGED, POST_RESTART_RETRIES, POST_RESTART_SLEEP_SEC
set -euo pipefail

# shellcheck source=assert-node-modules-symlink.lib.sh
source "$(cd "$(dirname "$0")" && pwd)/assert-node-modules-symlink.lib.sh"
# shellcheck source=uat-htaccess.lib.sh
source "$(cd "$(dirname "$0")" && pwd)/uat-htaccess.lib.sh"

HOME="$(uat_nm_home_dir)"
export HOME
UAT_DEPLOY_STATE_FILE="$(uat_nm_state_file)"
export UAT_DEPLOY_STATE_FILE

SITE_ROOT="${UAT_SITE_ROOT:-${HOME}/uat.agathatrack.com}"
APPDIR="${SITE_ROOT}/backend"
POST_RESTART_RETRIES="${POST_RESTART_RETRIES:-3}"
POST_RESTART_SLEEP_SEC="${POST_RESTART_SLEEP_SEC:-10}"
PKG_CHANGED="${PKG_CHANGED:-false}"

export UAT_SITE_ROOT
export UAT_APP_DIR="$APPDIR"

echo "UAT_SSH_DEPLOY_BEGIN"
echo "=== UAT SSH backend deploy ==="
echo "site_root=${SITE_ROOT}"
echo "app_dir=${APPDIR}"
echo "pkg_changed=${PKG_CHANGED}"

if [[ "$PKG_CHANGED" == "true" ]]; then
  echo "::warning title=Dependencies changed::server/package.json or package-lock.json changed in this deploy."
  echo "::warning::Manual action required: cPanel → Setup Node.js App → Run NPM Install → Restart"
fi

echo "=== SPA .htaccess at domain root ==="
uat_install_root_htaccess "${SITE_ROOT}"

echo "=== Passenger .htaccess ==="
PASSENGER_HTACCESS_FILE="$(uat_find_passenger_htaccess "${SITE_ROOT}" "${APPDIR}")"
PASSENGER_HTACCESS_OK="false"
if [[ -n "$PASSENGER_HTACCESS_FILE" ]]; then
  PASSENGER_HTACCESS_OK="true"
  echo "OK: Passenger config in ${PASSENGER_HTACCESS_FILE}"
else
  echo "::error::Passenger .htaccess not found at ${SITE_ROOT}/.htaccess or ${APPDIR}/.htaccess"
  echo "Action: cPanel → Setup Node.js App → app root ${APPDIR#"$HOME"/} → startup bin/start.js → Save (regenerates Passenger block) → Restart"
  echo "Note: o2switch usually writes Passenger directives at the domain root — never upload .htaccess via FTP."
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

uat_nm_finalize_deploy_proofs
echo "UAT_SSH_DEPLOY_END"
echo "=== UAT SSH backend deploy complete ==="
echo "deploy_state_file=${UAT_DEPLOY_STATE_FILE}"
cat "${UAT_DEPLOY_STATE_FILE}" 2>/dev/null || true
