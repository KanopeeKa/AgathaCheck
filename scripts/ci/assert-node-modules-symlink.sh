#!/usr/bin/env bash
# Assert CloudLinux nodevenv contract: backend/node_modules must be a symlink into ~/nodevenv/.
#
# Usage (on UAT server or with UAT_APP_DIR overridden):
#   scripts/ci/assert-node-modules-symlink.sh [--phase pre|post] [--retry N] [--sleep SEC]
#
# Exit codes: 0 OK | 10 missing | 11 real_dir | 12 broken_symlink
set -euo pipefail

PHASE="pre"
RETRY_ATTEMPTS=1
RETRY_SLEEP_SEC=10

while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase)
      PHASE="$2"
      shift 2
      ;;
    --retry)
      RETRY_ATTEMPTS="$2"
      shift 2
      ;;
    --sleep)
      RETRY_SLEEP_SEC="$2"
      shift 2
      ;;
    -h | --help)
      sed -n '1,16p' "$0"
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

# shellcheck source=assert-node-modules-symlink.lib.sh
source "$(cd "$(dirname "$0")" && pwd)/assert-node-modules-symlink.lib.sh"

export UAT_SITE_ROOT="${UAT_SITE_ROOT:-$HOME/uat.agathatrack.com}"
export UAT_APP_DIR="${UAT_APP_DIR:-${UAT_SITE_ROOT}/backend}"

uat_nm_assert "$PHASE" "$RETRY_ATTEMPTS" "$RETRY_SLEEP_SEC"
