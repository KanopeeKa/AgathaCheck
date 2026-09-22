#!/usr/bin/env bash
# Merge coordination preflight for /babysit-plus (mutex + FIFO yield).
# See docs/agent-efficiency/autonomous-pr-policy.md §Merge coordination.
#
# Usage:
#   ./scripts/babysit_merge_preflight.sh --pr <url|num> [--json]
#   ./scripts/babysit_merge_preflight.sh --pr <url|num> --claim [--force] [--json]
#   ./scripts/babysit_merge_preflight.sh --pr <url|num> --release [--json]
#
# Exit codes: 0 clear, 1 rebase, 2 wait, 3 error
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec node "$ROOT/scripts/babysit_merge_preflight.mjs" "$@"
