#!/usr/bin/env bash
# Download ~/.uat-deploy-state.env from UAT via SCP and export to GITHUB_OUTPUT.
set -euo pipefail

HOST="${UAT_SSH_HOST:?UAT_SSH_HOST required}"
USER="${UAT_SSH_USER:?UAT_SSH_USER required}"
KEY="${UAT_SSH_PRIVATE_KEY:?UAT_SSH_PRIVATE_KEY required}"
PORT="${UAT_SSH_PORT:-22}"
REMOTE_STATE="${UAT_REMOTE_STATE_FILE:-.uat-deploy-state.env}"
LOCAL_STATE=".uat-deploy-state.env"

eval "$(ssh-agent -s)" >/dev/null
trap 'ssh-agent -k >/dev/null 2>&1 || true' EXIT

key_file="$(mktemp)"
cleanup() { rm -f "$key_file"; }
trap cleanup EXIT

printf '%s\n' "$KEY" >"$key_file"
chmod 600 "$key_file"
ssh-add "$key_file" >/dev/null

mkdir -p ~/.ssh
ssh-keyscan -p "$PORT" -H "$HOST" >>~/.ssh/known_hosts 2>/dev/null || true

scp -P "$PORT" -o BatchMode=yes "${USER}@${HOST}:${REMOTE_STATE}" "$LOCAL_STATE"

if [[ ! -f "$LOCAL_STATE" ]]; then
  echo "::warning::Remote deploy state file not found"
  exit 0
fi

echo "Collected UAT deploy state:"
cat "$LOCAL_STATE"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  while IFS='=' read -r key value; do
    [[ -z "$key" ]] && continue
    echo "${key}=${value}" >>"$GITHUB_OUTPUT"
  done <"$LOCAL_STATE"
fi
