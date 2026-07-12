#!/usr/bin/env bash
# Stage server/ for UAT FTP deploy — never include node_modules (CloudLinux symlink on host).
set -euo pipefail

ROOT="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
SRC="${ROOT}/server"
DEST="${ROOT}/.uat-backend-deploy"

rm -rf "$DEST"
mkdir -p "$DEST"

tar -C "$SRC" \
  --exclude=node_modules \
  --exclude=test \
  --exclude=.dart_tool \
  --exclude=coverage \
  --exclude='*.test.js' \
  --exclude=babel.config.cjs \
  --exclude=.env \
  -cf - . | tar -C "$DEST" -xf -

mkdir -p "${DEST}/db" "${DEST}/tmp"
if [ -d "${ROOT}/db/migrations" ]; then
  cp -R "${ROOT}/db/migrations" "${DEST}/db/migrations"
fi
date -u +"restart %Y-%m-%dT%H:%M:%SZ" > "${DEST}/tmp/restart.txt"

if [ -e "${DEST}/node_modules" ] || find "${DEST}" -type d -name node_modules | grep -q .; then
  echo "::error::node_modules found in UAT backend staging dir — aborting FTP deploy"
  exit 1
fi

echo "Staged backend for FTP (${DEST}):"
find "${DEST}" -maxdepth 2 -type d | head -20
echo "::notice::node_modules excluded — on CloudLinux use cPanel Run NPM Install when package.json changes"
