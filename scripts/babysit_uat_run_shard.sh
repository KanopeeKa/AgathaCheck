#!/usr/bin/env bash
# Run one pre-UAT file-balanced shard locally (requires babysit_uat_bootstrap_stack.sh).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARD="${1:?usage: babysit_uat_run_shard.sh <1-13>}"

export E2E_BASE_URL="${E2E_BASE_URL:-http://localhost:3000}"
cd "${ROOT}/e2e"
npm run test:ci-shard -- "$SHARD"
