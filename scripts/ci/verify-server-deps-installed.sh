#!/usr/bin/env bash
# Verify runtime dependencies from server/package.json resolve in node_modules.
# Fails closed when FTP-deployed code references packages missing from nodevenv.
#
# Usage:
#   UAT_APP_DIR=~/uat.agathatrack.com/backend bash scripts/ci/verify-server-deps-installed.sh
set -euo pipefail

# shellcheck source=assert-node-modules-symlink.lib.sh
source "$(cd "$(dirname "$0")" && pwd)/assert-node-modules-symlink.lib.sh"

APPDIR="${UAT_APP_DIR:-${PROD_APP_DIR:-}}"

if [[ -z "$APPDIR" || ! -f "${APPDIR}/package.json" ]]; then
  echo "::error::verify-server-deps: APPDIR missing or no package.json (set UAT_APP_DIR or PROD_APP_DIR)" >&2
  exit 1
fi

cd "${APPDIR}"

if ! uat_nm_use_node; then
  echo "::error::node not found in PATH or CloudLinux nodevenv — cannot verify dependencies" >&2
  exit 1
fi

missing="$(
  node --input-type=module - <<'NODE'
import fs from 'fs';
import { createRequire } from 'module';

const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
const req = createRequire(import.meta.url);
const missing = [];
for (const name of Object.keys(pkg.dependencies || {})) {
  try {
    req.resolve(`${name}/package.json`);
  } catch {
    missing.push(name);
  }
}
if (missing.length) {
  process.stdout.write(missing.join(' '));
  process.exit(1);
}
NODE
)" || {
  echo "::error title=Missing npm dependencies::Runtime packages not installed in node_modules: ${missing}"
  echo "::error::cPanel → Setup Node.js App → Run NPM Install → Restart (CloudLinux nodevenv symlink)."
  echo "::error::See docs/pipelines/uat-backend-node-modules-runbook.md"
  exit 1
}

echo "OK: all server/package.json dependencies resolve in node_modules"
