#!/usr/bin/env bash
# Print active Pre-UAT Playwright shard count from e2e/scripts/shard-files.mjs.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
node --input-type=module -e "import { SHARD_TOTAL } from './e2e/scripts/shard-files.mjs'; console.log(SHARD_TOTAL)"
