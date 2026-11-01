#!/usr/bin/env bash
# Watch pre-uat-e2e.yml for a specific merge commit SHA (the PR you merged).
# Thin wrapper around execute-plan v2 `watch-preuat-sha` (GitHub API client, no gh).
#
# Usage:
#   ./scripts/babysit_uat_watch_preuat.sh <merge_sha> [--json] [--timeout-min 90]
#
# Exit 0 = Pre-UAT gate green for merge_sha
# Exit 1 = failed (prints failed shard indices when detectable)
# Exit 2 = timeout / run not found yet
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec node "$ROOT/scripts/execute_plan_runtime.js" watch-preuat-sha "$@"
