#!/usr/bin/env bash
# Create or verify UAT promotion tag uat-YYMMDD-PR# with idempotency (promotion contract).
#
# Environment (required):
#   PR_NUMBER, COMMIT_SHA, GITHUB_REPOSITORY, GITHUB_TOKEN
#
# Outputs to GITHUB_OUTPUT when set:
#   uat_tag, promotion_status (promoted|already_promoted), already_promoted (true|false)
set -euo pipefail

PR_NUMBER="${PR_NUMBER:?PR_NUMBER is required}"
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

uat_tag="uat-$(date -u +%y%m%d)-${PR_NUMBER}"
bash "${ROOT}/scripts/ci/assert-uat-tag.sh" "$uat_tag"

git fetch --force origin "refs/tags/${uat_tag}:refs/tags/${uat_tag}" 2>/dev/null || true

if git rev-parse "refs/tags/${uat_tag}" >/dev/null 2>&1; then
  existing_sha="$(git rev-parse "${uat_tag}^{commit}")"
  if [[ "$existing_sha" == "$COMMIT_SHA" ]]; then
    echo "::notice::Tag ${uat_tag} already points at ${COMMIT_SHA} — already_promoted"
    emit_output uat_tag "$uat_tag"
    emit_output promotion_status already_promoted
    emit_output already_promoted true
    exit 0
  fi
  echo "::error::Tag ${uat_tag} exists on different SHA (tag=${existing_sha}, expected=${COMMIT_SHA})" >&2
  emit_output promotion_block_reason tag_sha_collision
  exit 1
fi

git config user.email "github-actions[bot]@users.noreply.github.com"
git config user.name "github-actions[bot]"

git tag -a "$uat_tag" -m "UAT promotion for PR #${PR_NUMBER}" "$COMMIT_SHA"
git push origin "refs/tags/${uat_tag}"

emit_output uat_tag "$uat_tag"
emit_output promotion_status promoted
emit_output already_promoted false
echo "Pushed tag ${uat_tag} at ${COMMIT_SHA}"
