#!/usr/bin/env bash
# Backward-compatible wrapper — use scripts/ci/stage-backend-deploy.sh directly.
set -euo pipefail
exec bash "$(cd "$(dirname "$0")" && pwd)/ci/stage-backend-deploy.sh" --target uat "$@"
