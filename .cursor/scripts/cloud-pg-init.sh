#!/usr/bin/env bash
# Idempotent PostgreSQL dev cluster setup for Cursor Cloud (matches AGENTS.md / e2e).
set -euo pipefail

PG_VERSION="${PG_VERSION:-16}"
PG_HBA="/etc/postgresql/${PG_VERSION}/main/pg_hba.conf"
PG_CONF="/etc/postgresql/${PG_VERSION}/main/postgresql.conf"

if [[ ! -f "$PG_HBA" ]]; then
  echo "ERROR: PostgreSQL ${PG_VERSION} cluster not found at ${PG_HBA}" >&2
  exit 1
fi

if ! grep -qE '^\s*host\s+all\s+all\s+127\.0\.0\.1/32\s+' "$PG_HBA"; then
  echo "host all all 127.0.0.1/32 scram-sha-256" >>"$PG_HBA"
fi
if ! grep -qE '^\s*host\s+all\s+all\s+::1/128\s+' "$PG_HBA"; then
  echo "host all all ::1/128 scram-sha-256" >>"$PG_HBA"
fi

if [[ -f "$PG_CONF" ]] && ! grep -qE "^\s*listen_addresses\s*=" "$PG_CONF"; then
  echo "listen_addresses = 'localhost'" >>"$PG_CONF"
fi

sudo -u postgres psql -v ON_ERROR_STOP=0 -tc "SELECT 1 FROM pg_roles WHERE rolname = 'user'" | grep -q 1 \
  || sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE USER \"user\" WITH PASSWORD 'password' SUPERUSER CREATEDB;"

sudo -u postgres psql -v ON_ERROR_STOP=0 -tc "SELECT 1 FROM pg_database WHERE datname = 'agatha_db'" | grep -q 1 \
  || sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE DATABASE agatha_db OWNER \"user\";"

if pg_ctlcluster "${PG_VERSION}" main status >/dev/null 2>&1; then
  pg_ctlcluster "${PG_VERSION}" main reload || true
fi

echo "PostgreSQL dev user/database ready (user/password@localhost:5432/agatha_db)"
