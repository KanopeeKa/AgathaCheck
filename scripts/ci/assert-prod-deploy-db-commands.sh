#!/usr/bin/env bash
# Assert production deploy scripts only invoke migrate.js up (no bootstrap/seed/reset).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAIL=0

check_file() {
  local file="$1"
  local label="$2"
  if grep -qE 'bootstrap-db|uat-reset|regenerate-canonical|seed\.js|seed-migration-ledger' "$file"; then
    echo "assert-prod-deploy-db: FAIL $label references destructive/bootstrap commands: $file" >&2
    grep -nE 'bootstrap-db|uat-reset|regenerate-canonical|seed\.js|seed-migration-ledger' "$file" >&2 || true
    FAIL=1
  fi
  if ! grep -q 'migrate\.js up' "$file"; then
    echo "assert-prod-deploy-db: WARN $label has no migrate.js up: $file" >&2
  fi
}

check_file "${ROOT}/.github/workflows/deploy-prod.yml" "deploy-prod.yml"
check_file "${ROOT}/scripts/ci/uat-ssh-backend-deploy.sh" "uat-ssh-backend-deploy.sh"

if [[ "$FAIL" -ne 0 ]]; then
  exit 1
fi

echo "assert-prod-deploy-db: OK (deploy paths use migrate.js up only)"
