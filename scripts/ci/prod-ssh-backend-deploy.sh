#!/usr/bin/env bash
# PROD post-FTP backend steps over SSH (migrate + Passenger restart).
#
# Env:
#   PROD_SITE_ROOT — default ~/agathatrack.com (o2switch addon-domain layout)
#   PKG_CHANGED — when "true", logs manual cPanel Run NPM Install reminder
set -euo pipefail

# shellcheck source=assert-node-modules-symlink.lib.sh
source "$(cd "$(dirname "$0")" && pwd)/assert-node-modules-symlink.lib.sh"

HOME="$(uat_nm_home_dir)"
export HOME
PROD_SITE_ROOT="${PROD_SITE_ROOT:-${HOME}/agathatrack.com}"
APPDIR="${PROD_SITE_ROOT}/backend"
PKG_CHANGED="${PKG_CHANGED:-false}"

export UAT_APP_DIR="$APPDIR"

echo "PROD_SSH_DEPLOY_BEGIN"
echo "=== PROD SSH backend deploy ==="
echo "site_root=${PROD_SITE_ROOT}"
echo "app_dir=${APPDIR}"
echo "pkg_changed=${PKG_CHANGED}"

echo "pkg_changed=${PKG_CHANGED}"

if [[ ! -f "${APPDIR}/package.json" ]]; then
  echo "::error::${APPDIR}/package.json missing after FTP deploy." >&2
  echo "::error::PROD FTP account is likely jailed to a subfolder (e.g. agathatrack.com/PROD_user)." >&2
  echo "::error::Fix cPanel → FTP Accounts → set Directory to /home/<cpanel-user>/agathatrack.com (same pattern as UAT → uat.agathatrack.com)." >&2
  echo "::error::Then move misplaced files up and re-run deploy. See DEPLOYMENT_CPANEL_NODEJS.md." >&2
  exit 1
fi

if [[ "$PKG_CHANGED" == "true" ]]; then
  echo "::warning title=Dependencies changed::server/package.json or package-lock.json changed in this deploy."
  echo "::warning::Manual action required: cPanel → Setup Node.js App → Run NPM Install → Restart"
fi

echo "=== node_modules check (pre-migrate) ==="
if [[ -L "${APPDIR}/node_modules" ]]; then
  echo "node_modules_kind=symlink"
  echo "node_modules_target=$(readlink -f "${APPDIR}/node_modules" 2>/dev/null || readlink "${APPDIR}/node_modules")"
elif [[ -d "${APPDIR}/node_modules" ]]; then
  echo "::warning::node_modules is a real directory — use cPanel Run NPM Install to restore nodevenv symlink"
  echo "node_modules_kind=directory"
else
  echo "::warning::node_modules missing — run cPanel Run NPM Install before relying on backend"
  echo "node_modules_kind=missing"
fi

echo "=== Database migrations ==="
cd "${APPDIR}"
if ! uat_nm_use_node; then
  echo "::error::node not found in PATH or CloudLinux nodevenv — cannot run migrate.js"
  exit 1
fi
echo "node_bin=${UAT_NODE_BIN}"
node scripts/migrate.js up

echo "=== Triggering Passenger restart ==="
mkdir -p "${APPDIR}/tmp"
touch "${APPDIR}/tmp/restart.txt"
echo "Passenger restart triggered via tmp/restart.txt"

echo "PROD_SSH_DEPLOY_END"
echo "=== PROD SSH backend deploy complete ==="
