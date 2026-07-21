#!/usr/bin/env bash
# Idempotent PostgreSQL dev cluster setup for Cursor Cloud (matches AGENTS.md / e2e).
# Requires the cluster to be running (cloud-start.sh starts it before calling this).
set -euo pipefail

PG_VERSION="${PG_VERSION:-16}"
PG_HBA="/etc/postgresql/${PG_VERSION}/main/pg_hba.conf"

if [[ ! -f "$PG_HBA" ]]; then
  echo "ERROR: PostgreSQL ${PG_VERSION} cluster not found at ${PG_HBA}" >&2
  exit 1
fi

if ! pg_isready -h localhost -p 5432 -q; then
  echo "ERROR: PostgreSQL is not accepting connections — start the cluster before init" >&2
  exit 1
fi

append_hba() {
  local pattern="$1"
  local line="$2"
  if ! sudo grep -qE "$pattern" "$PG_HBA"; then
    echo "$line" | sudo tee -a "$PG_HBA" >/dev/null
  fi
}

append_hba '^\s*host\s+all\s+all\s+127\.0\.0\.1/32\s+' 'host all all 127.0.0.1/32 scram-sha-256'
append_hba '^\s*host\s+all\s+all\s+::1/128\s+' 'host all all ::1/128 scram-sha-256'

sudo -u postgres psql -v ON_ERROR_STOP=0 -tc "SELECT 1 FROM pg_roles WHERE rolname = 'user'" | grep -q 1 \
  || sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE USER \"user\" WITH PASSWORD 'password' CREATEDB LOGIN;"

sudo -u postgres psql -v ON_ERROR_STOP=0 -tc "SELECT 1 FROM pg_database WHERE datname = 'agatha_db'" | grep -q 1 \
  || sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE DATABASE agatha_db OWNER \"user\";"

sudo pg_ctlcluster "${PG_VERSION}" main reload || true

echo "PostgreSQL dev user/database ready (user/password@localhost:5432/agatha_db)"
