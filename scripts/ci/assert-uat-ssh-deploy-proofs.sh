#!/usr/bin/env bash
# Validate UAT SSH deploy left proof signals before smoke / prod-ready.
set -euo pipefail

SSH_INVARIANT_ENFORCED="${SSH_INVARIANT_ENFORCED:-false}"
SSH_INVARIANT="${SSH_INVARIANT:-skipped}"
STATE_COLLECTED="${STATE_COLLECTED:-false}"
NODE_MODULES_KIND="${NODE_MODULES_KIND:-not_verified}"
PASSENGER_HTACCESS_OK="${PASSENGER_HTACCESS_OK:-not_verified}"
SSH_DEPLOY_END="${SSH_DEPLOY_END:-false}"
RESTART_TXT_EPOCH="${RESTART_TXT_EPOCH:-0}"
JOB_START_EPOCH="${JOB_START_EPOCH:-0}"
GITHUB_EVENT_NAME="${GITHUB_EVENT_NAME:-push}"

write_outputs() {
  local verification="$1"
  local proofs_ok="$2"
  local pre_smoke="$3"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    {
      echo "deploy_verification=${verification}"
      echo "ssh_proofs_ok=${proofs_ok}"
      echo "pre_smoke_ok=${pre_smoke}"
    } >>"$GITHUB_OUTPUT"
  fi
}

if [[ "$SSH_INVARIANT_ENFORCED" != "true" ]]; then
  write_outputs unverified skipped true
  echo "SSH invariant not enforced — proof checks skipped."
  exit 0
fi

if [[ "$SSH_INVARIANT" != "passed" ]]; then
  write_outputs unverified false false
  echo "::error::SSH invariant step did not pass — cannot verify deploy."
  exit 1
fi

reasons=()
proofs_ok=true

if [[ "$STATE_COLLECTED" != "true" ]]; then
  proofs_ok=false
  reasons+=("state file not collected")
fi
if [[ "$SSH_DEPLOY_END" != "true" ]]; then
  proofs_ok=false
  reasons+=("ssh_deploy_end!=true")
fi
if [[ "$NODE_MODULES_KIND" != "symlink" ]]; then
  proofs_ok=false
  reasons+=("node_modules_kind=${NODE_MODULES_KIND}")
fi
if [[ "$PASSENGER_HTACCESS_OK" != "true" ]]; then
  proofs_ok=false
  reasons+=("passenger_htaccess_ok=${PASSENGER_HTACCESS_OK}")
fi

if [[ "$RESTART_TXT_EPOCH" =~ ^[0-9]+$ ]] && [[ "$JOB_START_EPOCH" =~ ^[0-9]+$ ]] && [[ "$JOB_START_EPOCH" -gt 0 ]]; then
  slack=120
  min_epoch=$((JOB_START_EPOCH - slack))
  if [[ "$RESTART_TXT_EPOCH" -lt "$min_epoch" ]]; then
    proofs_ok=false
    reasons+=("restart_txt_epoch=${RESTART_TXT_EPOCH} older than deploy job start (${JOB_START_EPOCH})")
  fi
else
  proofs_ok=false
  reasons+=("restart_txt_epoch or job start epoch unavailable")
fi

if [[ "$proofs_ok" == "true" ]]; then
  write_outputs verified true true
  echo "UAT SSH deploy proofs verified."
  exit 0
fi

write_outputs unverified false false
msg="SSH deploy proofs incomplete: ${reasons[*]}"
if [[ "$GITHUB_EVENT_NAME" == "workflow_dispatch" ]]; then
  echo "::error::${msg}" >&2
  exit 1
fi

echo "::warning title=UAT_SSH_PROOFS_INCOMPLETE::${msg}" >&2
echo "UAT_SSH_PROOFS_INCOMPLETE reasons=${reasons[*]}"
echo "::warning::Push deploy continuing — smoke gate will require proofs."
exit 0
