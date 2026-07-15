#!/usr/bin/env bash
# Backward-compatible wrapper — use scripts/ci/stage-backend-deploy.sh directly.
set -euo pipefail
echo "::notice::stage-uat-backend-deploy.sh is deprecated — use scripts/ci/stage-backend-deploy.sh --target uat"
exec bash "$(cd "$(dirname "$0")" && pwd)/ci/stage-backend-deploy.sh" --target uat "$@"
