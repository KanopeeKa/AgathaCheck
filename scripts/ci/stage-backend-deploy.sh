#!/usr/bin/env bash
# Stage server/ for FTP deploy (UAT + PROD). Never include node_modules.
set -euo pipefail

ROOT="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/../.." && pwd)}"
SRC="${ROOT}/server"
DEST_REL=".backend-deploy-staging"
TARGET=""

usage() {
  echo "usage: stage-backend-deploy.sh [--dest <relative-dir>] [--target uat|prod]" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dest)
      DEST_REL="$2"
      shift 2
      ;;
    --target)
      TARGET="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

case "$TARGET" in
  uat) DEST_REL=".uat-backend-deploy" ;;
  prod) DEST_REL=".prod-backend-deploy" ;;
  '') ;;
  *)
    echo "::error::unknown --target '${TARGET}' (expected uat or prod)" >&2
    exit 1
    ;;
esac

DEST="${ROOT}/${DEST_REL}"

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

mkdir -p "${DEST}/db" "${DEST}/db/schema" "${DEST}/tmp"
if [[ -d "${ROOT}/db/migrations" ]]; then
  cp -R "${ROOT}/db/migrations" "${DEST}/db/migrations"
fi
if [[ -f "${ROOT}/db/schema/migration-manifest.json" ]]; then
  cp "${ROOT}/db/schema/migration-manifest.json" "${DEST}/db/schema/migration-manifest.json"
fi
date -u +"restart %Y-%m-%dT%H:%M:%SZ" > "${DEST}/tmp/restart.txt"

if [[ -e "${DEST}/node_modules" ]] || find "${DEST}" -type d -name node_modules | grep -q .; then
  echo "::error::node_modules found in backend staging dir (${DEST_REL}) — aborting FTP deploy" >&2
  exit 1
fi

migration_count="$(find "${DEST}/db/migrations" -maxdepth 1 -name '*.sql' 2>/dev/null | wc -l | tr -d ' ')"
echo "Staged backend for FTP (${DEST_REL}, ${migration_count} migration file(s)):"
find "${DEST}" -maxdepth 2 -type d | head -20
echo "::notice::node_modules excluded — on CloudLinux use cPanel Run NPM Install when package.json changes"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "staging_dir=${DEST_REL}"
    echo "migration_count=${migration_count}"
  } >> "$GITHUB_OUTPUT"
fi

bash "$(cd "$(dirname "$0")" && pwd)/append-summary.sh" "Backend FTP staging" \
  "staging_dir=${DEST_REL}" \
  "migration_count=${migration_count}" \
  "target=${TARGET:-custom}"
