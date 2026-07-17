#!/usr/bin/env bash
# Resolve next production release tag (stable or stub -rc) per promotion contract.
#
# Environment (required):
#   COMMIT_SHA
#
# Environment (optional):
#   PROD_DEPLOY_ENABLED — when "true", stable vX.Y.Z; otherwise vX.Y.Z-rc.N
#
# Outputs to GITHUB_OUTPUT when set:
#   prod_tag, tag_kind (stable|rc), promotion_status (ok|already_released),
#   already_released (true|false)
set -euo pipefail

COMMIT_SHA="${COMMIT_SHA:?COMMIT_SHA is required}"
PROD_DEPLOY_ENABLED="${PROD_DEPLOY_ENABLED:-false}"

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

bump_patch() {
  local version="${1#v}"
  local major minor patch
  IFS='.' read -r major minor patch <<<"$version"
  echo "v${major}.${minor}.$((patch + 1))"
}

git fetch --tags --force origin

mapfile -t stable_tags < <(
  git tag -l 'v[0-9]*.[0-9]*.[0-9]*' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V
)

latest_stable=""
if ((${#stable_tags[@]} > 0)); then
  latest_stable="${stable_tags[${#stable_tags[@]} - 1]}"
fi

mapfile -t commit_tags < <(
  git tag -l --points-at "$COMMIT_SHA" | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+(-rc\.[0-9]+)?$' | sort -V
)

if [[ "$PROD_DEPLOY_ENABLED" == "true" ]]; then
  tag_kind="stable"
  stable_re='^v[0-9]+\.[0-9]+\.[0-9]+$'

  for existing in "${commit_tags[@]}"; do
    if [[ "$existing" =~ $stable_re ]]; then
      bash "${ROOT}/scripts/ci/assert-prod-tag.sh" "$existing" --kind stable
      emit_output prod_tag "$existing"
      emit_output tag_kind stable
      emit_output promotion_status already_released
      emit_output already_released true
      echo "::notice::Commit ${COMMIT_SHA} already released as ${existing}"
      exit 0
    fi
  done

  candidate="${latest_stable:-}"
  if [[ -z "$candidate" ]]; then
    candidate="v1.0.0"
  else
    candidate="$(bump_patch "$candidate")"
  fi

  while git rev-parse "refs/tags/${candidate}" >/dev/null 2>&1; do
    existing_sha="$(git rev-parse "${candidate}^{commit}")"
    if [[ "$existing_sha" == "$COMMIT_SHA" ]]; then
      bash "${ROOT}/scripts/ci/assert-prod-tag.sh" "$candidate" --kind stable
      emit_output prod_tag "$candidate"
      emit_output tag_kind stable
      emit_output promotion_status already_released
      emit_output already_released true
      echo "::notice::Tag ${candidate} already points at ${COMMIT_SHA}"
      exit 0
    fi
    candidate="$(bump_patch "$candidate")"
  done

  bash "${ROOT}/scripts/ci/assert-prod-tag.sh" "$candidate" --kind stable
  emit_output prod_tag "$candidate"
  emit_output tag_kind stable
  emit_output promotion_status ok
  emit_output already_released false
  exit 0
fi

tag_kind="rc"
rc_re='^v[0-9]+\.[0-9]+\.[0-9]+-rc\.[0-9]+$'

for existing in "${commit_tags[@]}"; do
  if [[ "$existing" =~ $rc_re ]]; then
    bash "${ROOT}/scripts/ci/assert-prod-tag.sh" "$existing" --kind rc
    emit_output prod_tag "$existing"
    emit_output tag_kind rc
    emit_output promotion_status already_released
    emit_output already_released true
    echo "::notice::Commit ${COMMIT_SHA} already promoted as stub ${existing}"
    exit 0
  fi
done

if [[ -n "$latest_stable" ]]; then
  base_version="$(bump_patch "$latest_stable" | sed 's/^v//')"
else
  base_version="1.0.0"
fi

max_rc=0
while IFS= read -r rc_tag; do
  [[ -z "$rc_tag" ]] && continue
  rc_num="${rc_tag##*-rc.}"
  if [[ "$rc_num" =~ ^[0-9]+$ && "$rc_num" -gt "$max_rc" ]]; then
    max_rc="$rc_num"
  fi
done < <(git tag -l "v${base_version}-rc.*" | grep -E "^v${base_version}-rc\\.[0-9]+$" | sort -V)

candidate="v${base_version}-rc.$((max_rc + 1))"
bash "${ROOT}/scripts/ci/assert-prod-tag.sh" "$candidate" --kind rc
emit_output prod_tag "$candidate"
emit_output tag_kind rc
emit_output promotion_status ok
emit_output already_released false
