#!/usr/bin/env bash
# Create or verify production release tag with idempotency (promotion contract).
#
# Environment (required):
#   PROD_TAG, COMMIT_SHA, GITHUB_REPOSITORY, GITHUB_TOKEN
#
# Outputs to GITHUB_OUTPUT when set:
#   prod_tag, promotion_status (promoted|already_released), already_released (true|false)
set -euo pipefail

PROD_TAG="${PROD_TAG:?PROD_TAG is required}"
COMMIT_SHA="${COMMIT_SHA:?COMMIT_SHA is required}"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

emit_output() {
  local key="$1"
  local value="$2"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf '%s=%s\n' "$key" "$value" >>"$GITHUB_OUTPUT"
  fi
  printf '%s=%s\n' "$key" "$value"
}

bash "${ROOT}/scripts/ci/assert-prod-tag.sh" "$PROD_TAG" --kind any

git fetch --force origin "refs/tags/${PROD_TAG}:refs/tags/${PROD_TAG}" 2>/dev/null || true

if git rev-parse "refs/tags/${PROD_TAG}" >/dev/null 2>&1; then
  existing_sha="$(git rev-parse "${PROD_TAG}^{commit}")"
  if [[ "$existing_sha" == "$COMMIT_SHA" ]]; then
    echo "::notice::Tag ${PROD_TAG} already points at ${COMMIT_SHA} — already_released"
    emit_output prod_tag "$PROD_TAG"
    emit_output promotion_status already_released
    emit_output already_released true
    exit 0
  fi
  echo "::error::Tag ${PROD_TAG} exists on different SHA (tag=${existing_sha}, expected=${COMMIT_SHA})" >&2
  emit_output promotion_block_reason tag_sha_collision
  exit 1
fi

git config user.email "github-actions[bot]@users.noreply.github.com"
git config user.name "github-actions[bot]"

git tag -a "$PROD_TAG" -m "Production promotion for ${COMMIT_SHA}" "$COMMIT_SHA"
git push origin "refs/tags/${PROD_TAG}"

emit_output prod_tag "$PROD_TAG"
emit_output promotion_status promoted
emit_output already_released false
echo "Pushed tag ${PROD_TAG} at ${COMMIT_SHA}"
