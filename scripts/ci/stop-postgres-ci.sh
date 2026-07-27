#!/usr/bin/env bash
# Stop the localhost E2E postgres container started by start-postgres-ci.sh.
set -euo pipefail

CONTAINER_NAME="${CI_POSTGRES_CONTAINER:-ci-postgres-e2e}"
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
