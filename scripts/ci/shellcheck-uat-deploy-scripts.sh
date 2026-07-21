#!/usr/bin/env bash
# Shellcheck UAT deploy CI scripts (sourced libs use -x).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "::error::shellcheck not installed — apt install shellcheck or brew install shellcheck" >&2
  exit 1
fi

mapfile -t FILES < <(
  find scripts/ci -maxdepth 1 -name '*.sh' \( \
    -name 'assert-uat-ssh-deploy-proofs.sh' -o \
    -name 'assert-node-modules-symlink*.sh' -o \
    -name 'check-uat-ssh-action-pin.sh' -o \
    -name 'uat-collect-deploy-state.sh' -o \
    -name 'uat-ssh-backend-deploy.sh' -o \
    -name 'uat-htaccess.lib.sh' -o \
    -name 'uat-e2e-env.lib.sh' -o \
    -name 'prepare-uat-ssh-remote.sh' -o \
    -name 'mask-log-value.lib.sh' \
  \) | sort
)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "::error::No UAT deploy scripts found for shellcheck" >&2
  exit 1
fi

echo "Shellcheck UAT deploy scripts (${#FILES[@]}):"
printf '  %s\n' "${FILES[@]}"

# -x follows shellcheck source= directives; exclude SC1091 (not following in CI without full paths).
shellcheck -x -e SC1091 -S warning "${FILES[@]}"
echo "Shellcheck passed."
