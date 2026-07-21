#!/usr/bin/env bash
# Start PostgreSQL for Cursor Cloud sessions (see AGENTS.md).
# Tolerates "already running"; fails when the cluster is actually down.
set -euo pipefail

log() { echo ">>> [start:] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

PG_VERSION="${PG_VERSION:-16}"

ensure_postgresql() {
  if command -v pg_ctlcluster >/dev/null 2>&1 && command -v pg_isready >/dev/null 2>&1; then
    return 0
  fi

  log "PostgreSQL tools missing — installing postgresql-${PG_VERSION} (bootstrap fallback)"
  if ! command -v apt-get >/dev/null 2>&1; then
    die "apt-get unavailable; rebuild Cloud environment with .cursor/Dockerfile"
  fi
  sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    "postgresql-${PG_VERSION}" "postgresql-client-${PG_VERSION}"
}

ensure_postgresql

INIT_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/cloud-pg-init.sh"
if [[ -x "$INIT_SCRIPT" ]]; then
  bash "$INIT_SCRIPT"
elif [[ -x /usr/local/bin/agatha-cloud-pg-init.sh ]]; then
  /usr/local/bin/agatha-cloud-pg-init.sh
fi

start_rc=0
sudo pg_ctlcluster "${PG_VERSION}" main start || start_rc=$?

if pg_isready -h localhost -p 5432 -q; then
  log "PostgreSQL ready on localhost:5432"
  exit 0
fi

sudo pg_ctlcluster "${PG_VERSION}" main status >&2 || true
die "PostgreSQL ${PG_VERSION}/main is not accepting connections (pg_ctlcluster exit ${start_rc})"
