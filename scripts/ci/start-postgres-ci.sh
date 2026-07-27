#!/usr/bin/env bash
# Start postgres:16 for localhost E2E (pull with retry, then health-wait).
#
# Replaces the workflow services.postgres block so we control pull retries beyond
# GitHub's built-in service-container backoff (3 attempts).
set -euo pipefail

CONTAINER_NAME="${CI_POSTGRES_CONTAINER:-ci-postgres-e2e}"
IMAGE="${CI_POSTGRES_IMAGE:-postgres:16}"

bash scripts/ci/docker-pull-retry.sh "$IMAGE"

docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

docker run -d --name "$CONTAINER_NAME" \
  -e POSTGRES_USER=user \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=agatha_db \
  -p 5432:5432 \
  "$IMAGE"

for attempt in $(seq 1 30); do
  if docker exec "$CONTAINER_NAME" pg_isready -U user -d agatha_db >/dev/null 2>&1; then
    echo "PostgreSQL ready (${attempt}/30)"
    exit 0
  fi
  echo "Waiting for PostgreSQL (${attempt}/30)..."
  sleep 2
done

echo "PostgreSQL did not become ready in time" >&2
docker logs "$CONTAINER_NAME" 2>&1 | tail -50 >&2
exit 1
