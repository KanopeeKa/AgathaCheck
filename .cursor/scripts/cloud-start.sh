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

wait_for_postgres() {
  local attempt
  for attempt in $(seq 1 30); do
    if pg_isready -h localhost -p 5432 -q; then
      return 0
    fi
    sleep 1
  done
  return 1
}

ensure_postgresql

start_rc=0
sudo pg_ctlcluster "${PG_VERSION}" main start || start_rc=$?

if ! wait_for_postgres; then
  sudo pg_ctlcluster "${PG_VERSION}" main status >&2 || true
  die "PostgreSQL ${PG_VERSION}/main is not accepting connections (pg_ctlcluster exit ${start_rc})"
fi

INIT_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/cloud-pg-init.sh"
if [[ -f "$INIT_SCRIPT" ]]; then
  bash "$INIT_SCRIPT"
elif [[ -f /usr/local/bin/agatha-cloud-pg-init.sh ]]; then
  bash /usr/local/bin/agatha-cloud-pg-init.sh
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BOOTSTRAP_DB="${ROOT}/e2e/scripts/bootstrap-db.sh"
if [[ -f "$BOOTSTRAP_DB" ]]; then
  log "ensuring database schema (bootstrap-db)"
  bash "$BOOTSTRAP_DB"
else
  log "bootstrap-db.sh not found — skipping schema bootstrap"
fi

if pg_isready -h localhost -p 5432 -q; then
  log "PostgreSQL ready on localhost:5432"
  exit 0
fi

sudo pg_ctlcluster "${PG_VERSION}" main status >&2 || true
die "PostgreSQL ${PG_VERSION}/main is not accepting connections after init"
