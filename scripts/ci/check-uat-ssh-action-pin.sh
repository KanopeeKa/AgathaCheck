#!/usr/bin/env bash
# Guard: UAT SSH step must pin appleboy/ssh-action to a full SHA (>= v1.2.0 script_path).
set -euo pipefail

WF="${1:-.github/workflows/deploy-uat.yml}"

if [[ ! -f "$WF" ]]; then
  echo "::error::Missing workflow file: $WF" >&2
  exit 1
fi

if grep -qE 'appleboy/ssh-action@v1\.(0|1)\.' "$WF"; then
  echo "::error::${WF} uses appleboy/ssh-action v1.0.x/v1.1.x — script_path is ignored (silent no-op)." >&2
  exit 1
fi

if ! grep -qE 'appleboy/ssh-action@[0-9a-f]{40}' "$WF"; then
  echo "::error::${WF} must pin appleboy/ssh-action to a full commit SHA (not a floating tag)." >&2
  exit 1
fi

if ! grep -q 'script_path: .ci-uat-ssh-remote.sh' "$WF"; then
  echo "::error::${WF} UAT SSH step must use script_path: .ci-uat-ssh-remote.sh" >&2
  exit 1
fi

echo "OK: ${WF} appleboy/ssh-action pin + script_path guard passed."
