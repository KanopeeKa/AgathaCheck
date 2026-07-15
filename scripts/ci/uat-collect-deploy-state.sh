#!/usr/bin/env bash
# Download ~/.uat-deploy-state.env from UAT via SSH and export to GITHUB_OUTPUT.
set -euo pipefail

HOST="${UAT_SSH_HOST:?UAT_SSH_HOST required}"
USER="${UAT_SSH_USER:?UAT_SSH_USER required}"
KEY="${UAT_SSH_PRIVATE_KEY:?UAT_SSH_PRIVATE_KEY required}"
PORT="${UAT_SSH_PORT:-22}"
REMOTE_STATE="${UAT_REMOTE_STATE_FILE:-\$HOME/.uat-deploy-state.env}"
LOCAL_STATE=".uat-deploy-state.env"
GITHUB_EVENT_NAME="${GITHUB_EVENT_NAME:-push}"

eval "$(ssh-agent -s)" >/dev/null

key_file="$(mktemp)"
cleanup() {
  rm -f "$key_file"
  ssh-agent -k >/dev/null 2>&1 || true
}
trap cleanup EXIT

printf '%s\n' "$KEY" >"$key_file"
chmod 600 "$key_file"
ssh-add "$key_file" >/dev/null

mkdir -p ~/.ssh
ssh-keyscan -p "$PORT" -H "$HOST" >>~/.ssh/known_hosts 2>/dev/null || true

ssh_target="${USER}@${HOST}"
ssh_opts=(-p "$PORT" -o BatchMode=yes -o StrictHostKeyChecking=yes)

state_field() {
  local key="$1"
  grep -E "^${key}=" "$LOCAL_STATE" 2>/dev/null | tail -1 | cut -d= -f2- || true
}

collect_failed() {
  local reason="$1"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "state_collected=false" >>"$GITHUB_OUTPUT"
  fi
  echo "::error::UAT deploy state collection failed: ${reason}" >&2
  if [[ "$GITHUB_EVENT_NAME" == "workflow_dispatch" ]]; then
    exit 1
  fi
  echo "::warning title=UAT_SSH_DEPLOY_STATE_MISSING::${reason}" >&2
  echo "UAT_SSH_DEPLOY_STATE_MISSING reason=${reason}"
  echo "::warning::Push deploy continuing without collected SSH proofs — smoke may fail."
  exit 0
}

# Prefer ssh cat with explicit $HOME — avoids scp relative-path ambiguity on cPanel shells.
if ! ssh "${ssh_opts[@]}" "$ssh_target" "cat ${REMOTE_STATE}" >"$LOCAL_STATE" 2>/dev/null; then
  if ! scp -P "$PORT" -o BatchMode=yes "${ssh_target}:~/.uat-deploy-state.env" "$LOCAL_STATE" 2>/dev/null; then
    collect_failed "remote state file not found (~/.uat-deploy-state.env)"
  fi
fi

if [[ ! -s "$LOCAL_STATE" ]]; then
  collect_failed "remote state file is empty"
fi

if [[ "$(state_field ssh_deploy_end)" != "true" ]]; then
  collect_failed "ssh_deploy_end=true missing — remote UAT SSH script likely did not run"
fi

echo "Collected UAT deploy state:"
cat "$LOCAL_STATE"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "state_collected=true" >>"$GITHUB_OUTPUT"
  while IFS='=' read -r key value; do
    [[ -z "$key" ]] && continue
    echo "${key}=${value}" >>"$GITHUB_OUTPUT"
  done <"$LOCAL_STATE"
fi
