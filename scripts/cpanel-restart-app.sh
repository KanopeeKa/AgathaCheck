#!/usr/bin/env bash
# cPanel UAPI — restart the Node.js application after FTP deploy (no SSH required).
#
# o2switch CloudLinux exposes the standard cPanel NodeJS UAPI module at port 2083.
# "restart_application" touches the app's restart file via the cPanel daemon, which
# is equivalent to `touch tmp/restart.txt` done through Passenger — without SSH.
#
# Required env vars:
#   CPANEL_SERVER  — hostname (same as UAT_SSH_HOST secret, e.g. server42.o2switch.net)
#   CPANEL_USER    — cPanel username (same as UAT_SSH_USER)
#   CPANEL_TOKEN   — cPanel API token (UAT_CPANEL_API_TOKEN)
#   APP_DOMAIN     — domain for the Node.js application (e.g. uat.agathatrack.com)
#
# Optional:
#   NPM_INSTALL    — set to "true" to also run npm install via cPanel NodeJS UAPI.
#                    Only set this when package.json actually changed. On o2switch,
#                    "npm_install_packages" runs inside nodevenv — never a bare npm install.
set -euo pipefail

CPANEL_SERVER="${CPANEL_SERVER:?CPANEL_SERVER required}"
CPANEL_USER="${CPANEL_USER:?CPANEL_USER required}"
CPANEL_TOKEN="${CPANEL_TOKEN:?CPANEL_TOKEN required}"
APP_DOMAIN="${APP_DOMAIN:?APP_DOMAIN required}"
NPM_INSTALL="${NPM_INSTALL:-false}"

AUTH="Authorization: cpanel ${CPANEL_USER}:${CPANEL_TOKEN}"
BASE="https://${CPANEL_SERVER}:2083/execute/NodeJS"

cpanel_call() {
  local endpoint="$1"
  shift
  local url="${BASE}/${endpoint}$*"
  local response
  echo "cPanel UAPI → ${endpoint} for ${APP_DOMAIN}"
  if ! response="$(curl -sfSm 60 -H "$AUTH" "$url")"; then
    echo "::error::cPanel UAPI request failed: ${url}" >&2
    exit 1
  fi
  # cPanel UAPI wraps results: {"status":1,"data":...} on success, {"status":0,"errors":[...]} on failure
  if command -v jq >/dev/null 2>&1; then
    local status
    status="$(echo "$response" | jq -r '.status // 0')"
    if [ "$status" != "1" ]; then
      echo "::error::cPanel UAPI error on ${endpoint}: $(echo "$response" | jq -c '.errors // .messages // .')" >&2
      exit 1
    fi
    echo "cPanel UAPI ${endpoint} → OK"
    echo "$response" | jq -c '.data // empty'
  else
    echo "$response"
  fi
}

if [ "$NPM_INSTALL" = "true" ]; then
  echo "Running npm install via cPanel NodeJS UAPI (nodevenv-managed, not bare npm)..."
  # This installs packages into the virtual environment under nodevenv/, never into node_modules/ directly.
  cpanel_call "npm_install_packages" "?domain=${APP_DOMAIN}"
fi

echo "Restarting Node.js application via cPanel UAPI..."
cpanel_call "restart_application" "?domain=${APP_DOMAIN}"

echo "::notice::Node.js app restarted via cPanel UAPI. Passenger will pick up new files from FTP."
