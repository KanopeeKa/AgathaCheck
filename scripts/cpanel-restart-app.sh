#!/usr/bin/env bash
# cPanel UAPI — restart the Node.js application after FTP deploy (no SSH required).
#
# o2switch CloudLinux exposes a subset of the standard cPanel UAPI.
# The NodeJS module (NodeJS::restart_application) is NOT available on all o2switch
# plans. When it is missing this script exits 0 with a notice — the SSH restart step
# in the workflow handles the actual Passenger restart in that case.
#
# Required env vars:
#   CPANEL_SERVER  — hostname (same as UAT_SSH_HOST secret, e.g. server42.o2switch.net)
#   CPANEL_USER    — cPanel username (same as UAT_SSH_USER)
#   CPANEL_TOKEN   — cPanel API token (UAT_CPANEL_API_TOKEN)
#   APP_DOMAIN     — domain for the Node.js application (e.g. uat.agathatrack.com)
#
# Optional:
#   NPM_INSTALL    — set to "true" to also run npm install via cPanel NodeJS UAPI.
set -euo pipefail

# shellcheck source=ci/mask-log-value.lib.sh
source "$(cd "$(dirname "$0")" && pwd)/ci/mask-log-value.lib.sh"

CPANEL_SERVER="${CPANEL_SERVER:?CPANEL_SERVER required}"
CPANEL_USER="${CPANEL_USER:?CPANEL_USER required}"
CPANEL_TOKEN="${CPANEL_TOKEN:?CPANEL_TOKEN required}"
APP_DOMAIN="${APP_DOMAIN:?APP_DOMAIN required}"
NPM_INSTALL="${NPM_INSTALL:-false}"
MASKED_SERVER="$(ci_mask_host "$CPANEL_SERVER")"
MASKED_USER="$(ci_mask_user "$CPANEL_USER")"

AUTH="Authorization: cpanel ${CPANEL_USER}:${CPANEL_TOKEN}"
BASE="https://${CPANEL_SERVER}:2083/execute/NodeJS"

cpanel_call() {
  local endpoint="$1"
  shift
  local url="${BASE}/${endpoint}$*"
  local response
  echo "cPanel UAPI → ${endpoint} for ${APP_DOMAIN} (server ${MASKED_SERVER}, user ${MASKED_USER})"
  if ! response="$(curl -sfSm 60 -H "$AUTH" "$url" 2>&1)"; then
    echo "::warning::cPanel UAPI request failed (network): ${endpoint} on server ${MASKED_SERVER}" >&2
    return 1
  fi

  # Detect "module not found" — o2switch does not ship Cpanel::API::NodeJS on all plans.
  if echo "$response" | grep -q "Can't locate Cpanel/API/NodeJS.pm"; then
    echo "::notice::cPanel NodeJS UAPI module is not available on this server."
    echo "::notice::The SSH restart step (UAT_SSH_ENABLED=true) will handle Passenger restart."
    echo "::notice::Alternatively: restart via cPanel → Node.js Apps → Restart."
    return 0
  fi

  if command -v jq >/dev/null 2>&1; then
    local status
    status="$(echo "$response" | jq -r '.status // 0')"
    if [ "$status" != "1" ]; then
      echo "::error::cPanel UAPI error on ${endpoint}: $(echo "$response" | jq -c '.errors // .messages // .')" >&2
      return 1
    fi
    echo "cPanel UAPI ${endpoint} → OK"
    echo "$response" | jq -c '.data // empty'
  else
    echo "$response"
  fi
}

if [ "$NPM_INSTALL" = "true" ]; then
  echo "Running npm install via cPanel NodeJS UAPI (nodevenv-managed, not bare npm)..."
  cpanel_call "npm_install_packages" "?domain=${APP_DOMAIN}" || true
fi

echo "Restarting Node.js application via cPanel UAPI..."
cpanel_call "restart_application" "?domain=${APP_DOMAIN}" || true

echo "::notice::cPanel UAPI restart attempt complete. SSH step will also touch tmp/restart.txt if configured."
