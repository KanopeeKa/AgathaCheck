#!/usr/bin/env bash
# o2switch cPanel SshWhitelist API — dynamic GitHub runner allowlist for port 22.
# https://faq.o2switch.fr/cpanel/outils/exception-parefeu/
set -euo pipefail

# shellcheck source=ci/mask-log-value.lib.sh
source "$(cd "$(dirname "$0")" && pwd)/ci/mask-log-value.lib.sh"

ACTION="${1:?usage: remove_all | add | list | remove}"

CPANEL_SERVER="${CPANEL_SERVER:?CPANEL_SERVER required}"
CPANEL_USER="${CPANEL_USER:?CPANEL_USER required}"
CPANEL_TOKEN="${CPANEL_TOKEN:?CPANEL_TOKEN required}"
MASKED_SERVER="$(ci_mask_host "$CPANEL_SERVER")"

PORT="${SSH_PORT:-22}"
RUNNER_IP="${RUNNER_IP:-}"

AUTH="Authorization: cpanel ${CPANEL_USER}:${CPANEL_TOKEN}"
BASE="https://${CPANEL_SERVER}:2083/execute/SshWhitelist"

curl_api() {
  local endpoint="$1"
  local url="${BASE}/${endpoint}"
  local response
  if ! response="$(curl -sfSm 45 -H "$AUTH" "$url")"; then
    echo "::error::o2switch SshWhitelist API request failed on server ${MASKED_SERVER}" >&2
    exit 1
  fi
  if command -v jq >/dev/null 2>&1; then
    local status
    status="$(echo "$response" | jq -r '.status // empty')"
    if [ "$status" != "1" ]; then
      echo "::error::o2switch API error: $(echo "$response" | jq -c '.errors // .messages // .')" >&2
      exit 1
    fi
  fi
  echo "$response"
}

case "$ACTION" in
  remove_all)
    echo "Clearing o2switch SSH whitelist slots on ${MASKED_SERVER} (CI reset)..."
    curl_api "remove_all"
    ;;
  add)
    [ -n "$RUNNER_IP" ] || { echo "::error::RUNNER_IP required for add" >&2; exit 1; }
    echo "Whitelisting runner IP ${RUNNER_IP} on port ${PORT} (${MASKED_SERVER})..."
    curl_api "add?address=${RUNNER_IP}&port=${PORT}"
    ;;
  list)
    curl_api "list"
    ;;
  remove)
    [ -n "$RUNNER_IP" ] || { echo "::error::RUNNER_IP required for remove" >&2; exit 1; }
    echo "Removing runner IP ${RUNNER_IP} from SSH whitelist..."
    for direction in in out; do
      curl -sfSm 45 -H "$AUTH" \
        "${BASE}/remove?address=${RUNNER_IP}&port=${PORT}&direction=${direction}" \
        >/dev/null || true
    done
    ;;
  *)
    echo "Unknown action: $ACTION" >&2
    exit 1
    ;;
esac
