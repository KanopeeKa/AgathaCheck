#!/usr/bin/env bash
# Pull a Docker image with exponential backoff (mitigates Docker Hub flakes on GHA).
#
# Usage:
#   scripts/ci/docker-pull-retry.sh <image> [max_attempts]
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: docker-pull-retry.sh <image> [max_attempts]" >&2
  exit 1
fi

image="$1"
max_attempts="${2:-5}"

for attempt in $(seq 1 "$max_attempts"); do
  echo "docker pull ${image} (attempt ${attempt}/${max_attempts})"
  if docker pull "$image"; then
    exit 0
  fi
  if [[ "$attempt" -lt "$max_attempts" ]]; then
    sleep_sec=$((attempt * 5))
    echo "Pull failed, backing off ${sleep_sec}s..."
    sleep "$sleep_sec"
  fi
done

echo "docker pull failed after ${max_attempts} attempts: ${image}" >&2
exit 1
