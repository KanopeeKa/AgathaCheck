#!/usr/bin/env bash
# Start PostgreSQL for Cursor Cloud sessions (see AGENTS.md).
# Tolerates "already running"; fails when the cluster is actually down.
set -euo pipefail

start_rc=0
sudo pg_ctlcluster 16 main start || start_rc=$?

if pg_isready -h localhost -p 5432 -q; then
  echo "PostgreSQL ready on localhost:5432"
  exit 0
fi

echo "ERROR: PostgreSQL 16/main is not accepting connections (pg_ctlcluster exit ${start_rc})" >&2
sudo pg_ctlcluster 16 main status >&2 || true
exit 1
