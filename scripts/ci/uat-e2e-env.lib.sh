# Ensure UAT backend .env has CI E2E flags (rate-limit skip + signup bypass).
# Sourced by uat-ssh-backend-deploy.sh — bundled into .ci-uat-ssh-remote.sh for SSH.
# shellcheck shell=bash

# Set or replace KEY=VALUE in envfile (safe for special characters in value).
uat_ensure_env_kv() {
  local envfile="$1" key="$2" value="$3"
  local tmp
  tmp="$(mktemp)"
  if [[ -f "$envfile" ]]; then
    grep -v "^${key}=" "$envfile" >"$tmp" || true
  fi
  printf '%s=%s\n' "$key" "$value" >>"$tmp"
  mv "$tmp" "$envfile"
  chmod 600 "$envfile"
}

# E2E=1 disables auth + API rate limits for CI smoke (UAT-only — never production).
# E2E_BYPASS_* allows audited signup bypass when the token is configured.
uat_ensure_e2e_env() {
  local envfile="$1"
  local bypass_token="${2:-}"

  if [[ ! -f "$envfile" ]]; then
    touch "$envfile"
    chmod 600 "$envfile"
  fi

  uat_ensure_env_kv "$envfile" E2E 1
  uat_ensure_env_kv "$envfile" E2E_BYPASS_ALLOWED true
  if [[ -n "$bypass_token" ]]; then
    uat_ensure_env_kv "$envfile" E2E_BYPASS_TOKEN "$bypass_token"
    echo "e2e_env=E2E=1,E2E_BYPASS_ALLOWED=true,E2E_BYPASS_TOKEN=set"
  else
    echo "e2e_env=E2E=1,E2E_BYPASS_ALLOWED=true,E2E_BYPASS_TOKEN=unchanged"
    echo "::warning::E2E_BYPASS_TOKEN not passed to SSH deploy — existing .env token retained (if any)"
  fi
}
