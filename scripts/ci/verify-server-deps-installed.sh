#!/usr/bin/env bash
# Verify runtime dependencies from server/package.json resolve in node_modules.
# Fails closed when FTP-deployed code references packages missing from nodevenv.
#
# Usage:
#   UAT_APP_DIR=~/uat.agathatrack.com/backend bash scripts/ci/verify-server-deps-installed.sh
set -euo pipefail

# shellcheck source=assert-node-modules-symlink.lib.sh
source "$(cd "$(dirname "$0")" && pwd)/assert-node-modules-symlink.lib.sh"

uat_nm_verify_server_deps
