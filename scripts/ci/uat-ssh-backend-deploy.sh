#!/usr/bin/env bash
# UAT post-FTP backend steps over SSH (single bundled script via workflow Prepare step).
#
# Env:
#   UAT_SITE_ROOT, PKG_CHANGED, POST_RESTART_RETRIES, POST_RESTART_SLEEP_SEC
#   UAT_AUTO_MIGRATE — when "true", run node scripts/migrate.js up before restart
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
UAT_AUTO_MIGRATE="${UAT_AUTO_MIGRATE:-false}"
MIGRATE_AUTO_APPLIED="false"

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

echo "=== Discover Passenger .htaccess (pre-merge) ==="
uat_htaccess_discover_passenger "${SITE_ROOT}" "${APPDIR}"
if [[ -n "${UAT_HT_PASSENGER_SOURCE:-}" ]]; then
  echo "passenger_discovered=${UAT_HT_PASSENGER_SOURCE}"
  echo "passenger_blocks_preserved=$([[ -n "${UAT_HT_PRESERVED_BLOCKS:-}" ]] && echo true || echo false)"
else
  echo "passenger_discovered=none"
  echo "passenger_blocks_preserved=false"
fi

echo "=== Merge SPA .htaccess at domain root ==="
uat_htaccess_apply_spa_merge "${SITE_ROOT}" "${UAT_HT_PRESERVED_BLOCKS:-}"

PASSENGER_EXPECTED_IN_ROOT="false"
if [[ "${UAT_HT_PASSENGER_SOURCE:-}" == "${SITE_ROOT}/.htaccess" ]] \
  || [[ "${UAT_HT_PASSENGER_MERGED_TO_ROOT:-}" == "true" ]]; then
  PASSENGER_EXPECTED_IN_ROOT="true"
fi

echo "=== Verify merged root .htaccess ==="
uat_htaccess_verify_merged_root "${SITE_ROOT}" "$PASSENGER_EXPECTED_IN_ROOT" "${UAT_HT_ROOT_APPLIED:-false}"

echo "=== Re-verify Passenger .htaccess (post-merge) ==="
PASSENGER_HTACCESS_FILE="$(uat_find_passenger_htaccess "${SITE_ROOT}" "${APPDIR}")"
PASSENGER_HTACCESS_OK="false"
if [[ -n "$PASSENGER_HTACCESS_FILE" ]]; then
  PASSENGER_HTACCESS_OK="true"
  echo "OK: Passenger config in ${PASSENGER_HTACCESS_FILE}"
  echo "passenger_htaccess_file=${PASSENGER_HTACCESS_FILE}"
else
  echo "::error::Passenger .htaccess not found at ${SITE_ROOT}/.htaccess or ${APPDIR}/.htaccess"
  echo "Action: cPanel → Setup Node.js App → app root ${APPDIR#"$HOME"/} → startup bin/start.js → Save (regenerates Passenger block) → Restart"
  echo "Note: o2switch usually writes Passenger directives at the domain root — never upload .htaccess via FTP."
  exit 1
fi
export PASSENGER_HTACCESS_OK
export PASSENGER_HTACCESS_FILE

echo "=== node_modules invariant (pre-restart) ==="
uat_nm_assert pre 1 0

echo "=== Database migrations ==="
cd "${APPDIR}"
if ! uat_nm_use_node; then
  echo "::error::node not found in PATH or CloudLinux nodevenv — cannot run migrate.js"
  echo "Expected: ~/nodevenv/uat.agathatrack.com/backend/<version>/bin/node"
  exit 1
fi
echo "node_bin=${UAT_NODE_BIN}"
if [[ "${UAT_AUTO_MIGRATE}" == "true" ]]; then
  echo "UAT_AUTO_MIGRATE=true — applying pending migrations (node scripts/migrate.js up)"
  node scripts/migrate.js up
  MIGRATE_AUTO_APPLIED="true"
else
  echo "UAT_AUTO_MIGRATE is not true — skipping migrate.js up (status only)"
fi

migrate_status_out=""
migrate_pending_count=0
if migrate_status_out="$(node scripts/migrate.js status 2>&1)"; then
  echo "${migrate_status_out}"
  migrate_pending_count="$(
    printf '%s\n' "${migrate_status_out}" \
      | grep -Eo '[0-9]+ applied, [0-9]+ pending\.' \
      | tail -1 \
      | sed -E 's/.*, ([0-9]+) pending\./\1/' || echo 0
  )"
  {
    echo "migrate_status_collected=true"
    echo "migrate_pending_count=${migrate_pending_count}"
    echo "migrate_auto_applied=${MIGRATE_AUTO_APPLIED}"
  } >>"${UAT_DEPLOY_STATE_FILE}"
  if [[ "${migrate_pending_count}" -gt 0 ]]; then
    echo "::warning title=Pending UAT migrations::${migrate_pending_count} migration(s) still pending on UAT."
    if [[ "${UAT_AUTO_MIGRATE}" != "true" ]]; then
      echo "::warning::Set UAT_AUTO_MIGRATE=true in the UAT environment to apply automatically over SSH."
    fi
  fi
else
  echo "::error::node scripts/migrate.js status failed on UAT backend"
  echo "${migrate_status_out}"
  {
    echo "migrate_status_collected=false"
    echo "migrate_pending_count=unknown"
    echo "migrate_auto_applied=${MIGRATE_AUTO_APPLIED}"
  } >>"${UAT_DEPLOY_STATE_FILE}"
  exit 1
fi

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
