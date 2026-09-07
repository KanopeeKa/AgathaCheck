#!/usr/bin/env bash
# Manual-only: run frozen-domain Jest suites (not part of active CI).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/server"

export ENABLE_FROZEN_DOMAINS=true

if [[ -f jest.config.frozen.cjs ]]; then
  npx jest -c jest.config.frozen.cjs --env=node --forceExit
else
  echo 'jest.config.frozen.cjs not found — frozen server tests unavailable.'
  exit 1
fi
