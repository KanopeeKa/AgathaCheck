#!/usr/bin/env bash
# Download ~/.uat-deploy-state.env from UAT via SSH and export to GITHUB_OUTPUT.
# Non-blocking: invariant may pass even when state collection fails (summary fields stay n/a).
set -euo pipefail

HOST="${UAT_SSH_HOST:?UAT_SSH_HOST required}"
USER="${UAT_SSH_USER:?UAT_SSH_USER required}"
KEY="${UAT_SSH_PRIVATE_KEY:?UAT_SSH_PRIVATE_KEY required}"
PORT="${UAT_SSH_PORT:-22}"
REMOTE_STATE="${UAT_REMOTE_STATE_FILE:-\$HOME/.uat-deploy-state.env}"
LOCAL_STATE=".uat-deploy-state.env"

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

collect_failed() {
  echo "::warning::Could not collect remote deploy state from ${REMOTE_STATE}"
  echo "::warning::SSH invariant may still have passed — summary fingerprint fields will be n/a"
  exit 0
}

# Prefer ssh cat with explicit $HOME — avoids scp relative-path ambiguity on cPanel shells.
if ! ssh "${ssh_opts[@]}" "$ssh_target" "cat ${REMOTE_STATE}" >"$LOCAL_STATE" 2>/dev/null; then
  if ! scp -P "$PORT" -o BatchMode=yes "${ssh_target}:~/.uat-deploy-state.env" "$LOCAL_STATE" 2>/dev/null; then
    collect_failed
  fi
fi

if [[ ! -s "$LOCAL_STATE" ]]; then
  collect_failed
fi

echo "Collected UAT deploy state:"
cat "$LOCAL_STATE"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  while IFS='=' read -r key value; do
    [[ -z "$key" ]] && continue
    echo "${key}=${value}" >>"$GITHUB_OUTPUT"
  done <"$LOCAL_STATE"
fi
